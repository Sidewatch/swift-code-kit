//
//  CoffeeScriptRules.swift
//  CodeHighlighting
//
//  The regex rule table for CoffeeScript.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// CoffeeScript: `#` comments and `### … ###` block comments; `'…'` and `"…"` strings with backslash
/// escapes (a `\'` does not end one), the `#{ … }` interpolations of a `"…"` string, a `"""` heredoc and a
/// `///` block regex painted as code (one may itself hold a string with its own interpolation, three levels
/// deep), `'''` heredocs, `/regex/` literals where a value starts, backtick JavaScript (code, painted with these rules), `->` / `=>`
/// arrows, `@` members.
extension RuleTables {
    static let coffeescript: [(String, TokenKind)] =
        [
            ("###[\\s\\S]*?###", .comment),
            ("#(?!\\{).*$", .comment),
            ("'\'\'[\\s\\S]*?'\'\'", .string),
        ]
        + interpolatedStringPieces(
            open: "\"", close: "\"", literal: "[^\"\\\\#\\n]|\\\\[\\s\\S]|#(?!\\{)", hole: coffeeHole, holeOpen: "#\\{", holeClose: "\\}",
            afterHole: coffeeAfterHole, multiline: true, skip: coffeeSkip)
        // A heredoc's and a block regex's text holds the other forms' quotes, so each finds its own tails.
        + interpolatedStringPieces(
            open: "\"\"\"", close: "\"\"\"", literal: "[^\"\\\\#\\n]|\\\\[\\s\\S]|#(?!\\{)|\"(?!\"\")", hole: coffeeHole, holeOpen: "#\\{",
            holeClose: "\\}", afterHole: coffeeAfterHole, multiline: true, skip: [coffeeHeregex, coffeeQuoted] + coffeeSkip.dropFirst(2))
        + interpolatedStringPieces(
            open: "///", close: "///[gimsuy]*", literal: "[^/\\\\#\\n]|\\\\[\\s\\S]|#(?!\\{)|/(?!//)", hole: coffeeHole, holeOpen: "#\\{",
            holeClose: "\\}", afterHole: coffeeAfterHole, multiline: true, skip: [coffeeTriple, coffeeQuoted] + coffeeSkip.dropFirst(2))
        + [
            singleQuoted,
            // A regex literal opens where a value starts: after an operator, an opening bracket or a backtick.
            ("(?:(?<=[=(,:\\[!&|?{};`])|^)[ \\t]*/(?![/*\\s=])(?:[^/\\\\\\n\\[]|\\\\.|\\[(?:[^\\]\\\\\\n]|\\\\.)*\\])+/[gimsuy]*", .string),
            keywords([
                "if", "else", "unless", "then", "for", "while", "until", "loop", "when", "switch", "break", "continue",
                "return", "throw", "try", "catch", "finally", "new", "delete", "typeof", "instanceof", "in", "of",
                "by", "and", "or", "not", "is", "isnt", "class", "extends", "super", "this", "do", "yield", "await",
                "import", "export", "from", "as", "default", "debugger", "with", "own", "async", "function", "var",
            ]),
            constants(["true", "false", "yes", "no", "on", "off", "null", "undefined", "NaN", "Infinity"]),
            ("@[A-Za-z_$][\\w$]*", .property),
            ("(?:->|=>)", .keyword),
            ("\\b0[xX][0-9a-fA-F_]+n?\\b|\\b0[oO][0-7_]+n?\\b|\\b0[bB][01_]+n?\\b|\\b\\d[\\d_]*(\\.\\d+)?([eE][+-]?\\d+)?n?\\b", .number),
            ("\\b([A-Z][\\w$]*)\\b", .type),
            ("\\b([a-zA-Z_$][\\w$]*)\\s*\\(", .function),
        ]

    /// A `"""…"""` heredoc, holes included.
    private static let coffeeTriple = "\"\"\"(?:[^\"\\\\#]|\\\\[\\s\\S]|#(?!\\{)|\"(?!\"\")|" + coffeeHole + ")*\"\"\""

    /// A `///…///` block regex, holes included.
    private static let coffeeHeregex = "///(?:[^/\\\\#]|\\\\[\\s\\S]|#(?!\\{)|/(?!//)|" + coffeeHole + ")*///[gimsuy]*"

    /// A hole's `}`, not one closing a `{ … }` that no `#` opens inside it (a regex's `{2,3}`, an object literal).
    private static let coffeeAfterHole = "(?<=\\})(?<!(?:^|[^#])\\{[^{}\\n]{0,30}\\})"

    /// A whole `"…"` string, holes included, for the heredoc's and block regex's scans to step over.
    private static let coffeeQuoted = "\"(?!\"\")(?:[^\"\\\\#]|\\\\[\\s\\S]|#(?!\\{)|" + coffeeHole + ")*\""

    /// The heredocs, block regexes, comments and other strings a search for a `"…"` string steps over.
    private static let coffeeSkip = [
        coffeeTriple, coffeeHeregex, "###[\\s\\S]*?###", "#(?!\\{)[^\\n]*", "'''[\\s\\S]*?'''", "'(?:[^'\\\\]|\\\\[\\s\\S])*'",
    ]

    /// A `#{ … }` hole, three levels of braces deep.
    private static let coffeeHole = "#\\{(?:[^{}]|\\{(?:[^{}]|\\{(?:[^{}]|\\{[^{}]*\\})*\\})*\\})*\\}"
}
