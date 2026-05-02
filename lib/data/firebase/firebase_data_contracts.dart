/// Firestore / Firebase layout (no SDK wired yet). Implement repositories that
/// read/write these paths when `firebase_core` is configured.
///
/// Collections (suggested):
/// - `plants/{plantId}` — public read catalog (same fields as [Plant] JSON).
/// - `users/{uid}/profile` — `{ locale, theme, fcmTokens[] }`.
/// - `users/{uid}/session/current` — mirrors [GrowSession.toJson].
/// - `users/{uid}/waterEvents` — append-only for analytics (optional).
/// - `devices/{deviceId}/sprinkler` — `{ on: bool, updatedAt: Timestamp }` for IoT.
/// - `market_cache/{regionId}/rows` — denormalized rows for offline sync.
///
/// Security rules sketch:
/// - `plants`: read if true; write admin only.
/// - `users/{uid}/**`: read, write if request.auth.uid == uid.
/// - `devices/{deviceId}`: read/write only with device credential or user claim `ownsDevice`.

void firebaseDataContractsDoc() {}
