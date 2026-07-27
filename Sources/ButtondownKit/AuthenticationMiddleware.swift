//
//  AuthenticationMiddleware.swift
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
public import HTTPTypes
public import OpenAPIRuntime

/// A ``ClientMiddleware`` that injects the Buttondown API key into every
/// request as an `Authorization: Token <key>` header.
///
/// Buttondown's `ApiKeyAuth` security scheme expects the key in the
/// `Authorization` header prefixed with `Token `. swift-openapi-generator does
/// not emit authentication code, so the credential is attached here at the
/// transport boundary. The key itself comes from the `BUTTONDOWN_API_KEY`
/// environment variable (see ``ButtondownClient``); no audience data or
/// credentials are stored in the repository.
public struct AuthenticationMiddleware: ClientMiddleware {
  /// The Buttondown API key, sent verbatim after the `Token ` prefix.
  private let apiKey: String

  /// Creates a middleware that authenticates requests with the given key.
  /// - Parameter apiKey: The Buttondown API key.
  public init(apiKey: String) {
    self.apiKey = apiKey
  }

  /// Adds the `Authorization: Token <key>` header, then forwards the request
  /// to the next middleware/transport in the chain.
  /// - Returns: The response produced downstream.
  /// - Throws: Any error thrown by a downstream middleware or the transport.
  public func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID _: String,
    next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    var request = request
    request.headerFields[.authorization] = "Token \(apiKey)"
    return try await next(request, body, baseURL)
  }
}
