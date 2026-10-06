//
//  JSON5Rules.swift
//  CodeHighlighting
//
//  The regex rule table for JSON5 and Hjson.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// JSON5 and Hjson: JSON plus comments, single-quoted and multi-line strings, quoted and unquoted keys as names,
/// hex and signed numbers, `Infinity` / `NaN`.
extension RuleTables {
    static let json5: [(String, TokenKind)] = [
        lineComment,
        blockComment,
        hashComment,
        ("\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"(?=\\s*:)", .function),
        ("'(?:[^'\\\\]|\\\\[\\s\\S])*'(?=\\s*:)", .function),
        ("[A-Za-z_$][\\w$]*(?=\\s*:)", .function),
        tripleSingleQuoted,
        // A value string. A quoted key is a name, not a string: neither rule matches one, and a quote that closes
        // a key (it follows the key's text) opens nothing.
        ("\"(?<![^\\s:,\\[{(]\")(?:[^\"\\\\]|\\\\[\\s\\S])*\"(?![ \\t]*:)", .string),
        ("'(?<![^\\s:,\\[{(]')(?:[^'\\\\]|\\\\[\\s\\S])*'(?![ \\t]*:)", .string),
        keywords(["true", "false", "null", "Infinity", "NaN"]),
        ("[+-]?(0[xX][0-9a-fA-F]+|\\d*\\.?\\d+([eE][+-]?\\d+)?)\\b", .number),
    ]
}
