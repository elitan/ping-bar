# PingBar

A macOS menu bar app for network diagnostics - monitor ping latency, WiFi signal, and connection quality at a glance.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**[⬇️ Download Latest Release](https://github.com/elitan/ping-bar/releases/latest/download/PingBar.zip)**

## Features

- **Menu bar latency** - Shows ping to internet (1.1.1.1) with color coding
- **WiFi info** - SSID, signal strength, noise, link rate, band (2.4/5 GHz)
- **Router ping** - Latency to your gateway with sparkline graph
- **Internet ping** - Latency to 1.1.1.1 with jitter and packet loss
- **DNS lookup** - Resolution time for cloudflare.com
- **Captive portal detection** - Alerts when login is required
- **Signed & notarized** - Runs without Gatekeeper warnings

## Install

### Download (Recommended)

1. Download [PingBar.zip](https://github.com/elitan/ping-bar/releases/latest/download/PingBar.zip)
2. Unzip and drag `PingBar.app` to `/Applications`
3. Open PingBar from Applications

### Build from source

```bash
git clone https://github.com/elitan/ping-bar.git
cd ping-bar
./scripts/build-app.sh
```

App bundle will be at `.build/release/PingBar.app`

## Usage

1. Click the menu bar item to open the diagnostics panel
2. Click **Start** to begin monitoring
3. View real-time stats with sparkline graphs
4. Click **Stop** to pause and clear

## Color Coding

| Metric | Green | Orange | Red |
|--------|-------|--------|-----|
| Ping | <30ms | <100ms | ≥100ms |
| Signal | >-50dBm | >-70dBm | ≤-70dBm |
| Loss | 0% | <5% | ≥5% |

## Settings

- **Launch at Login** - Start PingBar automatically when you log in

## License

MIT
