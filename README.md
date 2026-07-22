# ButtondownKit


[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrightdigit%2FButtondownKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/brightdigit/ButtondownKit)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrightdigit%2FButtondownKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/brightdigit/ButtondownKit)
[![Documentation](https://img.shields.io/badge/docc-read_documentation-blue)](https://swiftpackageindex.com/brightdigit/ButtondownKit/documentation)
[![License](https://img.shields.io/github/license/brightdigit/ButtondownKit)](LICENSE)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/brightdigit/ButtondownKit/ButtondownKit.yml?label=actions&logo=github&branch=main)](https://github.com/brightdigit/ButtondownKit/actions)
[![Maintainability](https://qlty.sh/gh/brightdigit/projects/ButtondownKit/maintainability.svg)](https://qlty.sh/gh/brightdigit/projects/ButtondownKit)
[![Codecov](https://img.shields.io/codecov/c/github/brightdigit/ButtondownKit)](https://codecov.io/gh/brightdigit/ButtondownKit)
[![CodeFactor Grade](https://img.shields.io/codefactor/grade/github/brightdigit/ButtondownKit)](https://www.codefactor.io/repository/github/brightdigit/ButtondownKit)

A small async Swift client for the Buttondown API.

---

A small async Swift client for the [Buttondown](https://buttondown.com) API,
used by brightdigit.com to publish newsletter issues. It is generated from
Buttondown's official OpenAPI spec with
[swift-openapi-generator](https://github.com/apple/swift-openapi-generator) and
wrapped in an ergonomic `ButtondownClient`.

This is a greenfield client (issue #83), part of the Phase 4 OpenAPI client
migration (#82). The actual publishing pipeline — PublishKit, the `publish`
CLI, BufferKit — lives in #33 / Phase 6 and is **not** part of this package.

## Installation

Add ButtondownKit as a Swift Package Manager dependency in your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/brightdigit/ButtondownKit.git", from: "1.0.0-alpha.1")
],
targets: [
  .target(
    name: "YourTarget",
    dependencies: ["ButtondownKit"]
  )
]
```

## Architecture

- **Spec → filter → generate, ahead of time.** The full upstream spec is
  vendored at `Sources/ButtondownKit/OpenAPI/openapi.json`. It is filtered down
  to the operations needed for newsletter publishing and generated into
  `Sources/ButtondownKit/Generated/{Types,Client}.swift`, which are **committed**.
- **The generator is NOT a package dependency** and the build-tool plugin is
  **not** used. The generator is pinned in `.mise.toml`
  (`spm:apple/swift-openapi-generator`) and run by
  `Scripts/generate-openapi-buttondown.sh`.
- **Runtime dependencies:** `swift-openapi-runtime`, `swift-openapi-urlsession`
  (a Linux-safe transport), and `swift-http-types`.
- **Swift 6.4 tools version, Swift 6 language mode.**

### Filtered operations

These are the operations generated into the committed client. Only the email
operations are surfaced as `ButtondownClient` methods today; the subscriber
operations are generated but not yet exposed on the public client.

| Operation | Endpoint | Purpose |
| --- | --- | --- |
| `create_email` | `POST /emails` | Create a draft (Markdown body) |
| `update_email` | `PATCH /emails/{id}` | Update an existing email |
| `send_draft` | `POST /emails/{id}/send-draft` | Send the draft to subscribers |
| `list_emails` | `GET /emails` | Read (list/round-trip tests) |
| `retrieve_email` | `GET /emails/{id}` | Read (round-trip tests) |
| `list_subscribers` | `GET /subscribers` | Subscriber read (generated, not yet surfaced) |
| `retrieve_subscriber` | `GET /subscribers/{id_or_email}` | Subscriber read (generated, not yet surfaced) |

## Authentication

The API key is supplied via the `BUTTONDOWN_API_KEY` environment variable and
attached as `Authorization: Token <key>` by `AuthenticationMiddleware`. **No
subscriber/audience data or credentials are stored in the repository.**

```swift
let client = try ButtondownClient.fromEnvironment()
let draft = try await client.createDraft(
  subject: "This week at BrightDigit",
  body: "# Hello\n\nMarkdown body — Buttondown is Markdown-native."
)
try await client.sendDraft(id: draft.id)
```

## Regenerating

```bash
mise install                            # installs the pinned generator + tools
./Scripts/generate-openapi-buttondown.sh
```

The script filters the spec, normalizes it (re-injects the security scheme,
drops out-of-scope webhooks, sorts keys for reproducible output), and regenerates
the committed client. Output is deterministic, so a regenerate-and-`git diff`
serves as a drift check.

## Testing

Contract tests (`Tests/ButtondownKitTests`) drive the generated client offline
through a fixture-replaying `MockTransport` (a `ClientTransport`), covering the
create-draft round trip, the `Authorization` header, send-draft, email read, and
error handling.

```bash
swift test
```
