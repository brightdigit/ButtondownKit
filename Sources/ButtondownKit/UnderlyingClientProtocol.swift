//
//  UnderlyingClientProtocol.swift
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

/// The shared seam the Buttondown capability protocols implement against.
///
/// Each capability (listing, drafting, retrieving) provides its methods in a
/// protocol extension constrained on `Self: UnderlyingClientProtocol`, calling
/// through ``underlying``, so ``ButtondownClient`` itself is only storage plus
/// initializers.
///
/// This protocol must be **public**: the capability protocols' methods are
/// public requirements witnessed by those constrained extensions, and Swift
/// forbids a `public` member in an extension whose generic constraint refers to
/// a non-public protocol ("cannot declare a public instance method in an
/// extension with internal requirements"). Exposing ``Client`` here is
/// therefore unavoidable, and is consistent with `ButtondownClient.init(underlying:)`,
/// which is already public and which the mock-transport tests use.
public protocol UnderlyingClientProtocol {
  /// The generated, transport-backed API client the wrappers call through.
  var underlying: Client { get }
}
