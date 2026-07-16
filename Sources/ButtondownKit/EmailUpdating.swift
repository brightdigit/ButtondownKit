//
//  EmailUpdating.swift
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

/// The capability to update (patch) an existing email.
public protocol EmailUpdating {
  /// Updates fields on an existing email, leaving unspecified fields unchanged.
  /// - Parameters:
  ///   - id: The id of the email to update.
  ///   - subject: A new subject line, or `nil` to leave it unchanged.
  ///   - body: A new body (HTML or Markdown), or `nil` to leave it unchanged.
  ///   - description: A new description, or `nil` to leave it unchanged.
  ///   - status: A new status, or `nil` to leave it unchanged.
  /// - Returns: The updated ``Email``.
  /// - Throws: An error if the request fails or the response is unexpected.
  func updateEmail(
    id: String,
    subject: String?,
    body: String?,
    description: String?,
    status: EmailStatus?
  ) async throws -> Email
}

extension EmailUpdating where Self: UnderlyingClientProtocol {
  /// Updates fields on an existing email. Maps to `PATCH /emails/{id}`.
  ///
  /// Only the arguments you supply are sent; every parameter defaults to `nil`,
  /// which the Buttondown API treats as "leave this field unchanged". This is
  /// the read-clean-write path used to repair cruft in already-hosted issues.
  /// - Parameters:
  ///   - id: The id of the email to update.
  ///   - subject: A new subject line, or `nil` to leave it unchanged.
  ///   - body: A new body (HTML or Markdown), or `nil` to leave it unchanged.
  ///   - description: A new description, or `nil` to leave it unchanged.
  ///   - status: A new status, or `nil` to leave it unchanged.
  /// - Returns: The updated ``Email``.
  /// - Throws: ``ButtondownClient/ClientError/unexpectedResponse`` on a non-200
  ///   response, or a transport/decoding error.
  public func updateEmail(
    id: String,
    subject: String? = nil,
    body: String? = nil,
    description: String? = nil,
    status: EmailStatus? = nil
  ) async throws -> Email {
    let input = Components.Schemas.EmailUpdateInput(
      body: body,
      description: description,
      status: status.map { .init(value1: $0.schema) },
      subject: subject
    )
    let output = try await underlying.update_email(
      path: .init(id: id),
      body: .json(input)
    )
    switch output {
    case .ok(let response):
      return try Email(from: response.body.json)
    default:
      throw ButtondownClient.ClientError.unexpectedResponse
    }
  }
}
