/// A page reloads when the server comes back: the connection's reconnect
/// count moved since the page last looked. Going offline and the "connected
/// again" notice settling away leave the count alone.
bool reloadsOnReconnect(int? before, int now) =>
    before != null && now != before;

/// How long a page's data counts as fresh (owner 2026-10-25: 5 minutes, the
/// same as coming back to the app; own writes patch the page at once anyway).
const pageDataFreshFor = Duration(minutes: 5);

/// Shown again (tab switch, pop back, app resume) re-opens the page only once
/// its data is older than [pageDataFreshFor]; never loaded = stale. A pull
/// or a reconnect doesn't ask: they always reload.
bool reopensWhenShown(DateTime? loadedAt, DateTime now) =>
    loadedAt == null || now.difference(loadedAt) >= pageDataFreshFor;
