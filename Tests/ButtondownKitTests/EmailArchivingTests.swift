//
//  EmailArchivingTests.swift
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
import Testing

@testable import ButtondownKit

@Suite internal struct EmailArchivingTests {
  private static let apiKey = "FAKE_KEY"
  private static let emailID = "00000000-0000-0000-0000-000000000001"

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

  /// Builds a `ButtondownClient` over the supplied mock transport, with the
  /// real authentication middleware in place so its behaviour is exercised.
  private func makeClient(_ transport: MockTransport) throws -> ButtondownClient {
    let generated = Client(
      serverURL: try Servers.Server1.url(),
      transport: transport,
      middlewares: [AuthenticationMiddleware(apiKey: Self.apiKey)]
    )
    return ButtondownClient(underlying: generated)
  }

  /// `createArchived` POSTs an `imported`/archival-enabled email and decodes the
  /// 201 `Email` back — the historical-issue backfill round trip.
  @Test internal func createArchivedRoundTrip() async throws {
    let transport = MockTransport(responses: [
      "POST /emails": [.init(status: 201, json: try fixture("email-archived"))]
    ])
    let client = try makeClient(transport)

    let email = try await client.createArchived(
      subject: "BrightDigit #42",
      body: "# Heading\n\nThis is a backfilled archive issue body."
    )

    #expect(email.id == Self.emailID)
    #expect(email.status == .imported)
    #expect(email.body.contains("backfilled archive issue body"))

    let recorded = await transport.recorded
    let request = try #require(recorded.first)
    #expect(request.method == "POST")
    #expect(request.path == "/emails")
    let body = try #require(request.body)
    #expect(body.contains("imported"), "the email should be created with imported status")
    #expect(body.contains("enabled"), "archival_mode should serialize as enabled")
    #expect(body.contains("backfilled archive issue body"), "the body should be sent")
  }

  /// The authentication middleware attaches `Authorization: Token <key>`.
  @Test internal func createArchivedAttachesAuthorization() async throws {
    let transport = MockTransport(responses: [
      "POST /emails": [.init(status: 201, json: try fixture("email-archived"))]
    ])
    let client = try makeClient(transport)

    _ = try await client.createArchived(subject: "s", body: "b")

    let recorded = await transport.recorded
    let request = try #require(recorded.first)
    #expect(request.headerFields[.authorization] == "Token \(Self.apiKey)")
  }

  /// A documented error status (403) surfaces as `unexpectedResponse`.
  @Test internal func createArchivedUnexpectedStatusThrows() async throws {
    let transport = MockTransport(responses: [
      "POST /emails": [
        .init(status: 403, json: #"{"detail":"nope","code":"forbidden"}"#)
      ]
    ])
    let client = try makeClient(transport)

    await #expect(throws: ButtondownClient.ClientError.unexpectedResponse) {
      _ = try await client.createArchived(subject: "s", body: "b")
    }
  }
}
