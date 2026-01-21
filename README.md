# PingBar

A simple macOS menu bar app that shows your ping latency to google.com.

![Menu Bar](https://img.shields.io/badge/macOS-13%2B-blue)

## Features

- Shows ping latency in menu bar (e.g., `12ms`)
- Color coded: green (<50ms), orange (<150ms), red (>150ms)
- Start/Stop ping monitoring
- Launch at Login option
- Lightweight, native Swift app

## Install

### Download (Recommended)

1. Download `PingBar.zip` from [Releases](https://github.com/elitan/ping-bar/releases)
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

1. Click the menu bar item (`---` initially)
2. Click **Start** to begin pinging
3. Watch latency update every second
4. Click **Stop** to pause

## Settings

- **Launch at Login**: Start PingBar automatically when you log in

## License

MIT
