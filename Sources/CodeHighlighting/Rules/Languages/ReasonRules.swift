//
//  ReasonRules.swift
//  CodeHighlighting
//
//  The regex rule table for Reason.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Reason: `//` and nesting `/* */` comments, `"…"` strings, `{|…|}` and `{js|…|js}` quoted strings,
/// `'x'` character literals (`'a` alone is a type variable), the Reason keywords, the primitive types and
/// capitalised module and constructor names, and numbers.
extension RuleTables {
    static let reason: [(String, TokenKind)] = [
        lineComment,
        nestedBlock("/*", "*/"),
        doubleQuoted,
        ("\\{([a-z_]*)\\|[\\s\\S]*?\\|\\1\\}", .string),
        ("'(?:[^'\\\\\\n]|\\\\(?:x[0-9a-fA-F]{2}|o[0-7]{3}|\\d{3}|u\\{[0-9a-fA-F]+\\}|.))'", .string),
        keywords([
            "and", "as", "assert", "begin", "class", "constraint", "do", "done", "downto", "else", "end", "exception",
            "external", "for", "fun", "function", "functor", "if", "in", "include", "inherit", "initializer", "lazy",
            "let", "module", "mutable", "new", "nonrec", "object", "of", "open", "or", "pri", "pub", "rec", "sig",
            "struct", "switch", "then", "to", "try", "type", "val", "virtual", "when", "while", "with",
        ]),
        ("\\b[A-Z]\\w*\\b", .type),
        types(["int", "float", "string", "bool", "char", "unit", "list", "array", "option", "int32", "int64", "nativeint"]),
        constants(["true", "false"]),
        ("\\b(?:0[xX][0-9a-fA-F_]+|0[oO][0-7_]+|0[bB][01_]+|\\d[\\d_]*(?:\\.[\\d_]*)?(?:[eE][+-]?\\d+)?)[lLn]?", .number),
    ]
}
