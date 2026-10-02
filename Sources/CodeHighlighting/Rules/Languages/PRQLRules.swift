//
//  PRQLRules.swift
//  CodeHighlighting
//
//  The regex rule table for PRQL.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// PRQL: `#` comments, `"…"` and `'…'` strings with escapes and their `"""…"""` / `'''…'''` forms,
/// each with an optional `r`, `f` or `s` prefix, the keywords and pipeline transforms, `<type>`
/// annotations, `@dates`, and numbers with their duration units (`3months`, `100milliseconds`).
/// Without it PRQL fell to the SQL family, which knows neither `#` comments nor `"…"` strings.
extension RuleTables {
    static let prql: [(String, TokenKind)] = [
        hashComment,
        ("(?:\\b[rfs])?\"\"\"[\\s\\S]*?\"\"\"", .string),
        ("(?:\\b[rfs])?'''[\\s\\S]*?'''", .string),
        ("(?:\\b[rfs])?\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("(?:\\b[rfs])?'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        call,
        keywords([
            "let", "into", "case", "prql", "type", "module", "internal", "func", "in", "from", "select", "derive", "filter",
            "take", "sort", "join", "group", "aggregate", "window", "append", "loop", "from_text", "side", "rows",
            "range", "expanding", "rolling",
        ]),
        ("(?<=<)[ \\t]*[a-z]+(?:[ \\t]*\\|\\|[ \\t]*[a-z]+)*[ \\t]*(?=>)", .type),
        constants(["true", "false", "null"]),
        decimal,
        ("\\b\\d+(?:years|months|weeks|days|hours|minutes|seconds|milliseconds|microseconds)\\b", .number),
        ("@\\d[\\d:T.+-]*Z?", .number),
    ]
}
