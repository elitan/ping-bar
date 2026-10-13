# PingBar

Network diagnostics in your menu bar. Monitor latency, WiFi signal, and connection quality at a glance.

**[Download Latest Release](https://github.com/elitan/ping-bar/releases/latest/download/PingBar.dmg)**

<p align="center">
  <img src="assets/pingbar.png" alt="PingBar Screenshot" width="400">
</p>

## Features

- **Menu bar latency** - Live ping displayed in menu bar with color coding
- **WiFi details** - Network name, signal strength, noise floor, link rate, frequency band
- **Router ping** - Latency to gateway with jitter, packet loss, and sparkline history
- **Internet ping** - Latency to 1.1.1.1 with jitter, packet loss, and sparkline history
- **DNS lookup** - Query time from your DNS server for google.com with sparkline history
- **Captive portal detection** - Alerts when network login is required
- **Signed & notarized** - No Gatekeeper warnings

## Install

### Homebrew

```bash
brew install --cask elitan/tap/pingbar
```

### Manual

1. Download [PingBar.dmg](https://github.com/elitan/ping-bar/releases/latest/download/PingBar.dmg)
2. Open the DMG and drag PingBar to Applications
3. Open PingBar

### Build from source

```bash
git clone https://github.com/elitan/ping-bar.git
cd ping-bar
./scripts/build-app.sh   # app bundle in .build/release/PingBar.app
swift test               # run the tests
```

## Color Coding

| Metric | Green | Orange | Red |
|--------|-------|--------|-----|
| Signal | >-50 dBm | >-70 dBm | ≤-70 dBm |
| Loss | 0% | <5% | ≥5% |

Latency fades smoothly from green at 0 ms to red at 200 ms and above, based on a weighted average of recent pings. A failed ping shows red.

## Requirements

- macOS 13+
- Location permission (optional, for WiFi network name)

## License

MIT
