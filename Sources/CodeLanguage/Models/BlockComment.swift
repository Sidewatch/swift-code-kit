//
//  BlockComment.swift
//  CodeLanguage
//
//  A language's block-comment delimiters.
//
//  Created by David Sherlock on 7/9/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The opening and closing delimiters of a language's block comment,
/// e.g. `/* … */` for C or `(* … *)` for OCaml.
public struct BlockComment: Sendable, Equatable {

    /// The opening delimiter, e.g. `"/*"`.
    public let open: String

    /// The closing delimiter, e.g. `"*/"`.
    public let close: String

    /// Creates a delimiter pair from its opening and closing tokens.
    public init(open: String, close: String) {
        self.open = open
        self.close = close
    }
}
