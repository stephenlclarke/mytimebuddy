# My Time Buddy

[![CI](https://github.com/stephenlclarke/mytimebuddy/actions/workflows/ci.yml/badge.svg)](https://github.com/stephenlclarke/mytimebuddy/actions/workflows/ci.yml)
[![CodeQL](https://github.com/stephenlclarke/mytimebuddy/actions/workflows/codeql.yml/badge.svg)](https://github.com/stephenlclarke/mytimebuddy/actions/workflows/codeql.yml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mytimebuddy&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mytimebuddy)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mytimebuddy&metric=reliability_rating)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mytimebuddy)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mytimebuddy&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mytimebuddy)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mytimebuddy&metric=sqale_rating)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mytimebuddy)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](LICENSE)

My Time Buddy is a native SwiftUI iPhone app inspired by World Time Buddy's visual world clock, time-zone converter, and meeting planner.

## Features

- Visual hour grid for comparing saved locations at a glance.
- Tap an hour tile to select a meeting window across all locations.
- Adjustable duration with share and copy actions.
- Add, remove, rename, reorder, and mark a home time zone.
- Weekend highlighting, mixed 12/24-hour display, and optional FX market-session bands.
- Local persistence through `UserDefaults`; no network account is required.

## Local Development

Open `MyTimeBuddy.xcodeproj` in Xcode, or use the Makefile:

```sh
make ci
```

`make ci` typechecks the app and tests against the iOS Simulator SDK. If an iPhone simulator is available locally it also builds the app and test bundle for that simulator; GitHub Actions requires a simulator and fails if one is not available.

## CI/CD

The workflows borrow the lightweight pieces that fit from `container-compose`:

- `ci.yml` runs on `macos-26`, prints Swift/Xcode versions, fingerprints source files, caches DerivedData, runs the local `make ci` entrypoint with simulator tests required, and runs SonarCloud when `SONAR_TOKEN` is available.
- `quality.yml` keeps SwiftLint and SwiftFormat advisory, matching the non-blocking style posture used in `container-compose`.
- `codeql.yml` runs manual-build CodeQL for Swift.

The SonarCloud badges use project key `stephenlclarke_mytimebuddy`; import the repository in SonarCloud with that key for the badges to populate.

## License

My Time Buddy is licensed under the GNU Affero General Public License v3.0 only. See [LICENSE](LICENSE).
