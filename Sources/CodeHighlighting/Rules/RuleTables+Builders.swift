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
    /// An identifier followed by `(`, the name alone: the space and the bracket after it stay unpainted.
    static let callee: (String, TokenKind) = ("\\b[a-zA-Z_]\\w*(?=[ \\t]*\\()", .function)

    // MARK: Word lists

    /// The words as keywords.
    static func keywords(_ words: [String]) -> (String, TokenKind) { alternation(words, .keyword) }
    /// The words as type names.
    static func types(_ words: [String]) -> (String, TokenKind) { alternation(words, .type) }
    /// Literal constants (`true`, `nil`, …) are painted as numbers.
    static func constants(_ words: [String]) -> (String, TokenKind) { alternation(words, .number) }
    /// The words as function names, whether or not a `(` follows.
    static func functions(_ words: [String]) -> (String, TokenKind) { alternation(words, .function) }

    /// `words` (regex-safe) as one group matching exactly one of them, common prefixes shared
    /// (`SE(?:LECT|T)`): a flat alternation is tried word by word at every position, the tree a
    /// character at a time, which keeps a list of hundreds of words cheap.
    static func prefixTree(_ words: Set<String>) -> String {
        var branches: [Character: Set<String>] = [:]
        var endsHere = false
        for word in words {
            guard let first = word.first else {
                endsHere = true
                continue
            }
            branches[first, default: []].insert(String(word.dropFirst()))
        }
        let alternatives = branches.keys.sorted().map { String($0) + prefixTree(branches[$0]!) }
        guard !alternatives.isEmpty else { return "" }
        if alternatives.count == 1 && !endsHere { return alternatives[0] }
        return "(?:" + alternatives.joined(separator: "|") + ")" + (endsHere ? "?" : "")
    }

    /// `\b(?:…)\b` of `kind` over `words`, written as a prefix tree — `a(?:bs|ccess|fter)` rather than
    /// `abs|access|after` — so the matcher tries each first letter once instead of every word in turn. It
    /// matches exactly what `alternation(words, kind)` matches, three to four times faster on a hundred-word
    /// list. `caseInsensitive` adds `(?i)`. Words are used verbatim, so they must be regex-safe.
    static func wordTrie(_ words: [String], _ kind: TokenKind, caseInsensitive: Bool = false) -> (String, TokenKind) {
        ((caseInsensitive ? "(?i)" : "") + "\\b" + prefixTree(Set(words)) + "\\b", kind)
    }

    /// `\b(a|b|c)\b` of `kind`. Words are used verbatim, so they must be regex-safe.
    static func alternation(_ words: [String], _ kind: TokenKind) -> (String, TokenKind) {
        ("\\b(" + words.joined(separator: "|") + ")\\b", kind)
    }
}
