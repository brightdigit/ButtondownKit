//
//  ButtondownClient.swift
//  ButtondownKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import OpenAPIRuntime

// URLSession transport is unavailable on WASI; the apiKey-based initializers that
// build a `URLSessionTransport` are gated behind #if !os(WASI) below. WASI callers
// construct a `Client` with a wasm-compatible transport and use `init(underlying:)`.
#if !os(WASI)
  import OpenAPIURLSession
#endif

/// A high-level async client for the subset of the Buttondown API used for
/// newsletter publishing.
///
/// ``ButtondownClient`` wraps the swift-openapi-generator ``Client`` with an
/// ``AuthenticationMiddleware`` and exposes a small, ergonomic surface via the
/// capability protocols it conforms to: ``EmailListing`` (list/page emails),
/// ``EmailDrafting`` (create/send drafts), ``EmailRetrieving`` (read one
/// email), and ``EmailUpdating`` (patch an email). Those capabilities implement
/// their methods against ``underlying`` in
/// extensions constrained on ``UnderlyingClientProtocol``, so this type is only
/// storage plus initializers. All results are Swift-native domain types
/// (``Email`` et al.), never the generated `Components.Schemas.*`.
///
/// The underlying transport defaults to `URLSessionTransport`, which works on
/// both Apple platforms and Linux. No subscriber/audience data is stored in the
/// repository; the API key is supplied via the `BUTTONDOWN_API_KEY` environment
/// variable.
public struct ButtondownClient: Sendable, UnderlyingClientProtocol,
  EmailListing, EmailDrafting, EmailRetrieving, EmailUpdating
{
  /// Errors surfaced by ``ButtondownClient``.
  public enum ClientError: Error, Equatable {
    /// `BUTTONDOWN_API_KEY` was not set in the environment.
    case missingAPIKey
    /// The server returned a response the client could not interpret as
    /// success (an undocumented status, or a documented error response).
    case unexpectedResponse
  }

  /// The default Buttondown API server URL.
  ///
  /// Built from the generated ``Servers/Server1`` constant. If this traps, the
  /// vendored OpenAPI spec contains an invalid server URL literal.
  public static let defaultServerURL: URL = {
    do {
      return try Servers.Server1.url()
    } catch {
      preconditionFailure("Invalid generated Buttondown server URL: \(error)")
    }
  }()

  /// The client configuration used by the URLSession-backed initializers.
  ///
  /// Installs ``LenientISO8601DateTranscoder`` so the mixed fractional/whole
  /// second timestamps the Buttondown API returns both decode successfully.
  public static var defaultConfiguration: Configuration {
    Configuration(dateTranscoder: LenientISO8601DateTranscoder.default)
  }

  /// The generated, transport-backed API client.
  public let underlying: Client

  /// Creates a client from a pre-built generated ``Client``.
  ///
  /// Primarily used by tests to inject a mock transport. Production callers
  /// should prefer ``init(apiKey:)`` or ``fromEnvironment()``.
  /// - Parameter underlying: The generated client to wrap.
  public init(underlying: Client) {
    self.underlying = underlying
  }

  // URLSession-backed conveniences. Unavailable on WASI (no URLSessionTransport);
  // build a `Client` with a wasm-compatible transport and use `init(underlying:)`.
  #if !os(WASI)
    /// Creates a client that talks to the Buttondown API with the given key,
    /// server URL, and configuration.
    ///
    /// This is the designated URLSession-backed initializer; the other
    /// `apiKey`-based initializers funnel through it.
    /// - Parameters:
    ///   - apiKey: The Buttondown API key.
    ///   - serverURL: The API server URL. Defaults to ``defaultServerURL``.
    ///   - configuration: The generated-client configuration.
    public init(
      apiKey: String,
      serverURL: URL = ButtondownClient.defaultServerURL,
      configuration: Configuration
    ) {
      self.init(
        underlying: Client(
          serverURL: serverURL,
          configuration: configuration,
          transport: URLSessionTransport(),
          middlewares: [AuthenticationMiddleware(apiKey: apiKey)]
        )
      )
    }

    /// Creates a client that talks to the Buttondown API with the given key,
    /// server URL, and date transcoder.
    /// - Parameters:
    ///   - apiKey: The Buttondown API key.
    ///   - serverURL: The API server URL. Defaults to ``defaultServerURL``.
    ///   - dateTranscoder: The transcoder used to decode API timestamps.
    ///     Defaults to ``LenientISO8601DateTranscoder``.
    public init(
      apiKey: String,
      serverURL: URL = ButtondownClient.defaultServerURL,
      dateTranscoder: any DateTranscoder = LenientISO8601DateTranscoder.default
    ) {
      self.init(
        apiKey: apiKey,
        serverURL: serverURL,
        configuration: Configuration(dateTranscoder: dateTranscoder)
      )
    }

    /// Creates a client using the `BUTTONDOWN_API_KEY` environment variable.
    /// - Throws: ``ClientError/missingAPIKey`` if the variable is unset/empty.
    public static func fromEnvironment() throws -> ButtondownClient {
      guard
        let apiKey = ProcessInfo.processInfo.environment["BUTTONDOWN_API_KEY"],
        !apiKey.isEmpty
      else {
        throw ClientError.missingAPIKey
      }
      return ButtondownClient(apiKey: apiKey)
    }
  #endif
}
