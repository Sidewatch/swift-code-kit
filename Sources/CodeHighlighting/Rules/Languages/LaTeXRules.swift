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
/// `\commands` (with a starred form's `*`), `\@internal` names, control symbols (`\,`) and the `\\` line
/// break; `{…}` groups; the math delimiters `$`, `$$`, `\(`, `\)`, `\[` and `\]` as strings, with the math
/// between them painted as code (its commands and numbers), as VS Code paints it; numbers and dimensions
/// (`2.5`, `1cm`, `3pt`). A backslash escaped by another (`\\c`) starts no command.
extension RuleTables {
    static let latex: [(String, TokenKind)] = [
        ("(?<!(?<!\\\\)\\\\)\\\\(?:[A-Za-z@]+\\*?|[^A-Za-z@\\s()\\[\\]$])", .keyword),
        ("\\{[^{}]*\\}", .type),
        ("(?<![A-Za-z\\d.])(?<!(?<!\\\\)\\\\)\\d+(?:\\.\\d+)?(?:pt|em|ex|cm|mm|in|bp|pc|sp|mu|dd|cc)?", .number),
        ("(?<!(?<!\\\\)\\\\)(?:\\$\\$?|\\\\[()\\[\\]])", .string),
    ]
}
