//
//  SMLRules.swift
//  CodeHighlighting
//
//  The regex rule table for Standard ML.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Standard ML: nesting `(* *)` comments (the language table adds them) — there is no `--` comment;
/// `"…"` strings with backslash escapes and `#"a"` character literals, while a type variable `'a` opens
/// nothing; the Definition's reserved words (core and modules); `~1` negatives, `0wx` words and reals.
extension RuleTables {
    static let sml: [(String, TokenKind)] = [
        ("#?\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        keywords([
            "abstype", "and", "andalso", "as", "case", "datatype", "do", "else", "end", "eqtype", "exception", "fn",
            "fun", "functor", "handle", "if", "in", "include", "infix", "infixr", "let", "local", "nonfix", "of", "op",
            "open", "orelse", "raise", "rec", "sharing", "sig", "signature", "struct", "structure", "then", "type",
            "val", "where", "while", "with", "withtype",
        ]),
        constants(["true", "false", "nil"]),
        ("\\b[A-Z][A-Za-z0-9_']*", .type),
        ("(?<![\\w'])~?(?:0w?x[0-9a-fA-F]+|0w\\d+|\\d+(?:\\.\\d+)?(?:[eE]~?\\d+)?)\\b", .number),
    ]
}
