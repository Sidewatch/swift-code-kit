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
/// backtick (and `""`), `$variables` including `${braced name}` and `$env:NAME`, `Verb-Noun`
/// cmdlets, `-operator` words, and the language's keywords.
extension RuleTables {
    static let powershell: [(String, TokenKind)] = [
        ("<#[\\s\\S]*?#>", .comment),
        hashComment,
        ("@\"[ \\t]*\\r?\\n[\\s\\S]*?\\r?\\n\"@", .string),
        ("@'[ \\t]*\\r?\\n[\\s\\S]*?\\r?\\n'@", .string),
        ("'(?:[^']|'')*'", .string),
        ("\"(?:[^\"`]|`[\\s\\S]|\"\")*\"", .string),
        keywords([
            "if", "elseif", "else", "switch", "while", "do", "until", "for", "foreach", "in", "function", "filter",
            "workflow", "param", "begin", "process", "end", "dynamicparam", "return", "break", "continue", "throw",
            "try", "catch", "finally", "trap", "exit", "class", "enum", "using", "namespace", "data", "default", "hidden",
            "static", "from", "parallel",
        ]),
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
}
