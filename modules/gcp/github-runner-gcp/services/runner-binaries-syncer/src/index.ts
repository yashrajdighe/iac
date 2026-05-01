import { createHash } from "node:crypto";
import { Readable } from "node:stream";
import { Storage } from "@google-cloud/storage";
import {
  loadConfig,
  logger,
  startServer,
  healthRoute,
  type Handler,
} from "@github-runner-gcp/lib";

/**
 * Cloud Run runner-binaries-syncer service.
 *
 * Mirrors the upstream `runner-binaries-syncer` Lambda + S3 cache:
 *   - Resolve latest actions/runner release.
 *   - Find the linux-<arch> tarball asset.
 *   - Download, sha256 verify, upload to GCS at versioned/<arch>/<version>.tar.gz.
 *   - Update latest/<arch>.json pointer with the version + checksum + path.
 *
 * Idempotent: re-runs are no-ops once the latest version is cached.
 */

const config = loadConfig();
const storage = new Storage({ projectId: config.projectId });
const bucket = storage.bucket(config.runnerBinariesBucket);

const archMap: Record<"x64" | "arm64", string> = {
  x64: "x64",
  arm64: "arm64",
};

interface ReleaseAsset {
  name: string;
  browser_download_url: string;
}
interface Release {
  tag_name: string;
  assets: ReleaseAsset[];
}

const fetchLatestRelease = async (): Promise<Release> => {
  const r = await fetch("https://api.github.com/repos/actions/runner/releases/latest", {
    headers: { "user-agent": "github-runner-gcp" },
  });
  if (!r.ok) throw new Error(`GitHub releases lookup failed: ${r.status}`);
  return (await r.json()) as Release;
};

const sha256 = (buf: Buffer): string => createHash("sha256").update(buf).digest("hex");

const handler: Handler = async (_req) => {
  const release = await fetchLatestRelease();
  const version = release.tag_name.replace(/^v/, "");
  const wanted = `actions-runner-linux-${archMap[config.runnerArchitecture]}-${version}.tar.gz`;
  const asset = release.assets.find((a) => a.name === wanted);
  if (!asset) {
    logger.error({ wanted, available: release.assets.map((a) => a.name) }, "asset not found");
    return { status: 500, body: { error: "asset not found", wanted } };
  }

  const versionedPath = `versioned/${config.runnerArchitecture}/${version}.tar.gz`;
  const versionedFile = bucket.file(versionedPath);

  const [exists] = await versionedFile.exists();
  let checksum: string | undefined;
  if (!exists) {
    logger.info({ versionedPath, asset: asset.name }, "downloading runner asset");
    const r = await fetch(asset.browser_download_url);
    if (!r.ok) throw new Error(`download failed: ${r.status}`);
    const buf = Buffer.from(await r.arrayBuffer());
    checksum = sha256(buf);
    await new Promise<void>((resolve, reject) => {
      Readable.from(buf)
        .pipe(versionedFile.createWriteStream({
          contentType: "application/gzip",
          metadata: { metadata: { sha256: checksum, version, arch: config.runnerArchitecture } },
        }))
        .on("finish", () => resolve())
        .on("error", reject);
    });
    logger.info({ versionedPath, sha256: checksum, bytes: buf.length }, "uploaded runner asset");
  } else {
    logger.info({ versionedPath }, "runner asset already cached");
    const [meta] = await versionedFile.getMetadata();
    checksum = (meta.metadata as { sha256?: string } | undefined)?.sha256;
  }

  const pointerName = `latest/${config.runnerArchitecture}.json`;
  const pointerFile = bucket.file(pointerName);
  const pointer = {
    version,
    arch: config.runnerArchitecture,
    sha256: checksum ?? null,
    object: versionedPath,
    bucket: bucket.name,
    sourceUrl: asset.browser_download_url,
    updatedAt: new Date().toISOString(),
  };
  await pointerFile.save(JSON.stringify(pointer, null, 2), {
    contentType: "application/json",
    metadata: { cacheControl: "no-store, max-age=0" },
  });
  logger.info({ pointer }, "updated latest pointer");

  return { status: 200, body: pointer };
};

startServer({
  "/": handler,
  "/healthz": healthRoute,
});
