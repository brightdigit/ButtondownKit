//
//  EmailListing.swift
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

/// The capability to read (and page through) a newsletter's emails.
public protocol EmailListing {
  /// Retrieves a single page of emails.
  /// - Parameters:
  ///   - status: If non-empty, only return emails with one of these statuses.
  ///   - page: The 1-based page number to fetch.
  /// - Returns: The ``EmailPage`` for the requested page.
  /// - Throws: An error if the request fails or the response is unexpected.
  func listEmails(
    status: [EmailStatus],
    page: Int?
  ) async throws -> EmailPage

  /// Enumerates every email across all pages.
  /// - Parameters:
  ///   - status: If non-empty, only return emails with one of these statuses.
  ///   - pageLimit: The maximum number of pages to fetch, if any.
  /// - Returns: All ``Email`` values across the fetched pages.
  /// - Throws: An error if a request fails or a response is unexpected.
  func listAllEmails(
    status: [EmailStatus],
    pageLimit: Int?
  ) async throws -> [Email]
}

extension EmailListing where Self: UnderlyingClientProtocol {
  /// Retrieves a single page of emails. Maps to `GET /emails`.
  ///
  /// Buttondown paginates with a 1-based `page` query parameter; the returned
  /// page carries the emails for that page plus the total `count` across all
  /// pages. Use ``listAllEmails(status:pageLimit:)`` to walk every page.
  /// - Parameters:
  ///   - status: If non-empty, only return emails with one of the given
  ///     statuses (server-side filter, e.g. `[.sent]`).
  ///   - page: The 1-based page number to fetch. Defaults to the first page.
  /// - Returns: The ``EmailPage`` for the requested page.
  /// - Throws: ``ButtondownClient/ClientError/unexpectedResponse`` on a non-200
  ///   response, or a transport/decoding error.
  public func listEmails(
    status: [EmailStatus] = [],
    page: Int? = nil
  ) async throws -> EmailPage {
    let output = try await underlying.list_emails(
      query: .init(
        status: status.isEmpty ? nil : status.map(\.schema),
        page: page
      )
    )
    switch output {
    case .ok(let response):
      return try EmailPage(from: response.body.json)
    default:
      throw ButtondownClient.ClientError.unexpectedResponse
    }
  }

  /// Enumerates every email across all pages. Maps to repeated `GET /emails`.
  ///
  /// Walks pages starting at 1, accumulating emails, and stops once the
  /// collected count reaches the reported total `count`, a page comes back
  /// empty, or `pageLimit` pages have been fetched (whichever comes first).
  /// - Parameters:
  ///   - status: If non-empty, only return emails with one of the given
  ///     statuses (server-side filter, e.g. `[.sent]`).
  ///   - pageLimit: The maximum number of pages to fetch. Defaults to `nil`
  ///     (no limit — walk until the count is reached).
  /// - Returns: All ``Email`` values across the fetched pages, in the order the
  ///   API returns them.
  /// - Throws: ``ButtondownClient/ClientError/unexpectedResponse`` on a non-200
  ///   response, or a transport/decoding error.
  public func listAllEmails(
    status: [EmailStatus] = [],
    pageLimit: Int? = nil
  ) async throws -> [Email] {
    var collected: [Email] = []
    var page = 1
    while true {
      let result = try await listEmails(status: status, page: page)
      collected.append(contentsOf: result.emails)
      if result.emails.isEmpty || collected.count >= result.count {
        break
      }
      if let pageLimit, page >= pageLimit {
        break
      }
      page += 1
    }
    return collected
  }
}
