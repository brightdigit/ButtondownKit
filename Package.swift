// swift-tools-version:6.4
// swiftlint:disable explicit_top_level_acl
import PackageDescription

let package = Package(
  name: "ButtondownKit",
  platforms: [
    .macOS(.v13),
    .iOS(.v16),
    .tvOS(.v16),
    .watchOS(.v9)
  ],
  products: [
    .library(name: "ButtondownKit", targets: ["ButtondownKit"])
  ],
  dependencies: [
    // NOTE: swift-openapi-generator is intentionally NOT a dependency here.
    // The Types.swift/Client.swift under Sources/ButtondownKit/Generated are
    // produced ahead of time by Scripts/generate-openapi-buttondown.sh (the
    // generator is pinned in .mise.toml via the spm backend) and committed.
    // The build-tool/command plugin is deliberately not used.
    .package(
      url: "https://github.com/apple/swift-openapi-runtime",
      from: "1.8.0"
    ),
    // URLSessionTransport works on both Apple platforms and Linux
    // (via FoundationNetworking), keeping the CI Linux container green.
    .package(
      url: "https://github.com/apple/swift-openapi-urlsession",
      from: "1.0.0"
    ),
    // Transitive via swift-openapi-runtime; declared explicitly so the contract
    // tests can name HTTPRequest/HTTPResponse in their mock transport.
    .package(
      url: "https://github.com/apple/swift-http-types",
      from: "1.0.0"
    )
  ],
  targets: [
    .target(
      name: "ButtondownKit",
      dependencies: [
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
        .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
        .product(name: "HTTPTypes", package: "swift-http-types")
      ],
      // The vendored OpenAPI spec and generator config are inputs to
      // Scripts/generate-openapi-buttondown.sh, not build resources.
      exclude: [
        "OpenAPI/openapi.json",
        "OpenAPI/openapi-generator-config.yaml"
      ]
    ),
    .testTarget(
      name: "ButtondownKitTests",
      dependencies: [
        "ButtondownKit",
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
        .product(name: "HTTPTypes", package: "swift-http-types")
      ],
      resources: [
        .copy("Fixtures")
      ]
    )
  ]
)
