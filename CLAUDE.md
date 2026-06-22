# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

ButtondownKit is a small async Swift client for the subset of the [Buttondown](https://buttondown.com)
API used for newsletter publishing (used by brightdigit.com). The generated OpenAPI client is wrapped
in an ergonomic `ButtondownClient`. Swift 6.4 tools version, Swift 6 language mode; targets macOS 13+,
iOS 16+, tvOS 16+, watchOS 9+, and Linux.

## Commands

```bash
swift test                              # run the contract tests (offline, no network/key needed)
swift build --build-tests               # compile

# Single test: filter by suite/method
swift test --filter ButtondownClientTests/createDraftRoundTrip

# Lint/format/check (installs pinned tools via mise, formats in place locally, builds tests, runs periphery)
./Scripts/lint.sh
LINT_MODE=STRICT ./Scripts/lint.sh      # CI-style strict mode (no auto-fix; lint + build only when CI is set)

mise install                            # install pinned tools (swift-format, swiftlint, periphery, generator)
./Scripts/generate-openapi-buttondown.sh   # regenerate the committed client from the vendored spec
```

Tooling (swift-format, SwiftLint, periphery, swift-openapi-generator) is pinned in `.mise.toml` and run
through `mise exec --`. `Scripts/lint.sh` auto-formats and rewrites file headers only when `CI` is unset;
in CI it lints and builds without mutating files.

## The generation model — this is the key architectural decision

The OpenAPI client is generated **ahead of time and committed**, NOT via the build-tool/command plugin,
and **swift-openapi-generator is intentionally NOT a `Package.swift` dependency**.

- `Sources/ButtondownKit/OpenAPI/openapi.json` — the vendored Buttondown spec (the generator's input;
  `exclude`d from the build). It has been pre-normalized: security scheme matches kept operations,
  out-of-scope `webhooks` removed, keys sorted, so generator output is deterministic.
- `Sources/ButtondownKit/OpenAPI/openapi-generator-config.yaml` — `filter:` restricts generation to the
  six operations the client needs (create_email, send_draft, list_emails, retrieve_email,
  list_subscribers, retrieve_subscriber). Adding a new endpoint means adding it here and regenerating.
- `Sources/ButtondownKit/Generated/{Types,Client}.swift` — committed output. **Do not hand-edit.** It is
  marked `swift-format-ignore-file` + `periphery:ignore:all`, excluded from formatting/periphery by those
  markers and from SwiftLint via `.swiftlint.yml`.

Because output is deterministic, regenerate-and-`git diff` doubles as a drift check against the spec.

## Hand-written code (the only files you normally edit)

- `Sources/ButtondownKit/ButtondownClient.swift` — public `struct ButtondownClient: Sendable` wrapping the
  generated `Client`. Each method maps an output enum case to a return value and throws
  `ClientError.unexpectedResponse` on any other case. Construct via `init(apiKey:)`,
  `fromEnvironment()` (reads `BUTTONDOWN_API_KEY`), or `init(underlying:)` (test injection).
- `Sources/ButtondownKit/AuthenticationMiddleware.swift` — a `ClientMiddleware` that injects
  `Authorization: Token <key>`. The generator emits no auth code, so the credential is attached here at
  the transport boundary.

## Tests

Contract tests run fully offline. `Tests/ButtondownKitTests/MockTransport.swift` is a `ClientTransport`
that replays JSON fixtures from `Tests/ButtondownKitTests/Fixtures/` (copied as a bundle resource) keyed by
`"METHOD /path"`, and records requests for assertions. Tests build a real generated `Client` over the mock
transport **with the real `AuthenticationMiddleware`** so auth behavior is exercised. Uses swift-testing
(`@Suite`/`@Test`/`#expect`), not XCTest.

## Conventions

- The MIT license header on every hand-written Swift file is managed by `Scripts/header.sh` (invoked from
  `lint.sh` locally). Don't hand-maintain headers; files under `Generated/` are skipped.
- No subscriber/audience data or API keys live in the repo; the key only ever comes from
  `BUTTONDOWN_API_KEY`.
