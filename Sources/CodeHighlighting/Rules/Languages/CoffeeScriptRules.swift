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
/// escapes (a `\'` does not end one), a `"…"` string's `#{ … }` interpolation painted as code (it may itself
/// hold a string with its own interpolation, three levels deep), `'''` and `"""` heredocs and `///` block
/// regexes (whole, holes included),
/// `/regex/` literals where a value starts, backtick JavaScript (code, painted with these rules), `->` / `=>`
/// arrows, `@` members.
extension RuleTables {
    static let coffeescript: [(String, TokenKind)] =
        [
            ("###[\\s\\S]*?###", .comment),
            ("#(?!\\{).*$", .comment),
            ("'\'\'[\\s\\S]*?'\'\'", .string),
            // A heredoc or block regex paints whole, holes included; only a `"…"` string is split around its holes.
            (coffeeTriple, .string),
            (coffeeHeregex, .string),
        ]
        + interpolatedStringPieces(
            whole: coffeeStrings, skip: coffeeSkip, open: "\"", close: "\"",
            literal: "[^\"\\\\#]|\\\\[\\s\\S]|#(?!\\{)", holeClose: "\\}", nested: coffeeNotHole)
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

    /// Every interpolated string: `"""…"""`, `///…///`, then `"…"`: where a `"…"` string's tail may start.
    private static let coffeeStrings = [coffeeTriple, coffeeHeregex, "\"(?:[^\"\\\\#]|\\\\[\\s\\S]|#(?!\\{)|" + coffeeHole + ")*\""].joined(
        separator: "|")

    /// A `"""…"""` heredoc, holes included.
    private static let coffeeTriple = "\"\"\"(?:[^\"\\\\#]|\\\\[\\s\\S]|#(?!\\{)|\"(?!\"\")|" + coffeeHole + ")*\"\"\""

    /// A `///…///` block regex, holes included.
    private static let coffeeHeregex = "///(?:[^/\\\\#]|\\\\[\\s\\S]|#(?!\\{)|/(?!//)|" + coffeeHole + ")*///[gimsuy]*"

    /// A `{ … }` that no `#` opens (a regex's `{2,3}`, an object literal): its brace ends no hole.
    private static let coffeeNotHole = "(?:^|[^#])\\{[^{}\\n]{0,30}\\}"

    /// The comments and other strings a search for an interpolated string steps over.
    private static let coffeeSkip = [
        "###[\\s\\S]*?###", "#(?!\\{)[^\\n]*", "'''[\\s\\S]*?'''", "'(?:[^'\\\\]|\\\\[\\s\\S])*'",
    ]

    /// A `#{ … }` hole, three levels of braces deep.
    private static let coffeeHole = "#\\{(?:[^{}]|\\{(?:[^{}]|\\{(?:[^{}]|\\{[^{}]*\\})*\\})*\\})*\\}"
}
