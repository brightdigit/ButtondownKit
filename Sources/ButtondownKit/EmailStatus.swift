//
//  EmailStatus.swift
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

/// The lifecycle state of a Buttondown email.
///
/// A Swift-native mirror of the generated `Components.Schemas.EmailStatus`
/// schema, so callers never touch `Components.Schemas.*`. It maps in from the
/// generated enum (``init(from:)``) and back out (``schema``) for the `status`
/// filter passed to `list_emails`.
public enum EmailStatus: String, Equatable, Sendable, CaseIterable {
  /// An unsent draft.
  case draft
  /// Managed by an RSS-to-email automation.
  case managedByRSS
  /// Queued and about to send.
  case aboutToSend
  /// Scheduled to send at a future time.
  case scheduled
  /// Currently being delivered.
  case inFlight
  /// Sending is paused.
  case paused
  /// Deleted.
  case deleted
  /// Sending errored.
  case errored
  /// Fully sent.
  case sent
  /// Imported from an external source.
  case imported
  /// Throttled by sending limits.
  case throttled
  /// Being re-sent.
  case resending
  /// A transactional (non-broadcast) email.
  case transactional
  /// Suppressed from sending.
  case suppressed
}

extension EmailStatus {
  /// The generated `EmailStatus` equivalent, for query filters sent to the API.
  internal var schema: Components.Schemas.EmailStatus {
    switch self {
    case .draft: .draft
    case .managedByRSS: .managed_by_rss
    case .aboutToSend: .about_to_send
    case .scheduled: .scheduled
    case .inFlight: .in_flight
    case .paused: .paused
    case .deleted: .deleted
    case .errored: .errored
    case .sent: .sent
    case .imported: .imported
    case .throttled: .throttled
    case .resending: .resending
    case .transactional: .transactional
    case .suppressed: .suppressed
    }
  }

  /// Maps a generated `EmailStatus` into the Swift-native status.
  internal init(from status: Components.Schemas.EmailStatus) {
    self = status.domain
  }
}

extension Components.Schemas.EmailStatus {
  /// The Swift-native ``EmailStatus`` equivalent of this generated status.
  ///
  /// A flat, exhaustive 1:1 mapping the compiler keeps in sync with the
  /// generated enum. The return type is module-qualified so it is not shadowed
  /// by the generated `Components.Schemas.EmailStatus` being extended.
  internal var domain: ButtondownKit.EmailStatus {
    switch self {
    case .draft: .draft
    case .managed_by_rss: .managedByRSS
    case .about_to_send: .aboutToSend
    case .scheduled: .scheduled
    case .in_flight: .inFlight
    case .paused: .paused
    case .deleted: .deleted
    case .errored: .errored
    case .sent: .sent
    case .imported: .imported
    case .throttled: .throttled
    case .resending: .resending
    case .transactional: .transactional
    case .suppressed: .suppressed
    }
  }
}
