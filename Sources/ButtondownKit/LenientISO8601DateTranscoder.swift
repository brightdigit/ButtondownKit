//
//  LenientISO8601DateTranscoder.swift
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

/// A ``DateTranscoder`` that decodes RFC-3339 / ISO-8601 timestamps whether or
/// not they carry fractional seconds.
///
/// The Buttondown API mixes both forms in a single response — e.g.
/// `creation_date` is `"2026-06-29T18:36:10.808726Z"` (fractional seconds) while
/// `publish_date` is `"2026-06-30T12:03:00Z"` (none). OpenAPIRuntime's default
/// ``ISO8601DateTranscoder`` is configured for exactly one shape and throws
/// `DecodingError.dataCorrupted` on the other, which makes every real listing
/// fail to decode. This transcoder tries the fractional-seconds parse first and
/// falls back to the whole-second parse, so both shapes decode.
///
/// Parsing goes through the value-type `Date.ISO8601FormatStyle`, which carries
/// no shared mutable state and is trivially `Sendable`. The styles tried when
/// decoding — and the style used when encoding — are injectable, so the mixed
/// fractional/whole-second default can be overridden for other APIs.
public struct LenientISO8601DateTranscoder: DateTranscoder {
  /// The ISO-8601 style requiring fractional seconds (e.g. `...10.808Z`).
  private static let fractionalSecondsStyle = Date.ISO8601FormatStyle(
    includingFractionalSeconds: true
  )

  /// The ISO-8601 style requiring whole seconds (e.g. `...10Z`).
  private static let wholeSecondsStyle = Date.ISO8601FormatStyle(
    includingFractionalSeconds: false
  )

  /// A transcoder covering the mixed fractional/whole-second timestamps the
  /// Buttondown API returns: decode tries fractional seconds first and whole
  /// seconds second; encode emits fractional seconds.
  public static let `default` = LenientISO8601DateTranscoder(
    decodeStyles: [fractionalSecondsStyle, wholeSecondsStyle],
    encodeStyle: fractionalSecondsStyle
  )

  /// The styles attempted, in order, when decoding.
  private let decodeStyles: [Date.ISO8601FormatStyle]

  /// The style used when encoding.
  private let encodeStyle: Date.ISO8601FormatStyle

  /// Creates a lenient transcoder.
  ///
  /// - Parameters:
  ///   - decodeStyles: The ISO-8601 styles tried, in order, when decoding.
  ///   - encodeStyle: The style used when encoding.
  public init(
    decodeStyles: [Date.ISO8601FormatStyle],
    encodeStyle: Date.ISO8601FormatStyle
  ) {
    self.decodeStyles = decodeStyles
    self.encodeStyle = encodeStyle
  }

  /// Encodes the date using ``encodeStyle``.
  public func encode(_ date: Date) throws -> String {
    date.formatted(encodeStyle)
  }

  /// Decodes an ISO-8601 string by trying each style in ``decodeStyles`` until
  /// one succeeds.
  ///
  /// - Throws: `DecodingError.dataCorrupted` when no style parses the string;
  ///   its context aggregates every style's error in `debugDescription` and
  ///   carries the last one as `underlyingError`.
  public func decode(_ dateString: String) throws -> Date {
    var errors: [any Error] = []
    for style in decodeStyles {
      do {
        return try style.parse(dateString)
      } catch {
        errors.append(error)
      }
    }
    let reasons = errors.map { String(describing: $0) }.joined(separator: "; ")
    throw DecodingError.dataCorrupted(
      .init(
        codingPath: [],
        debugDescription:
          "Expected date string to be ISO8601-formatted matching one of "
          + "\(decodeStyles.count) style(s): \"\(dateString)\". "
          + "Underlying errors: \(reasons)",
        underlyingError: errors.last
      )
    )
  }
}
