//
//  SCSSRules.swift
//  CodeHighlighting
//
//  The regex rule table for SCSS / Sass / Less.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for SCSS / Sass / Less.
/// Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let scss: [(String, TokenKind)] = [
        // CSS supersets whose variables (`$var` in SCSS/Sass, `@var` in Less)
        // the CSS tree-sitter grammar turns into ERROR nodes that swallow
        // neighbouring declarations (indented Sass barely parses at all), so
        // these route here instead of reusing that grammar — see the note by
        // the grammar table in `TreeSitterHighlighter`. Later rules overwrite
        // earlier ones: property names paint before the variable rules so
        // `$primary:` / `@primary:` keep the variable colour, and the known
        // at-keywords repaint over the generic Less `@var` rule.
        lineComment,
        blockComment,
        // Strings end on their line (a backslash continues them) and may carry `#{…}` interpolation,
        // whose own quotes (`"#{f("a")}"`) must not close the string early.
        interpolatedString(quote: "\""),
        interpolatedString(quote: "'"),
        ("\\b\\d+(\\.\\d+)?(px|em|rem|%|vh|vw|s|ms|fr|deg)?\\b", .number),
        ("[.#%][a-zA-Z_-][\\w-]*", .function),  // selectors (+ SCSS %placeholders)
        ("#[0-9a-fA-F]{3,8}\\b", .number),  // hex colours, after `#fff`-shaped selectors
        ("[a-z-]+(?=\\s*:)", .type),  // property names
        ("@[a-zA-Z_-][\\w-]*", .property),  // Less @variables
        (
            "@(media|import|charset|namespace|supports|keyframes|font-face|page|include|mixin|function|return|extend|use|forward|if|else|each|for|while|content|at-root|debug|warn|error|plugin)\\b",
            .keyword
        ),
        ("\\$[a-zA-Z_-][\\w-]*", .property),  // SCSS/Sass $variables
    ]

    /// A `quote`-delimited Sass string: single-line, escapes, and `#{…}` holes that may hold quoted strings.
    private static func interpolatedString(quote: String) -> (String, TokenKind) {
        let plain = "[^\(quote)\\\\\\n#]|\\\\[\\s\\S]|#(?!\\{)"
        let inner = "\"(?:[^\"\\\\\\n]|\\\\.)*\"|'(?:[^'\\\\\\n]|\\\\.)*'"
        let hole = "#\\{(?:[^{}\"'\\n]|\(inner))*\\}"
        return ("\(quote)(?:\(plain)|\(hole))*\(quote)", .string)
    }
}
