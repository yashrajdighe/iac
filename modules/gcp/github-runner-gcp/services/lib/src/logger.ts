import pino from "pino";

/**
 * Cloud Logging-friendly logger.
 *
 * Maps pino's numeric level into Cloud Logging's `severity` field and uses
 * the `message` key Google's log explorer indexes. Trace correlation is
 * left to a per-request child logger created in `http.ts`.
 */

const severityByLevel: Record<string, string> = {
  trace: "DEBUG",
  debug: "DEBUG",
  info: "INFO",
  warn: "WARNING",
  error: "ERROR",
  fatal: "CRITICAL",
};

export const logger = pino({
  level: process.env.LOG_LEVEL ?? "info",
  messageKey: "message",
  formatters: {
    level(label: string) {
      return { severity: severityByLevel[label] ?? "DEFAULT" };
    },
  },
  base: {
    service: process.env.K_SERVICE ?? "github-runner-gcp",
    revision: process.env.K_REVISION,
  },
});

export type Logger = typeof logger;
