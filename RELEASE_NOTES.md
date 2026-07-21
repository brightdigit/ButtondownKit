# Release Notes

## Unreleased

Synced from the brightdigit.com monorepo subrepo maintenance sweep (PR #4,
`brightdigit-com-260621`).

### Added
- `ButtondownClient` with typed operations for email drafting, listing, retrieving,
  updating, and archiving, backed by the Swift OpenAPI generator.
- Email model types: `Email`, `EmailPage`, `EmailStatus`, and the
  `EmailDrafting` / `EmailListing` / `EmailRetrieving` / `EmailUpdating` protocols.
- `LenientISO8601DateTranscoder` to tolerate fractional-second timestamps from the
  Buttondown API.
- OpenAPI definition (`OpenAPI/openapi.json`) and generator config; generated
  `Client.swift` / `Types.swift`.
- Test suite covering email listing, archiving, updating, and lenient date decoding,
  with JSON fixtures.

### Changed
- Swift 6.4 CI template (`.github/workflows/ButtondownKit.yml`) and supporting
  workflows (`check-unsafe-flags`, `claude`, `cleanup-caches`, `swift-source-compat`).
- Dev container pinned to `swiftlang/swift:nightly-6.4.x-noble`.
- `setup-tools` composite action and `Package.swift` dependency wiring.
