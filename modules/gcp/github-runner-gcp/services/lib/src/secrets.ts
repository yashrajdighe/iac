import { SecretManagerServiceClient } from "@google-cloud/secret-manager";

const client = new SecretManagerServiceClient();

const cache = new Map<string, { value: string; expires: number }>();
const TTL_MS = 5 * 60 * 1000;

/**
 * Resolve a Secret Manager secret to its latest version's plaintext.
 * Cached for 5 minutes to avoid hammering Secret Manager on every request;
 * rotation propagates within one TTL.
 */
export const readSecret = async (resourceId: string): Promise<string> => {
  const now = Date.now();
  const hit = cache.get(resourceId);
  if (hit && hit.expires > now) return hit.value;

  const name = resourceId.endsWith("/versions/latest")
    ? resourceId
    : `${resourceId}/versions/latest`;
  const [response] = await client.accessSecretVersion({ name });
  const data = response.payload?.data;
  if (data === null || data === undefined) {
    throw new Error(`Secret ${resourceId} has no payload data`);
  }
  const value = typeof data === "string" ? data : Buffer.from(data).toString("utf8");
  cache.set(resourceId, { value, expires: now + TTL_MS });
  return value;
};

export const invalidateSecret = (resourceId: string): void => {
  cache.delete(resourceId);
};
