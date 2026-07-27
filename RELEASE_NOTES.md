# Release Notes

## 1.0.0-alpha.1

First release of ButtondownKit — a Swift client for the [Buttondown](https://buttondown.com)
newsletter API, generated from an OpenAPI description via swift-openapi-generator.

### Library
* Provide `ButtondownClient` over swift-openapi-runtime and swift-openapi-urlsession, with `AuthenticationMiddleware` for API-key auth by @leogdion in https://github.com/brightdigit/ButtondownKit/pull/9
* Add the email surface — `Email`, `EmailStatus`, `EmailPage`, and the `EmailListing`, `EmailRetrieving`, `EmailDrafting` and `EmailUpdating` operations by @leogdion in https://github.com/brightdigit/ButtondownKit/pull/9
* Build on `swift-tools-version:6.4` with complete strict concurrency by @leogdion in https://github.com/brightdigit/ButtondownKit/pull/9

### Documentation
* Add unified badge header and DocC catalog by @leogdion in https://github.com/brightdigit/ButtondownKit/pull/10

### Tooling & CI
* Add standalone CI workflow for ButtondownKit (Swift 6.4) by @leogdion in https://github.com/brightdigit/ButtondownKit/pull/1
* Add `Scripts/generate-openapi-buttondown.sh` to regenerate the client from the API description by @leogdion in https://github.com/brightdigit/ButtondownKit/pull/9
* Move linting to mise with `.mise.toml`, `.swift-format`, `.swiftlint.yml`, `.periphery.yml`, and `Scripts/lint.sh` by @leogdion in https://github.com/brightdigit/ButtondownKit/pull/9
* Add Claude Code GitHub Workflow by @leogdion in https://github.com/brightdigit/ButtondownKit/pull/7
