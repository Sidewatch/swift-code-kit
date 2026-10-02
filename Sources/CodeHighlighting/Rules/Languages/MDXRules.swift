//
//  MDXRules.swift
//  CodeHighlighting
//
//  The regex rule table for MDX.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// MDX: Markdown plus `{/* … */}` comments (the language table adds them), `import` / `export` statements
/// (their JavaScript keywords, up to the next blank line), JSX tags with their attribute names and quoted
/// attribute values, and the frontmatter's keys. Prose quotes open nothing — an apostrophe (`author's`) or a
/// `"quoted"` word is text, so a string is only an attribute value or an import's source.
extension RuleTables {
    static let mdx: [(String, TokenKind)] =
        [
            ("^[\\w-]+:(?=\\s)", .property),
            (esmStatement + esmKeywords.0, .keyword),
            ("</?[A-Za-z][\\w.:-]*|</?>|/?>", .keyword),
            ("(?<=\\s)[A-Za-z_][\\w-]*(?==)", .function),
            ("(?<==)\"[^\"\\n]*\"|(?<==)'[^'\\n]*'", .string),
            ("(?<=\\bfrom\\s)(?:\"[^\"\\n]*\"|'[^'\\n]*')", .string),
            ("(?<=^import\\s)(?:\"[^\"\\n]*\"|'[^'\\n]*')", .string),
        ] + markdown

    /// The scope of an `import` / `export` statement: from the keyword at a line's start to the next blank
    /// line, so the body of an exported function is code too.
    private static let esmStatement = RuleScope.marker(opens: ["(?m)^(?:import|export)\\b"], closes: ["\\n[ \\t]*\\n"], within: 4000)

    /// The JavaScript keywords an ESM statement holds; prose outside one keeps words like `return` plain.
    private static let esmKeywords = wordTrie(
        [
            "as", "async", "await", "break", "case", "catch", "class", "const", "continue", "default", "do", "else",
            "export", "extends", "finally", "for", "from", "function", "get", "if", "import", "in", "instanceof", "let",
            "new", "of", "return", "set", "static", "switch", "this", "throw", "try", "typeof", "var", "void", "while",
            "yield",
        ],
        .keyword
    )
}
