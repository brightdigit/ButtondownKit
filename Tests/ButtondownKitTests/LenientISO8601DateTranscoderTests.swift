//
//  LenientISO8601DateTranscoderTests.swift
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
import Testing

@testable import ButtondownKit

/// Verifies the lenient date transcoder decodes the mixed timestamp shapes the
/// Buttondown API returns, both directly and end-to-end through a listing.
@Suite internal struct LenientISO8601DateTranscoderTests {
  private static let apiKey = "FAKE_KEY"

  /// Loads a JSON fixture from the test bundle's copied `Fixtures` directory.
  private func fixture(_ name: String) throws -> String {
    let url = try #require(
      Bundle.module.url(
        forResource: name,
        withExtension: "json",
        subdirectory: "Fixtures"
      ),
      "missing fixture \(name).json"
    )
    return try String(contentsOf: url, encoding: .utf8)
  }

  /// A timestamp with fractional seconds decodes to the expected instant.
  @Test internal func decodesFractionalSeconds() throws {
    let transcoder = LenientISO8601DateTranscoder.default
    let date = try transcoder.decode("2026-06-29T18:36:10.808726Z")
    // 2026-06-29T18:36:10Z is 1_782_758_170 seconds since the epoch; the
    // fractional part adds within the same second.
    #expect(abs(date.timeIntervalSince1970 - 1_782_758_170.808) < 0.01)
  }

  /// A timestamp with no fractional seconds still decodes (the fallback path).
  @Test internal func decodesWholeSeconds() throws {
    let transcoder = LenientISO8601DateTranscoder.default
    let date = try transcoder.decode("2026-06-30T12:03:00Z")
    #expect(date.timeIntervalSince1970 == 1_782_820_980)
  }

  /// A non-ISO8601 string throws rather than returning a bogus date.
  @Test internal func rejectsGarbage() {
    let transcoder = LenientISO8601DateTranscoder.default
    #expect(throws: (any Error).self) {
      _ = try transcoder.decode("not-a-date")
    }
  }

  /// Round-trips a fixture whose timestamps mix fractional and whole seconds
  /// through a real generated `Client` — the shape that previously failed to
  /// decode against the live API.
  @Test internal func listAllEmailsDecodesMixedTimestamps() async throws {
    let transport = MockTransport(responses: [
      "GET /emails": [.init(status: 200, json: try fixture("emails-fractional"))]
    ])
    let generated = Client(
      serverURL: try Servers.Server1.url(),
      configuration: ButtondownClient.defaultConfiguration,
      transport: transport,
      middlewares: [AuthenticationMiddleware(apiKey: Self.apiKey)]
    )
    let client = ButtondownClient(underlying: generated)
    let emails = try await client.listAllEmails(status: [.sent])
    #expect(emails.count == 2)
    #expect(emails.map(\.subject) == ["Fractional One", "Whole Second Two"])
  }
}
