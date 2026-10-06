//
//  PowerShellRules.swift
//  CodeHighlighting
//
//  The regex rule table for PowerShell.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// PowerShell: `#` and `<# … #>` comments, here-strings `@"…"@` and `@'…'@` (the closing mark opens
/// a line), `'…'` strings where `''` is a quote and nothing is escaped, `"…"` strings escaped by the
/// backtick (and `""`) whose `$( … )` subexpressions paint as code (a `@"…"@` here-string's too), `$variables` including `${braced name}`
/// and `$env:NAME`, a `global:` / `script:` scope prefix, `Verb-Noun` cmdlets, `-operator` words, and the
/// language's keywords in any case.
extension RuleTables {
    static let powershell: [(String, TokenKind)] =
        [
            ("<#[\\s\\S]*?#>", .comment),
            hashComment,
            ("@'[ \\t]*\\r?\\n[\\s\\S]*?\\r?\\n'@", .string),
            ("'(?:[^']|'')*'", .string),
        ]
        + interpolatedStringPieces(
            open: "\"", close: "\"", literal: "[^\"`$\\n]|`[\\s\\S]|\"\"|\\$(?!\\()", hole: powershellHole, holeOpen: "\\$\\(",
            holeClose: "\\)",
            afterHole: powershellAfterHole, multiline: true, skip: powershellSkip)
        // A here-string's text holds quotes; only a `"@` that opens a line closes it. Its tails need their own
        // rule: a `"…"` string's would end at the first quote.
        + interpolatedStringPieces(
            open: "@\"[ \\t]{0,40}\\r?\\n", close: "(?<=\\n)\"@", literal: "[^\"`$\\n]|`[\\s\\S]|\\$(?!\\()|\"(?<=[^\\n]\")|\"(?!@)",
            hole: powershellHole, holeOpen: "\\$\\(", holeClose: "\\)", afterHole: powershellAfterHole, multiline: true,
            skip: ["<#[\\s\\S]*?#>", "#[^\\n]*", "@'[ \\t]*\\r?\\n[\\s\\S]*?\\r?\\n'@", "'(?:[^']|'')*'", "\"(?:[^\"`]|`[\\s\\S]|\"\")*\""])
        + [
            wordTrie(
                [
                    "if", "elseif", "else", "switch", "while", "do", "until", "for", "foreach", "in", "function", "filter",
                    "workflow", "param", "begin", "process", "end", "dynamicparam", "return", "break", "continue", "throw",
                    "try", "catch", "finally", "trap", "exit", "class", "enum", "using", "namespace", "data", "default",
                    "hidden", "static", "from", "parallel",
                ], .keyword, caseInsensitive: true),
            ("(?i)(?<![$\\w])(?:global|script|local|private)(?=:\\w)", .keyword),
            (
                "(?i)(?<=\\s)-(?:eq|ne|gt|ge|lt|le|like|notlike|match|notmatch|contains|notcontains|in|notin|replace|split|join|is|isnot|as|and|or|not|xor|band|bor|bxor|shl|shr|f|ceq|cne|cgt|clike|cmatch|ieq|ilike|imatch)\\b",
                .keyword
            ),
            ("\\$\\{[^}]*\\}|\\$(?:global:|script:|local:|env:|private:)?\\w+|\\$[$?^_]", .type),
            ("\\b[A-Z][a-z]+-[A-Z][A-Za-z]+\\b", .function),
            ("\\[[A-Za-z][\\w.]*(?:\\[\\])?\\]", .type),
            ("\\$(?:true|false|null)\\b", .number),
            ("\\b0[xX][0-9a-fA-F]+\\b|\\b\\d+(\\.\\d+)?(?:[kKmMgGtTpP][bB])?\\b", .number),
        ]

    /// The comments and other strings a search for a `"…"` string steps over.
    private static let powershellSkip = [
        "<#[\\s\\S]*?#>", "#[^\\n]*", "@\"[ \\t]*\\r?\\n[\\s\\S]*?\\r?\\n\"@", "@'[ \\t]*\\r?\\n[\\s\\S]*?\\r?\\n'@",
        "'(?:[^']|'')*'",
    ]

    /// A subexpression's `)`, not one that closes a call inside it (`$($a.Where({ $_ })[0])`).
    private static let powershellAfterHole = "(?<=\\))(?<!\\w\\([^()\\n]{0,30}\\))"

    /// A `$( … )` subexpression: brackets two deep, strings inside it.
    private static let powershellHole = "\\$\\((?:[^()\"]|\"(?:[^\"`]|`.)*\"|\\((?:[^()]|\\([^()]*\\))*\\))*\\)"
}
