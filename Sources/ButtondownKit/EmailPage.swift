//
//  EmailPage.swift
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

/// A single page of a paginated email listing.
///
/// A Swift-native flattening of the generated `Components.Schemas.EmailPage`
/// schema, mapped via ``init(from:)``, so callers see domain ``Email`` values
/// rather than `Components.Schemas.*`.
public struct EmailPage: Equatable, Sendable {
  /// The total number of emails across all pages.
  public let count: Int
  /// The emails on this page.
  public let emails: [Email]

  /// Memberwise initializer.
  public init(count: Int, emails: [Email]) {
    self.count = count
    self.emails = emails
  }
}

extension EmailPage {
  /// Maps a generated OpenAPI `Components.Schemas.EmailPage` into the domain
  /// model.
  internal init(from page: Components.Schemas.EmailPage) {
    self.init(
      count: page.count,
      emails: page.results.map(Email.init(from:))
    )
  }
}
