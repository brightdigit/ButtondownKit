//
//  MockTransport.swift
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
import HTTPTypes
import OpenAPIRuntime

/// A `ClientTransport` that replays pre-canned responses keyed by
/// `"<METHOD> <path>"`, so the generated client can be exercised offline.
///
/// Each entry is consumed in order, allowing multiple calls to the same
/// endpoint to return successive responses. Every request is recorded so tests
/// can assert on the method, path, captured body, and headers.
internal actor MockTransport: ClientTransport {
  /// A recorded canned response: status code and optional JSON body.
  internal struct Response: Sendable {
    internal let status: Int
    internal let json: String?

    internal init(status: Int = 200, json: String? = nil) {
      self.status = status
      self.json = json
    }
  }

  /// A request the transport observed.
  internal struct RecordedRequest: Sendable {
    internal let method: String
    internal let path: String
    internal let body: String?
    internal let headerFields: HTTPFields
  }

  /// Queued responses keyed by `"<METHOD> <path>"`; consumed in order.
  private var responses: [String: [Response]]
  /// Every request the transport observed, in order.
  internal private(set) var recorded: [RecordedRequest] = []

  internal init(responses: [String: [Response]]) {
    self.responses = responses
  }

  internal func send(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL _: URL,
    operationID _: String
  ) async throws -> (HTTPResponse, HTTPBody?) {
    let path = request.path ?? ""
    let key = "\(request.method.rawValue) \(path.split(separator: "?").first ?? "")"

    var bodyString: String?
    if let body {
      let bytes = try await [UInt8](collecting: body, upTo: .max)
      bodyString = String(decoding: bytes, as: UTF8.self)
    }
    recorded.append(
      RecordedRequest(
        method: request.method.rawValue,
        path: path,
        body: bodyString,
        headerFields: request.headerFields
      )
    )

    guard var queue = responses[key], !queue.isEmpty else {
      return (HTTPResponse(status: .init(code: 404)), nil)
    }
    let response = queue.removeFirst()
    responses[key] = queue

    let httpResponse = HTTPResponse(
      status: .init(code: response.status),
      headerFields: [.contentType: "application/json"]
    )
    return (httpResponse, response.json.map { HTTPBody($0) })
  }
}
