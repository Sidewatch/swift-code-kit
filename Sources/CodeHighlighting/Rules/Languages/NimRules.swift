//
//  NimRules.swift
//  CodeHighlighting
//
//  The regex rule table for Nim.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Nim: `#` comments, `#[ … ]#` and `##[ … ]##` block comments (nested to two levels), `"…"` strings
/// that end at the line, `"""…"""` triple strings, raw and generalised `r"…"` / `fmt"…"` strings (a
/// doubled `""` is a quote), one-character `'…'` literals (the `'` of `1'i32` opens nothing), the
/// keywords, types, and `proc`-style declarations.
extension RuleTables {
    static let nim: [(String, TokenKind)] = [
        ("##\\[[\\s\\S]*?\\]##", .comment),
        (
            "#\\[(?:[^\\]#]|#(?!\\[)|\\](?!#)|#\\[(?:[^\\]#]|#(?!\\[)|\\](?!#))*\\]#)*\\]#",
            .comment
        ),
        hashComment,
        ("\\b[A-Za-z_]\\w*\"\"\"[\\s\\S]*?\"\"\"", .string),
        ("\\b[A-Za-z_]\\w*\"(?:[^\"\\n]|\"\")*\"", .string),
        tripleDoubleQuoted,
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("(?<![\\w'])'(?:[^'\\\\\\n]|\\\\(?:x[0-9a-fA-F]{2}|u[0-9a-fA-F]{4}|[^\\n]\\w*))'", .string),
        keywords([
            "proc", "func", "method", "iterator", "template", "macro", "converter", "type", "var", "let",
            "const", "if", "elif", "else", "when", "case", "of", "while", "for", "in", "notin", "is", "isnot",
            "block", "break", "continue", "return", "yield", "discard", "import", "from", "export", "include",
            "as", "except", "try", "finally", "raise", "defer", "using", "mixin", "bind", "static", "and",
            "or", "not", "xor", "shl", "shr", "div", "mod", "object", "tuple", "enum", "concept", "ref", "ptr",
            "out", "asm", "cast", "end", "do", "addr", "distinct", "interface", "nil",
        ]),
        constants(["true", "false", "nil"]),
        types([
            "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64", "float",
            "float32", "float64", "bool", "char", "string", "cstring", "seq", "array", "set", "openArray",
            "Table", "HashSet", "Option", "Natural", "Positive", "void", "auto", "typed", "untyped",
        ]),
        ("\\{\\.[^}]*\\.\\}", .attribute),
        ("\\b[A-Z]\\w*\\b", .type),
        ("\\b0[xX][0-9a-fA-F_]+|\\b0[bB][01_]+|\\b0o[0-7_]+|\\b\\d[\\d_]*(\\.\\d[\\d_]*)?([eE][+-]?\\d+)?('[iIuUfFdD]\\d*)?", .number),
        call,
    ]
}
