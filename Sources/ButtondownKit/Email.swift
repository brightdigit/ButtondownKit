//
//  Email.swift
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

/// A Buttondown email (newsletter issue), reduced to the fields the site
/// consumes.
///
/// A Swift-native flattening of the 22-field generated `Components.Schemas.Email`
/// schema, mapped via ``init(from:)``. Kept intentionally small so
/// `Components.Schemas.*` never leaks into the public API; add fields here as new
/// consumers need them.
public struct Email: Equatable, Sendable {
  /// A unique TypeID associated with the email.
  public let id: String
  /// The subject line for the email.
  public let subject: String
  /// The body of the email, in HTML or Markdown format.
  public let body: String
  /// The current lifecycle status of the email.
  public let status: EmailStatus
  /// The date and time at which the email was first created.
  public let creationDate: Date
  /// The date and time at which the email was last modified.
  public let modificationDate: Date
  /// The canonical web URL of the email on the newsletter's archive.
  public let absoluteURL: String
  /// A human-readable description of the email, used for archives and SEO.
  public let description: String
  /// A primary image URL used when previewing the email on the web.
  public let image: String

  /// Memberwise initializer.
  public init(
    id: String,
    subject: String,
    body: String,
    status: EmailStatus,
    creationDate: Date,
    modificationDate: Date,
    absoluteURL: String,
    description: String,
    image: String
  ) {
    self.id = id
    self.subject = subject
    self.body = body
    self.status = status
    self.creationDate = creationDate
    self.modificationDate = modificationDate
    self.absoluteURL = absoluteURL
    self.description = description
    self.image = image
  }
}

extension Email {
  /// Maps a generated OpenAPI `Components.Schemas.Email` into the domain model.
  internal init(from email: Components.Schemas.Email) {
    self.init(
      id: email.id,
      subject: email.subject,
      body: email.body,
      status: EmailStatus(from: email.status),
      creationDate: email.creation_date,
      modificationDate: email.modification_date,
      absoluteURL: email.absolute_url,
      description: email.description,
      image: email.image
    )
  }
}
