//
//  TokenKind.swift
//  CodeHighlighting
//
//  The semantic role of a highlighted token.
//
//  Created by David Sherlock on 7/9/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The semantic role of a highlighted token. A ``TokenColorProviding`` maps each
/// role to a concrete color, so the highlighter itself stays theme-agnostic.
public enum TokenKind: Sendable {
    /// Line and block comments.
    case comment
    /// String and character literals.
    case string
    /// Language keywords (`if`, `func`, `return`, …).
    case keyword
    /// Type names and built-in types.
    case type
    /// Numeric literals (also used for `true`/`false`/`nil`-style constants).
    case number
    /// Function and method names (usually at the call/definition site).
    case function
    /// Attributes, annotations, and decorators (`@Published`, `#[derive]`, …).
    case attribute
    /// Variables a grammar singles out — `self`, parameters, built-in variables.
    case variable
    /// Plain names no other role claims. A theme paints them a quiet tint of the foreground, or the
    /// foreground itself where names are meant to stay plain.
    case identifier
    /// Properties, fields, and object keys.
    case property
    /// Added lines in a diff/patch (themes map this to their diff-added tint).
    case added
    /// Removed lines in a diff/patch (themes map this to their diff-removed tint).
    case removed
}
