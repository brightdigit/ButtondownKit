//
//  ButtondownClientListEmailsTests.swift
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

/// Exercises the paged `listEmails` / `listAllEmails` read wrappers against the
/// offline ``MockTransport``.
@Suite internal struct ButtondownClientListEmailsTests {
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

  /// Builds a `ButtondownClient` over the supplied mock transport.
  private func makeClient(_ transport: MockTransport) throws -> ButtondownClient {
    let generated = Client(
      serverURL: try Servers.Server1.url(),
      transport: transport,
      middlewares: [AuthenticationMiddleware(apiKey: Self.apiKey)]
    )
    return ButtondownClient(underlying: generated)
  }

  /// `listEmails` reads a single page via `GET /emails`, decoding the page into
  /// the Swift-native domain types and applying the status filter.
  @Test internal func listEmailsSinglePage() async throws {
    let transport = MockTransport(responses: [
      "GET /emails": [.init(status: 200, json: try fixture("emails-page-1"))]
    ])
    let client = try makeClient(transport)
    let page: EmailPage = try await client.listEmails(
      status: [.sent],
      page: 1
    )
    #expect(page.count == 3)
    #expect(page.emails.count == 2)
    let first: Email = try #require(page.emails.first)
    #expect(first.id == "00000000-0000-0000-0000-000000000001")
    #expect(first.subject == "Issue One")
    #expect(first.status == .sent)
    let request = try #require(await transport.recorded.first)
    #expect(request.method == "GET")
    #expect(request.path.hasPrefix("/emails"))
    // Status filter is applied server-side via the query string.
    #expect(request.path.contains("status=sent"))
    #expect(request.path.contains("page=1"))
  }

  /// `listAllEmails` walks every page (1-based) until the reported `count`
  /// is reached, concatenating results in order — the paging contract.
  @Test internal func listAllEmailsWalksPages() async throws {
    let transport = MockTransport(responses: [
      "GET /emails": [
        .init(status: 200, json: try fixture("emails-page-1")),
        .init(status: 200, json: try fixture("emails-page-2")),
      ]
    ])
    let client = try makeClient(transport)
    let emails = try await client.listAllEmails(status: [.sent])
    #expect(emails.count == 3)
    #expect(emails.map(\.subject) == ["Issue One", "Issue Two", "Issue Three"])
    // Two page requests were issued; the second asked for page 2.
    let recorded = await transport.recorded
    #expect(recorded.count == 2)
    #expect(recorded.first?.path.contains("page=1") == true)
    #expect(recorded.last?.path.contains("page=2") == true)
  }

  /// `pageLimit` halts paging after the given number of pages, even when the
  /// reported `count` has not yet been reached.
  @Test internal func listAllEmailsRespectsPageLimit() async throws {
    let transport = MockTransport(responses: [
      "GET /emails": [
        .init(status: 200, json: try fixture("emails-limit-1")),
        .init(status: 200, json: try fixture("emails-limit-2")),
        .init(status: 200, json: try fixture("emails-limit-3")),
      ]
    ])
    let client = try makeClient(transport)
    let emails = try await client.listAllEmails(pageLimit: 2)
    // count is 6, but only the first 2 of the 3 queued pages were fetched.
    #expect(emails.count == 4)
    #expect(emails.map(\.subject) == ["Limit One", "Limit Two", "Limit Three", "Limit Four"])
    let recorded = await transport.recorded
    #expect(recorded.count == 2)
    #expect(recorded.last?.path.contains("page=2") == true)
  }

  /// A documented error status on `listEmails` surfaces as `unexpectedResponse`.
  @Test internal func listEmailsUnexpectedStatusThrows() async throws {
    let transport = MockTransport(responses: [
      "GET /emails": [
        .init(status: 403, json: #"{"detail":"nope","code":"forbidden"}"#)
      ]
    ])
    let client = try makeClient(transport)
    await #expect(throws: ButtondownClient.ClientError.unexpectedResponse) {
      _ = try await client.listEmails()
    }
  }
}
