const DEFAULT_TIMEZONE = "UTC";

export function resolveTimeZone(settings: FirebaseFirestore.DocumentData | undefined): string {
    const candidate = settings?.timeZone ?? settings?.timezone ?? settings?.region;
    if (typeof candidate !== "string" || !candidate.trim()) { return DEFAULT_TIMEZONE; }

    try {
        new Intl.DateTimeFormat("en-US", { timeZone: candidate }).format(new Date());
        return candidate;
    } catch {
        return DEFAULT_TIMEZONE;
    }
}
