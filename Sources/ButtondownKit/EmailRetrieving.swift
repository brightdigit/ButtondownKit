//
//  EmailRetrieving.swift
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

/// The capability to retrieve a single email by id.
public protocol EmailRetrieving {
  /// Retrieves a single email by id.
  /// - Parameter id: The email id.
  /// - Returns: The ``Email``.
  /// - Throws: An error if the request fails or the response is unexpected.
  func email(id: String) async throws -> Email
}

extension EmailRetrieving where Self: UnderlyingClientProtocol {
  /// Retrieves a single email by id. Maps to `GET /emails/{id}`.
  /// - Parameter id: The email id.
  /// - Returns: The ``Email``.
  /// - Throws: ``ButtondownClient/ClientError/unexpectedResponse`` on a non-200
  ///   response, or a transport/decoding error.
  public func email(id: String) async throws -> Email {
    let output = try await underlying.retrieve_email(path: .init(id: id))
    switch output {
    case .ok(let response):
      return try Email(from: response.body.json)
    default:
      throw ButtondownClient.ClientError.unexpectedResponse
    }
  }
}
