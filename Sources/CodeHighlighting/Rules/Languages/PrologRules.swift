//
//  PrologRules.swift
//  CodeHighlighting
//
//  The regex rule table for Prolog.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Prolog: `%` and block comments, quoted atoms, `` `codes` ``, capitalised variables, the `:-` neck,
/// predicate calls. A character code (`0'a`, `0''`, `0'''`, `0'\n`) is painted whole as a literal and a
/// radix number (`16'FF`) as a number, so neither quote opens a quoted atom.
extension RuleTables {
    static let prolog: [(String, TokenKind)] = [
        ("%.*$", .comment),
        blockComment,
        doubleQuoted,
        backQuoted,
        ("\\b0'(?:\\\\(?:x[0-9a-fA-F]+\\\\?|[0-7]+\\\\?|.)|''|.)", .string),
        ("(?<![\\w'])'(?:[^'\\\\]|''|\\\\[\\s\\S])*'", .string),
        (":-|-->|\\?-|\\\\\\+|->|;", .keyword),
        keywords([
            "is", "mod", "rem", "not", "true", "fail", "false", "dynamic", "discontiguous", "module", "use_module", "initialization",
            "findall", "bagof", "setof", "forall", "length", "member", "append", "nth0", "nth1", "assert", "asserta", "assertz", "retract",
            "write", "writeln", "nl", "format", "halt",
        ]),
        ("\\b[A-Z_][A-Za-z0-9_]*\\b", .variable),
        ("\\b[a-z]\\w*(?=\\()", .function),
        (
            "\\b(?:0x[0-9a-fA-F_]+|0o[0-7_]+|0b[01_]+|\\d+'[0-9a-zA-Z]+|\\d+(?:_\\d+)*(?:\\.\\d+(?:[eE][+-]?\\d+)?(?:Inf|NaN)?|[eE][+-]?\\d+|r\\d+)?)\\b",
            .number
        ),
    ]
}
