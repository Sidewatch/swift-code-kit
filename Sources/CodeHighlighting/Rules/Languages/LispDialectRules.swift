//
//  LispDialectRules.swift
//  CodeHighlighting
//
//  The builder behind the Lisp-dialect tables: Common Lisp, Emacs Lisp, Scheme, Racket and Fennel.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The builder behind the Lisp-dialect tables. A Lisp word ends only at a delimiter — whitespace,
/// a bracket, a quote or `;` — never at `-`, `?` or `!`, so the special forms are matched between
/// delimiters rather than at `\b`, and `set!` or `let*` is one word. Strings span lines; a quoted
/// symbol (`'pending`) is painted as a string, as a literal datum.
extension RuleTables {
    /// Before a Lisp word: the start of the text, or a delimiter or reader prefix.
    static let lispWordStart = "(?<![^\\s()\\[\\]{}'`,@])"
    /// After a Lisp word: the end of the text, or a delimiter.
    static let lispWordEnd = "(?![^\\s()\\[\\]{}\"';])"

    /// Numbers with their radix and exactness prefixes (`#xFF`, `#b-101`, `#e1.5`, `#x#e10`), signs,
    /// ratios (`-3/4`), fractions with or without digits on one side (`.5`, `1.`), exponent markers
    /// (`1.5e10`, `1.0d0`), and the infinities and NaNs (`+inf.0`, `-nan.f`).
    static let lispNumber: (String, TokenKind) = (
        lispWordStart
            + "(?:(?:#[eEiI])?(?:#[xX](?:#[eEiI])?[+-]?[0-9a-fA-F]+(?:/[0-9a-fA-F]+)?|#[bB](?:#[eEiI])?[+-]?[01]+(?:/[01]+)?|#[oO](?:#[eEiI])?[+-]?[0-7]+(?:/[0-7]+)?|#\\d+[rR][+-]?[0-9a-zA-Z]+|(?:#[dD](?:#[eEiI])?)?[+-]?(?:\\d+(?:/\\d+|\\.\\d*)?|\\.\\d+)(?:[eEdDfFsSlLtT][+-]?\\d+)?)|[+-](?:inf|nan)\\.[0ft])"
            + lispWordEnd,
        .number
    )

    /// `#\a`, `#\Space`, `#\x41`, `#\(` — a character literal is a string, so `#\;` and `#\"` never
    /// open a comment or a string.
    static let lispCharacter: (String, TokenKind) = ("#\\\\(?:[A-Za-z][\\w+-]*|.)", .string)

    /// `'symbol` and `'|symbol with spaces|`: a quoted symbol, painted as a string.
    static let lispQuotedSymbol: (String, TokenKind) = (
        "(?<![\\w#\\\\])'(?:\\|(?:[^|\\\\\\n]|\\\\.)*\\||[^\\s()\\[\\]{}\"'`,;|#][^\\s()\\[\\]{}\"'`,;]*)", .string
    )

    /// The words as one alternation between Lisp delimiters. Words are escaped, so `set!`, `let*`
    /// and `->>` are safe.
    static func lispWords(_ words: [String], _ kind: TokenKind) -> (String, TokenKind) {
        let alternatives = words.sorted { $0.count > $1.count }.map { NSRegularExpression.escapedPattern(for: $0) }
        return (lispWordStart + "(?:" + alternatives.joined(separator: "|") + ")" + lispWordEnd, kind)
    }

    /// A Lisp-dialect table: `;` comments, `"…"` strings across lines, the dialect's own literal forms
    /// (`literals`, painted as strings or comments), quoted symbols, `:keywords`, the special forms, the
    /// constants and numbers.
    static func lispDialect(
        specialForms: [String], constants constantWords: [String], literals: [(String, TokenKind)] = [],
        quotedSymbols: Bool = true, keywordSymbols: String = "#?:[^\\s()\\[\\]{}\"';]+", numbers: [(String, TokenKind)] = [lispNumber]
    ) -> [(String, TokenKind)] {
        var rules: [(String, TokenKind)] = [(";.*$", .comment), doubleQuoted] + literals
        if quotedSymbols { rules.append(lispQuotedSymbol) }
        rules += [
            (lispWordStart + keywordSymbols, .type),
            lispWords(specialForms, .keyword),
            lispWords(constantWords, .number),
        ]
        return rules + numbers
    }
}
