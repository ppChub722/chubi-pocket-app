/// A page reloads when the server comes back: the connection's reconnect
/// count moved since the page last looked. Going offline and the "connected
/// again" notice settling away leave the count alone.
bool reloadsOnReconnect(int? before, int now) =>
    before != null && now != before;
