//
//  RuleTables+Builders.swift
//  CodeHighlighting
//
//  The rules every table is built from.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The rules every table is built from. A table is an array of (pattern, kind): the named
/// constants cover the idioms most languages share, the word-list builders turn a list of
/// words into one `\b(a|b|c)\b` alternation of the given kind.
extension RuleTables {

    // MARK: Comments

    /// `// …` to the end of the line.
    static let lineComment: (String, TokenKind) = ("//.*$", .comment)
    /// `/* … */`, across lines.
    static let blockComment: (String, TokenKind) = ("/\\*[\\s\\S]*?\\*/", .comment)
    /// `# …` to the end of the line.
    static let hashComment: (String, TokenKind) = ("#.*$", .comment)
    /// `-- …` to the end of the line.
    static let dashComment: (String, TokenKind) = ("--.*$", .comment)
    /// `<!-- … -->`, across lines.
    static let htmlComment: (String, TokenKind) = ("<!--[\\s\\S]*?-->", .comment)

    // MARK: Strings

    /// `"…"` with backslash escapes.
    static let doubleQuoted: (String, TokenKind) = ("\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string)
    /// `'…'` with backslash escapes.
    static let singleQuoted: (String, TokenKind) = ("'(?:[^'\\\\]|\\\\[\\s\\S])*'", .string)
    /// `` `…` `` with backslash escapes.
    static let backQuoted: (String, TokenKind) = ("`(?:[^`\\\\]|\\\\[\\s\\S])*`", .string)
    /// `"…"` with no escapes (data formats).
    static let doubleQuotedPlain: (String, TokenKind) = ("\"[^\"]*\"", .string)
    /// `'…'` with no escapes.
    static let singleQuotedPlain: (String, TokenKind) = ("'[^']*'", .string)
    /// `"""…"""`, across lines, no escapes.
    static let tripleDoubleQuoted: (String, TokenKind) = ("\"\"\"[\\s\\S]*?\"\"\"", .string)
    /// `'''…'''`, across lines, no escapes.
    static let tripleSingleQuoted: (String, TokenKind) = ("'''[\\s\\S]*?'''", .string)

    // MARK: Numbers and calls

    /// Numbers the way most languages spell them: decimals with `_` digit separators, a fraction and an
    /// exponent, `0x` / `0o` / `0b` prefixed forms, and a short type suffix — `1_000`, `0xFF_FF`, `0o755`,
    /// `0b1010`, `1.5e-3`, `255uy`, `12L`, `3.0f32`.
    static let decimal: (String, TokenKind) = (
        "\\b(?:0[xX][0-9a-fA-F][0-9a-fA-F_]*|0[oO][0-7][0-7_]*|0[bB][01][01_]*|\\d[\\d_]*(?:\\.\\d[\\d_]*)?(?:[eE][+-]?\\d[\\d_]*)?)(?:[a-zA-Z]{1,3}\\d{0,3})?\\b",
        .number
    )
    /// The same numbers; kept as its own name for the tables that ask for hex explicitly.
    static let decimalOrHex: (String, TokenKind) = decimal
    /// An identifier followed by `(`: the callee is captured as group 1.
    static let call: (String, TokenKind) = ("\\b([a-zA-Z_]\\w*)\\s*\\(", .function)

    // MARK: Word lists

    /// The words as keywords.
    static func keywords(_ words: [String]) -> (String, TokenKind) { alternation(words, .keyword) }
    /// The words as type names.
    static func types(_ words: [String]) -> (String, TokenKind) { alternation(words, .type) }
    /// Literal constants (`true`, `nil`, …) are painted as numbers.
    static func constants(_ words: [String]) -> (String, TokenKind) { alternation(words, .number) }
    /// The words as function names, whether or not a `(` follows.
    static func functions(_ words: [String]) -> (String, TokenKind) { alternation(words, .function) }

    /// `\b(a|b|c)\b` of `kind`. Words are used verbatim, so they must be regex-safe.
    static func alternation(_ words: [String], _ kind: TokenKind) -> (String, TokenKind) {
        ("\\b(" + words.joined(separator: "|") + ")\\b", kind)
    }
}
