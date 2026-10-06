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
/// doubled `""` is a quote; a `fmt"…"` or `&"…"` string's `{expr}` holes stay code), one-character `'…'` literals (the `'` of `1'i32` opens nothing), the
/// keywords, types, and the routine a `proc`-style declaration names (a quoted operator too).
extension RuleTables {
    static let nim: [(String, TokenKind)] =
        [
            ("##\\[[\\s\\S]*?\\]##", .comment),
            (
                "#\\[(?:[^\\]#]|#(?!\\[)|\\](?!#)|#\\[(?:[^\\]#]|#(?!\\[)|\\](?!#))*\\]#)*\\]#",
                .comment
            ),
            hashComment,
            ("\\b[A-Za-z_]\\w*\"\"\"[\\s\\S]*?\"\"\"", .string),
            ("\\b(?!fmt\")[A-Za-z_]\\w*\"(?:[^\"\\n]|\"\")*\"", .string),
            tripleDoubleQuoted,
            // A quote right after a `}` closes a `fmt"…"` string.
            ("\"(?<!\\}\")(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
            ("(?<![\\w'])'(?:[^'\\\\\\n]|\\\\(?:x[0-9a-fA-F]{2}|u[0-9a-fA-F]{4}|[^\\n]\\w*))'", .string),
        ]
        // A `fmt"…"` or `&"…"` string's `{expr}` and `{expr:spec}` holes stay code; `{{` and `}}` are braces of its text.
        + interpolatedStringPieces(
            open: "(?:\\bfmt|&)\"(?!\"\")", close: "\"", literal: "[^\"\\\\{}\\n]|\\\\.|\"\"|\\{\\{|\\}\\}",
            hole: "\\{(?!\\{)(?:[^{}\"\\n]|\"[^\"\\n]*\")*\\}", holeOpen: "\\{(?!\\{)", holeClose: "\\}",
            skip: [
                "##\\[[\\s\\S]*?\\]##", "#\\[[\\s\\S]*?\\]#", "#[^\\n]*", "\\b[A-Za-z_]\\w*\"\"\"[\\s\\S]*?\"\"\"",
                "\"\"\"[\\s\\S]*?\"\"\"",
                "\\b(?!fmt\")[A-Za-z_]\\w*\"(?:[^\"\\n]|\"\")*\"", "\"(?:[^\"\\\\\\n]|\\\\.)*\"",
            ])
        + [
            // A call's name is painted before the words, so `not (`, `type(`, `const (` and `do (` stay keywords.
            call,
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
            // The routine a declaration names, a quoted operator (`` `+` ``, `` `=sink` ``) included; its keyword
            // is repainted after it.
            ("\\b(?:proc|func|method|iterator|template|macro|converter)[ \\t]+(?:`[^`\\n]+`|[A-Za-z_]\\w*)", .function),
            ("\\b(?:proc|func|method|iterator|template|macro|converter)\\b", .keyword),
        ]
}
