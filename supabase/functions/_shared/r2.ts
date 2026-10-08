// Cloudflare R2 (S3 compatible) for shared videos. The bucket is private and stored in Eastern Europe
// (location hint EEUR); only this server code holds the keys. Links handed to the app are presigned and short-lived.
//
// Secrets (Supabase → Edge Functions → Secrets): R2_ACCOUNT_ID, R2_ACCESS_KEY_ID,
// R2_SECRET_ACCESS_KEY, R2_BUCKET.

import { AwsClient } from "npm:aws4fetch@1.0.20";

export interface R2 {
  presign(key: string, method: "GET" | "PUT", ttlSeconds: number, headers?: Record<string, string>): Promise<string>;
  /** Size in bytes, or null when the object does not exist. */
  size(key: string): Promise<number | null>;
  remove(key: string): Promise<void>;
}

export function getR2(): R2 {
  const accountId = Deno.env.get("R2_ACCOUNT_ID");
  const accessKeyId = Deno.env.get("R2_ACCESS_KEY_ID");
  const secretAccessKey = Deno.env.get("R2_SECRET_ACCESS_KEY");
  const bucket = Deno.env.get("R2_BUCKET");
  if (!accountId || !accessKeyId || !secretAccessKey || !bucket) {
    throw new Error("R2 secrets are not set.");
  }

  const client = new AwsClient({ accessKeyId, secretAccessKey, service: "s3", region: "auto" });
  const objectURL = (key: string) =>
    `https://${accountId}.r2.cloudflarestorage.com/${bucket}/${key.split("/").map(encodeURIComponent).join("/")}`;

  return {
    async presign(key, method, ttlSeconds, headers = {}) {
      const url = new URL(objectURL(key));
      url.searchParams.set("X-Amz-Expires", String(ttlSeconds));
      // allHeaders: the size and type become part of the signature, so the upload must match them.
      const signed = await client.sign(url.toString(), { method, headers, aws: { signQuery: true, allHeaders: true } });
      return signed.url;
    },

    async size(key) {
      const res = await client.fetch(objectURL(key), { method: "HEAD" });
      if (res.status === 404) return null;
      if (!res.ok) throw new Error(`R2 HEAD failed: ${res.status}`);
      return Number(res.headers.get("content-length") ?? "0");
    },

    async remove(key) {
      const res = await client.fetch(objectURL(key), { method: "DELETE" });
      // 204 when deleted, 404 when it was already gone: both mean the file is not there any more.
      if (!res.ok && res.status !== 404) throw new Error(`R2 DELETE failed: ${res.status}`);
    },
  };
}
