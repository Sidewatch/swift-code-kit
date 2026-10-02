//
//  WolframRules.swift
//  CodeHighlighting
//
//  The regex rule table for the Wolfram Language.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The Wolfram Language: nesting `(* *)` comments (the language table adds them) — `--` is decrement, never
/// a comment; `"…"` strings with backslash escapes; `Context`` names; `x_`, `x__`, `x_Integer` patterns;
/// `#`, `#1`, `##` slots; capitalised built-in symbols; `16^^FF`, `1.5*^-3`, `3.14`20` numbers.
extension RuleTables {
    static let wolfram: [(String, TokenKind)] = [
        doubleQuoted,
        ("\\b([A-Z][A-Za-z0-9$]*)(?=\\[)", .function),
        ("\\b[A-Z][A-Za-z0-9$]*`(?:[A-Za-z][A-Za-z0-9$]*`)*", .type),
        ("\\b[A-Za-z$][A-Za-z0-9$]*_{1,3}(?:[A-Z][A-Za-z0-9]*)?", .variable),
        ("#{1,2}\\d*", .property),
        constants(["True", "False", "Null", "None", "All", "Automatic", "Infinity", "Pi", "E", "I"]),
        ("\\b\\d+\\^\\^[0-9A-Za-z]+|\\b\\d+(?:\\.\\d*)?(?:``?[\\d.]*)?(?:\\*\\^-?\\d+)?|\\.\\d+", .number),
    ]
}
