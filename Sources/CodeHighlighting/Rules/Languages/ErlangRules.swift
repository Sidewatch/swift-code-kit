//
//  ErlangRules.swift
//  CodeHighlighting
//
//  The regex rule table for Erlang.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Erlang: `%` comments, quoted atoms, capitalised variables, `-module(...)` attributes,
/// `?MACRO`, `#record`, `Mod:fun(` calls. Without it Erlang falls to the empty plain family. Keywords paint after calls,
/// so `fun(` stays a keyword.
extension RuleTables {
    static let erlang: [(String, TokenKind)] = [
        ("%.*$", .comment),
        doubleQuoted,
        ("'(?:[^'\\\\]|\\\\[\\s\\S])*'", .string),
        ("^-[a-z_]+", .attribute),
        ("\\?[A-Z_][A-Za-z0-9_]*", .type),
        ("#[a-z_]\\w*", .type),
        ("\\b[A-Z_][A-Za-z0-9_@]*\\b", .variable),
        ("\\b[a-z]\\w*:[a-z]\\w*(?=\\()", .function),
        ("\\b[a-z]\\w*(?=\\()", .function),
        keywords([
            "module", "export", "import", "define", "record", "behaviour", "behavior", "include", "include_lib", "spec", "type", "opaque",
            "callback",
            "fun", "case", "of", "end", "if", "when", "receive", "after", "try", "catch", "throw", "begin", "and", "or", "not", "andalso",
            "orelse",
            "div", "rem", "bnot", "band", "bor", "bxor", "bsl", "bsr", "xor", "cond", "let", "query",
        ]),
        ("\\b\\d+#[0-9a-zA-Z_]+\\b|\\b\\d[\\d_]*(\\.\\d[\\d_]*)?([eE][+-]?\\d+)?\\b", .number),
        // A character literal is one token, escape and all: `$a`, `$\n`, `$\x41`, `$\x{263A}`, `$\^A`, `$\101`.
        ("\\$(?:\\\\(?:x\\{[0-9A-Fa-f]+\\}|x[0-9A-Fa-f]{2}|[0-7]{1,3}|\\^.|.)|.)", .number),
    ]
}
