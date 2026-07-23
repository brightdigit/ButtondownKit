//
//  EmailUpdatingTests.swift
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

@Suite internal struct EmailUpdatingTests {
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

  /// `updateEmail` PATCHes `/emails/{id}` with only the supplied fields and
  /// decodes the 200 `Email` back — the read-clean-write round trip.
  @Test internal func updateEmailRoundTrip() async throws {
    let transport = MockTransport(responses: [
      "PATCH /emails/\(Self.emailID)": [.init(status: 200, json: try fixture("email-updated"))]
    ])
    let client = try makeClient(transport)

    let email = try await client.updateEmail(
      id: Self.emailID,
      body: "# Heading\n\nThis is the cleaned newsletter body.",
      description: "Archive description",
      image: "https://example.com/social.jpg",
      publishDate: Date(timeIntervalSince1970: 1_704_067_200),
      status: .imported
    )

    #expect(email.id == Self.emailID)
    #expect(email.status == .imported)
    #expect(email.body.contains("cleaned newsletter body"))

    let recorded = await transport.recorded
    let request = try #require(recorded.first)
    #expect(request.method == "PATCH")
    #expect(request.path == "/emails/\(Self.emailID)")
    let body = try #require(request.body)
    #expect(body.contains("cleaned newsletter body"), "the new body should be sent")
    #expect(body.contains("Archive description"), "description should serialize")
    #expect(body.contains("social.jpg"), "image should serialize")
    #expect(body.contains("2024-01-01T00:00:00Z"), "publish date should serialize as ISO-8601")
    #expect(body.contains("imported"), "status should serialize as imported")
    // Unspecified fields are omitted from the PATCH payload.
    #expect(!body.contains("\"subject\""), "subject was not supplied, so it should be omitted")
  }

  /// The authentication middleware attaches `Authorization: Token <key>`.
  @Test internal func updateEmailAttachesAuthorization() async throws {
    let transport = MockTransport(responses: [
      "PATCH /emails/\(Self.emailID)": [.init(status: 200, json: try fixture("email-updated"))]
    ])
    let client = try makeClient(transport)

    _ = try await client.updateEmail(id: Self.emailID, body: "b")

    let recorded = await transport.recorded
    let request = try #require(recorded.first)
    #expect(request.headerFields[.authorization] == "Token \(Self.apiKey)")
  }

  /// A documented error status (403) surfaces as `unexpectedResponse`.
  @Test internal func updateEmailUnexpectedStatusThrows() async throws {
    let transport = MockTransport(responses: [
      "PATCH /emails/\(Self.emailID)": [
        .init(status: 403, json: #"{"detail":"nope","code":"forbidden"}"#)
      ]
    ])
    let client = try makeClient(transport)

    await #expect(throws: ButtondownClient.ClientError.unexpectedResponse) {
      _ = try await client.updateEmail(id: Self.emailID, body: "b")
    }
  }
}
