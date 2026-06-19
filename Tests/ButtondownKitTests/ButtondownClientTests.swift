//
//  ButtondownClientTests.swift
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

@Suite internal struct ButtondownClientTests {
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

  /// `createDraft` POSTs the Markdown body and decodes the 201 `Email` back —
  /// the create-draft round trip.
  @Test internal func createDraftRoundTrip() async throws {
    let transport = MockTransport(responses: [
      "POST /emails": [.init(status: 201, json: try fixture("email-created"))]
    ])
    let client = try makeClient(transport)

    let email = try await client.createDraft(
      subject: "Hello from ButtondownKit",
      body: "# Heading\n\nThis is a **Markdown** newsletter body."
    )

    #expect(email.id == Self.emailID)
    #expect(email.subject == "Hello from ButtondownKit")
    #expect(email.status == .draft)
    #expect(email.source == .api)

    // The request carried the Markdown body unchanged (no HTML conversion).
    let recorded = await transport.recorded
    let request = try #require(recorded.first)
    #expect(request.method == "POST")
    #expect(request.path == "/emails")
    let body = try #require(request.body)
    #expect(body.contains("**Markdown**"))
    #expect(body.contains("draft"), "status should serialize as draft")
  }

  /// The authentication middleware attaches `Authorization: Token <key>`.
  @Test internal func authorizationHeaderIsAttached() async throws {
    let transport = MockTransport(responses: [
      "POST /emails": [.init(status: 201, json: try fixture("email-created"))]
    ])
    let client = try makeClient(transport)

    _ = try await client.createDraft(subject: "s", body: "b")

    let recorded = await transport.recorded
    let request = try #require(recorded.first)
    #expect(
      request.headerFields[.authorization] == "Token \(Self.apiKey)"
    )
  }

  /// `sendDraft` hits `POST /emails/{id}/send-draft` and treats 200 as success.
  @Test internal func sendDraft() async throws {
    let transport = MockTransport(responses: [
      "POST /emails/\(Self.emailID)/send-draft": [.init(status: 200, json: "{}")]
    ])
    let client = try makeClient(transport)

    try await client.sendDraft(id: Self.emailID)

    let recorded = await transport.recorded
    let request = try #require(recorded.first)
    #expect(request.method == "POST")
    #expect(request.path == "/emails/\(Self.emailID)/send-draft")
  }

  /// `email(id:)` reads back a single email via `GET /emails/{id}`.
  @Test internal func retrieveEmail() async throws {
    let transport = MockTransport(responses: [
      "GET /emails/\(Self.emailID)": [.init(status: 200, json: try fixture("email-created"))]
    ])
    let client = try makeClient(transport)

    let email = try await client.email(id: Self.emailID)

    #expect(email.id == Self.emailID)
    let recorded = await transport.recorded
    #expect(recorded.first?.method == "GET")
  }

  /// A documented error status (403) surfaces as `unexpectedResponse`.
  @Test internal func forbiddenSurfacesAsError() async throws {
    let transport = MockTransport(responses: [
      "POST /emails": [
        .init(status: 403, json: #"{"detail":"nope","code":"forbidden"}"#)
      ]
    ])
    let client = try makeClient(transport)

    await #expect(throws: ButtondownClient.ClientError.unexpectedResponse) {
      _ = try await client.createDraft(subject: "s", body: "b")
    }
  }

  /// `fromEnvironment()` throws when `BUTTONDOWN_API_KEY` is unset.
  ///
  /// Disabled when the key happens to be set in the running environment.
  @Test(
    .enabled(if: ProcessInfo.processInfo.environment["BUTTONDOWN_API_KEY"] == nil)
  )
  internal func fromEnvironmentMissingKeyThrows() throws {
    #expect(throws: ButtondownClient.ClientError.missingAPIKey) {
      _ = try ButtondownClient.fromEnvironment()
    }
  }

  /// A documented error status on `sendDraft` surfaces as `unexpectedResponse`.
  @Test internal func sendDraftUnexpectedStatusThrows() async throws {
    let transport = MockTransport(responses: [
      "POST /emails/\(Self.emailID)/send-draft": [
        .init(status: 403, json: #"{"detail":"nope","code":"forbidden"}"#)
      ]
    ])
    let client = try makeClient(transport)

    await #expect(throws: ButtondownClient.ClientError.unexpectedResponse) {
      try await client.sendDraft(id: Self.emailID)
    }
  }

  /// A documented error status on `email(id:)` surfaces as `unexpectedResponse`.
  @Test internal func retrieveEmailUnexpectedStatusThrows() async throws {
    let transport = MockTransport(responses: [
      "GET /emails/\(Self.emailID)": [
        .init(status: 403, json: #"{"detail":"nope","code":"forbidden"}"#)
      ]
    ])
    let client = try makeClient(transport)

    await #expect(throws: ButtondownClient.ClientError.unexpectedResponse) {
      _ = try await client.email(id: Self.emailID)
    }
  }

  /// `init(apiKey:)` builds a live-transport client without throwing.
  @Test internal func initWithAPIKeySucceeds() throws {
    _ = try ButtondownClient(apiKey: Self.apiKey)
  }
}
