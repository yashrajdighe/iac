"""
Cloudflare origin mTLS: custom root CA + client cert, secrets, S3 trust-store, Cloudflare API.
Uses the Lambda layer for cryptography and requests (boto3 is in the runtime). The layer ZIP must
use the AWS layout with packages under python/ so they resolve under /opt/python.
"""

from __future__ import annotations

import base64
import json
import logging
import os
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any

import boto3
import requests
from botocore.exceptions import ClientError
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import ExtendedKeyUsageOID, NameOID

log = logging.getLogger()
log.setLevel(logging.INFO)

ZONE_ID = os.environ["CLOUDFLARE_ZONE_ID"]
TOKEN_ARN = os.environ["CLOUDFLARE_API_TOKEN_SECRET_ARN"]
ROOT_CA_ARN = os.environ["ROOT_CA_SECRET_ARN"]
CLIENT_ARN = os.environ["CLIENT_CERT_SECRET_ARN"]
BUCKET_NAMES = [b for b in os.environ.get("TRUST_STORE_BUCKET_NAMES", "").split(",") if b]
TRUST_STORE_S3_KEY = (os.environ.get("TRUST_STORE_S3_OBJECT_KEY", "root-ca.pem") or "root-ca.pem").lstrip("/")
ROOT_DAYS = int(os.environ.get("ROOT_CA_VALIDITY_DAYS", "3650"))
ROOT_CA_RENEW_BEFORE_DAYS = int(os.environ.get("ROOT_CA_RENEW_BEFORE_DAYS", "120"))
CLIENT_DAYS = int(os.environ.get("CLIENT_CERT_VALIDITY_DAYS", "30"))

sm = boto3.client("secretsmanager")
s3 = boto3.client("s3")
CF = "https://api.cloudflare.com/client/v4"


def _get_cf_token() -> str:
    r = sm.get_secret_value(SecretId=TOKEN_ARN)
    s = r.get("SecretString")
    if s:
        j = s.strip()
        if j.startswith("{"):
            d = json.loads(j)
            if "token" in d:
                return str(d["token"])
        return s.strip()
    b = r.get("SecretBinary")
    if b:
        return base64.b64decode(b).decode("utf-8").strip()
    raise RuntimeError("Cloudflare API token secret is empty or unsupported format.")


def _cf_headers(token: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }


def _cf_get(token: str, path: str) -> dict[str, Any]:
    r = requests.get(
        f"{CF}/zones/{ZONE_ID}{path}",
        headers=_cf_headers(token),
        timeout=60,
    )
    r.raise_for_status()
    return r.json()


def _cf_json(
    method: str, token: str, path: str, body: Any | None = None
) -> dict[str, Any]:
    kwargs: dict[str, Any] = {"timeout": 90}
    if body is not None:
        kwargs["json"] = body
    r = requests.request(
        method,
        f"{CF}/zones/{ZONE_ID}{path}",
        headers=_cf_headers(token),
        **kwargs,
    )
    if r.status_code >= 400:
        log.error("Cloudflare %s %s: %s", method, path, r.text)
    r.raise_for_status()
    return r.json() if (r.text and r.content) else {}


def _set_authenticated_origin_pulls(token: str) -> None:
    _cf_json(
        "PATCH",
        token,
        "/settings/authenticated_origin_pulls",
        {"value": "on"},
    )
    log.info("Authenticated origin pulls: on")


def _load_root_from_sm() -> dict | None:
    try:
        r = sm.get_secret_value(SecretId=ROOT_CA_ARN)
    except ClientError as e:
        code = (e.response or {}).get("Error", {}).get("Code", "")
        if code in ("ResourceNotFoundException", "InvalidRequestException"):
            return None
        raise
    s = (r or {}).get("SecretString")
    if not s:
        return None
    try:
        d = json.loads(s)
    except json.JSONDecodeError:
        return None
    if d.get("cert_pem") and d.get("key_pem"):
        return d
    return None


def _build_root_ca() -> dict:
    k = rsa.generate_private_key(public_exponent=65537, key_size=4096)
    name = x509.Name(
        [x509.NameAttribute(NameOID.COMMON_NAME, "Custom-Cloudflare-Origin-CA")]
    )
    now = datetime.now(timezone.utc)
    c = (
        x509.CertificateBuilder()
        .subject_name(name)
        .issuer_name(name)
        .public_key(k.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now)
        .not_valid_after(now + timedelta(days=ROOT_DAYS))
        .add_extension(
            x509.BasicConstraints(ca=True, path_length=None), critical=True
        )
        .add_extension(
            x509.KeyUsage(
                key_cert_sign=True,
                crl_sign=True,
                digital_signature=True,
                content_commitment=False,
                key_encipherment=False,
                data_encipherment=False,
                key_agreement=False,
                encipher_only=False,
                decipher_only=False,
            ),
            critical=True,
        )
        .sign(k, hashes.SHA256())
    )
    return {
        "key_pem": k.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        ).decode("utf-8"),
        "cert_pem": c.public_bytes(serialization.Encoding.PEM).decode("utf-8"),
    }


def _sign_client_cert(
    ca_cert: x509.Certificate, ca_key: Any
) -> dict:
    k = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    subj = x509.Name(
        [x509.NameAttribute(NameOID.COMMON_NAME, "cloudflare-origin-pull")]
    )
    csr = (
        x509.CertificateSigningRequestBuilder()
        .subject_name(subj)
        .sign(k, hashes.SHA256())
    )
    now = datetime.now(timezone.utc)
    serial = int(uuid.uuid4().int & (1 << 64) - 1)
    cert = (
        x509.CertificateBuilder()
        .subject_name(csr.subject)
        .issuer_name(ca_cert.subject)
        .public_key(k.public_key())
        .serial_number(serial)
        .not_valid_before(now)
        .not_valid_after(now + timedelta(days=CLIENT_DAYS))
        .add_extension(
            x509.BasicConstraints(ca=False, path_length=None), critical=True
        )
        .add_extension(
            x509.KeyUsage(
                digital_signature=True,
                key_encipherment=True,
                key_cert_sign=False,
                crl_sign=False,
                content_commitment=False,
                data_encipherment=False,
                key_agreement=False,
                encipher_only=False,
                decipher_only=False,
            ),
            critical=True,
        )
        .add_extension(
            x509.ExtendedKeyUsage([ExtendedKeyUsageOID.CLIENT_AUTH]), critical=False
        )
        .sign(ca_key, hashes.SHA256())
    )
    return {
        "key_pem": k.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        ).decode("utf-8"),
        "cert_pem": cert.public_bytes(serialization.Encoding.PEM).decode("utf-8"),
    }


def _pem_to_cert(pem: str) -> x509.Certificate:
    return x509.load_pem_x509_certificate(pem.encode("utf-8"))


def _cert_not_after_utc(cert: x509.Certificate) -> datetime:
    """Return certificate notAfter as timezone-aware UTC."""
    try:
        nva = cert.not_valid_after_utc  # cryptography 42+
    except AttributeError:
        nva = cert.not_valid_after
        if nva.tzinfo is None:
            nva = nva.replace(tzinfo=timezone.utc)
    return nva


def _root_ca_expired_or_due_for_renewal(root: dict) -> bool:
    """
    True if the stored root CA is missing parseable cert, already expired, or
    notAfter is within ROOT_CA_RENEW_BEFORE_DAYS (so the next 28d run can rotate
    well before 3650-day lifetime ends, or immediately after if already expired).
    """
    try:
        cert = _pem_to_cert(root["cert_pem"])
    except Exception as e:  # noqa: BLE001
        log.warning("Cannot parse root CA cert_pem, will rotate: %s", e)
        return True
    not_after = _cert_not_after_utc(cert)
    now = datetime.now(timezone.utc)
    threshold = not_after - timedelta(days=ROOT_CA_RENEW_BEFORE_DAYS)
    if now >= threshold:
        log.info(
            "Root CA auto-rotation: now=%s notAfter=%s renew_before=%s day(s) (threshold=%s)",
            now.isoformat(),
            not_after.isoformat(),
            ROOT_CA_RENEW_BEFORE_DAYS,
            threshold.isoformat(),
        )
        return True
    log.info(
        "Root CA still valid: notAfter=%s (renewal starts %s day(s) before that)",
        not_after.isoformat(),
        ROOT_CA_RENEW_BEFORE_DAYS,
    )
    return False


def _pem_to_key(pem: str) -> Any:
    return serialization.load_pem_private_key(
        pem.encode("utf-8"), password=None
    )


def _put_root_pem_s3(cert_pem: str) -> None:
    for name in BUCKET_NAMES:
        s3.put_object(
            Bucket=name,
            Key=TRUST_STORE_S3_KEY,
            Body=cert_pem.encode("utf-8"),
            ContentType="application/x-pem-file",
            ServerSideEncryption="AES256",
        )
        log.info("Uploaded to s3://%s/%s", name, TRUST_STORE_S3_KEY)


def _put_secret(arn: str, payload: str) -> None:
    sm.put_secret_value(SecretId=arn, SecretString=payload)
    log.info("Secrets Manager updated (PutSecretValue ok): %s", arn)


def _list_origin_client_auth_ids(token: str) -> list[str]:
    j = _cf_get(token, "/origin_tls_client_auth")
    res = j.get("result")
    if res is None:
        return []
    if isinstance(res, list):
        return [str(x.get("id", "")) for x in res if x.get("id")]
    if isinstance(res, dict):
        certs = res.get("certificates") or res.get("certs")
        if isinstance(certs, list):
            return [str(x.get("id", "")) for x in certs if x.get("id")]
    return []


def _post_origin_client_auth(
    token: str, cert_pem: str, key_pem: str
) -> str | None:
    j = _cf_json(
        "POST",
        token,
        "/origin_tls_client_auth",
        {"certificate": cert_pem, "private_key": key_pem},
    )
    res = j.get("result")
    if isinstance(res, dict) and res.get("id"):
        return str(res["id"])
    return None


def _delete_origin_client_auth(token: str, cert_id: str) -> None:
    if not cert_id:
        return
    try:
        _cf_json("DELETE", token, f"/origin_tls_client_auth/{cert_id}", None)
        log.info("Deleted old Cloudflare origin client auth cert: %s", cert_id)
    except Exception:  # noqa: BLE001
        log.exception("Delete cert %s", cert_id)


def _load_client_meta() -> dict:
    try:
        r = sm.get_secret_value(SecretId=CLIENT_ARN)
    except ClientError:
        return {}
    s = (r or {}).get("SecretString", "")
    if not s:
        return {}
    try:
        return json.loads(s)
    except json.JSONDecodeError:
        return {}


def lambda_handler(event, context) -> dict:  # noqa: ARG001
    ev: dict
    if isinstance(event, str):
        try:
            ev = json.loads(event)
        except json.JSONDecodeError:
            ev = {}
    elif isinstance(event, dict):
        ev = event
    else:
        ev = {}
    if isinstance(ev, dict) and "detail" in ev and isinstance(ev.get("detail"), dict):
        ev = ev["detail"]

    force_root = ev.get("force_root_ca_rotation") is True
    log.info("Rotation start (force_root=%s)", force_root)

    if not BUCKET_NAMES:
        raise RuntimeError("TRUST_STORE_BUCKET_NAMES is empty.")

    token = _get_cf_token()

    existing_root = _load_root_from_sm()
    need_new_root = (
        force_root
        or existing_root is None
        or (existing_root is not None and _root_ca_expired_or_due_for_renewal(existing_root))
    )

    root_ca_rotated = False
    if need_new_root:
        if existing_root is None:
            log.info("Bootstrapping new root CA (no secret yet)")
        elif force_root:
            log.info("Rotating root CA (force_root_ca_rotation=true)")
        else:
            log.info("Rotating root CA (expired or within automatic renew-before window)")
        root = _build_root_ca()
        _put_secret(ROOT_CA_ARN, json.dumps(root))
        try:
            _put_root_pem_s3(root["cert_pem"])
        except Exception:
            log.exception(
                "Trust store S3 upload failed (root CA PEM is already in Secrets Manager)"
            )
        root_ca_rotated = True
    else:
        log.info("Reusing root CA; skipping S3 trust store re-upload (%s)", TRUST_STORE_S3_KEY)
        root = existing_root

    ca_cert = _pem_to_cert(root["cert_pem"])
    ca_key = _pem_to_key(root["key_pem"])

    old_meta = _load_client_meta()
    old_cf_id = old_meta.get("cloudflare_cert_id")

    cl = _sign_client_cert(ca_cert, ca_key)
    client_payload: dict[str, Any] = {
        "cert_pem": cl["cert_pem"],
        "key_pem": cl["key_pem"],
    }
    # Persist before Cloudflare API calls so Secrets Manager still gets PEM material if CF errors.
    _put_secret(CLIENT_ARN, json.dumps(client_payload))

    new_id = _post_origin_client_auth(token, cl["cert_pem"], cl["key_pem"])
    if not new_id:
        ids = _list_origin_client_auth_ids(token)
        if old_cf_id and len(ids) == 1 and ids[0] != str(old_cf_id):
            new_id = str(ids[0])
        else:
            known = {str(x) for x in ids}
            for x in known:
                if str(old_cf_id) != x:
                    new_id = x
                    break
        if not new_id and ids:
            new_id = str(ids[-1])
    if old_cf_id and new_id and str(old_cf_id) != str(new_id):
        _delete_origin_client_auth(token, str(old_cf_id))

    if new_id:
        client_payload["cloudflare_cert_id"] = new_id
        _put_secret(CLIENT_ARN, json.dumps(client_payload))
    _set_authenticated_origin_pulls(token)
    return {
        "ok": True,
        "root_ca_rotated": root_ca_rotated,
        "new_cloudflare_cert_id": new_id,
        "s3_buckets": BUCKET_NAMES,
    }
