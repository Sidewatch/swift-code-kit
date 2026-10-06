//
//  BibTeXRules.swift
//  CodeHighlighting
//
//  The regex rule table for BibTeX.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// BibTeX: `%` comments; `@comment{…}` / `@comment(…)` entries, whose body is ignored whole (as biber
/// reads them), and the junk text between entries — an unindented line that opens no entry; `@entry{` types,
/// `key = ` fields; `{…}` values (braces nest), `"…"` values (with no escapes: a quote inside one sits
/// in braces), and the values a `#` joins; numbers.
extension RuleTables {
    static let bibtex: [(String, TokenKind)] = [
        ("%.*$", .comment),
        ("(?i)@comment\\s*(?:\\{(?:[^{}]|\\{(?:[^{}]|\\{[^{}]*\\})*\\})*\\}|\\([^()]*\\))", .comment),
        ("^(?![ \\t@}%)\\n])[^@\\n]+$", .comment),
        ("@[A-Za-z]+(?=\\s*[{(])", .keyword),
        ("^\\s*[A-Za-z_-]+(?=\\s*=)", .property),
        ("\\{(?<=[=#(][ \\t\\n]{0,20}\\{)" + bibBraced + "*\\}", .string),
        ("\"(?:[^\"{}]|\\{" + bibBraced + "*\\})*\"", .string),
        ("(?<=[{(])\\s*[\\w:.-]+(?=\\s*,)", .type),
        ("\\b\\d+(--\\d+)?\\b", .number),
    ]

    /// One piece of a braced value: a character that is no brace, or a group nesting two levels deep.
    private static let bibBraced = "(?:[^{}]|\\{(?:[^{}]|\\{[^{}]*\\})*\\})"
}
