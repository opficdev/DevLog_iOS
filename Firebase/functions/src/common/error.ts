export function normalizeError(error: unknown): Record<string, unknown> {
    const normalized = error as {
        code?: unknown;
        details?: unknown;
        message?: unknown;
        stack?: unknown;
    };
    return {
        code: normalized?.code ?? null,
        details: normalized?.details ?? null,
        message: normalized?.message ?? String(error),
        stack: normalized?.stack ?? null
    };
}
