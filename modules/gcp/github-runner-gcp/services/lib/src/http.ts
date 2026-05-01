import http from "node:http";
import { logger } from "./logger.js";

/**
 * Tiny HTTP server. We avoid Express to keep the container surface small.
 * Each route returns a status code + JSON body; thrown errors become 500.
 */

export interface RawRequest {
  method: string;
  path: string;
  headers: http.IncomingHttpHeaders;
  rawBody: Buffer;
  query: URLSearchParams;
}

export interface Response {
  status: number;
  body?: unknown;
  headers?: Record<string, string>;
}

export type Handler = (req: RawRequest) => Promise<Response>;

const readBody = (req: http.IncomingMessage): Promise<Buffer> =>
  new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    let total = 0;
    req.on("data", (chunk: Buffer) => {
      total += chunk.length;
      if (total > 4 * 1024 * 1024) {
        reject(new Error("payload too large"));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });

export const startServer = (routes: Record<string, Handler>): http.Server => {
  const port = Number.parseInt(process.env.PORT ?? "8080", 10);

  const server = http.createServer(async (req, res) => {
    const url = new URL(req.url ?? "/", `http://${req.headers.host ?? "localhost"}`);
    const reqLog = logger.child({ method: req.method, path: url.pathname });

    try {
      const handler = routes[url.pathname] ?? routes["*"];
      if (!handler) {
        res.writeHead(404, { "content-type": "application/json" });
        res.end(JSON.stringify({ error: "not found" }));
        return;
      }

      const rawBody = await readBody(req);
      const result = await handler({
        method: req.method ?? "GET",
        path: url.pathname,
        headers: req.headers,
        rawBody,
        query: url.searchParams,
      });
      res.writeHead(result.status, {
        "content-type": "application/json",
        ...(result.headers ?? {}),
      });
      res.end(result.body !== undefined ? JSON.stringify(result.body) : "");
    } catch (err) {
      reqLog.error({ err }, "handler failed");
      res.writeHead(500, { "content-type": "application/json" });
      res.end(JSON.stringify({ error: "internal error" }));
    }
  });

  server.listen(port, () => {
    logger.info({ port }, "listening");
  });

  const shutdown = (signal: string) => {
    logger.info({ signal }, "shutting down");
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(1), 10_000).unref();
  };
  process.once("SIGTERM", () => shutdown("SIGTERM"));
  process.once("SIGINT", () => shutdown("SIGINT"));

  return server;
};

export const healthRoute: Handler = async () => ({ status: 200, body: { ok: true } });
