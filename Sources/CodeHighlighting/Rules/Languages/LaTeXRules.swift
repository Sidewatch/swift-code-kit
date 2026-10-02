//
//  LaTeXRules.swift
//  CodeHighlighting
//
//  The regex rule table for LaTeX.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// LaTeX: `%` comments (the language table's `exactLineComment`), where an escaped `\%` is a percent sign;
/// `\commands` and `\@internal` names; `{…}` groups; `$…$` math, which an escaped `\$` does not open or close
/// (`$$` pairs up as an empty span, leaving display math code); numbers and dimensions (`2.5`, `1cm`, `3pt`).
extension RuleTables {
    static let latex: [(String, TokenKind)] = [
        ("\\\\[A-Za-z@]+", .keyword),
        ("\\{[^{}]*\\}", .type),
        ("(?<![\\w\\\\])\\d+(?:\\.\\d+)?(?:pt|em|ex|cm|mm|in|bp|pc|sp|mu|dd|cc)?(?![A-Za-z])", .number),
        ("(?<!\\\\)\\$(?:[^$\\\\]|\\\\[\\s\\S])*\\$", .string),
    ]
}
