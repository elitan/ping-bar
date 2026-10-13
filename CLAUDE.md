# PingBar

## Develop

```bash
swift test                 # unit tests
./scripts/build-app.sh     # builds .build/release/PingBar.app
```

## Release

To create a release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This triggers the GitHub Actions workflow, which stamps the tag's version into the app, then signs, notarizes and publishes `PingBar.dmg` and updates the Homebrew tap.
