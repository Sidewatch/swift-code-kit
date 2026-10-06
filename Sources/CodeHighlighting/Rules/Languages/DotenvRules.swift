//
//  DotenvRules.swift
//  CodeHighlighting
//
//  The regex rule table for dotenv files.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// dotenv: `#` comments at a line's start or after whitespace (`value#frag` keeps its hash), the
/// `export` prefix, `KEY` names, `"…"` (escapes, may span lines), `'…'` (literal, may span lines) and
/// `` `…` `` values, `$NAME` / `${NAME:-default}` expansions (`${` and `}` in the keyword colour, a quote
/// in the default text opens no string), and a value that is wholly a number or a boolean.
extension RuleTables {
    static let dotenv: [(String, TokenKind)] =
        [
            ("'(?<!\\$\\{[^}\\n]{0,80}')[^']*'", .string),
            ("`[^`\\n]*`", .string),
        ]
        // A `"…"` value is painted around its expansions' `${` and `}`, which keep the keyword colour; the name
        // and default between them stay the value's text, as VS Code reads them. A quote inside a
        // `${NAME:-default}` expansion is part of the default text, not a string.
        + interpolatedStringPieces(
            open: "\"(?<!\\$\\{[^}\\n]{0,80}\")", close: "\"",
            literal: "[^\"\\\\$}\\n]|\\\\[\\s\\S]|\\$(?!\\{)|\\}(?<!\\$\\{[^{}\"\\n]{0,80}\\})",
            hole: "\\$\\{|\\}(?<=\\$\\{[^{}\"\\n]{0,80}\\})", holeOpen: "\\$\\{|\\}", holeClose: "[{}]", multiline: true,
            skip: ["#(?<![^ \\t\\n]#)[^\\n]*", "'[^']*'", "`[^`\\n]*`"])
        + [
            ("^[ \\t]*(?:export[ \\t]+)?[A-Za-z_][\\w.-]*(?=[ \\t]*=)", .property),
            ("^[ \\t]*export\\b", .keyword),
            // An expansion's `${` and `}` are punctuation in the keyword colour, the name and default inside are
            // the variable; one level of nesting (`${A:-${B}}`) closes at the outer brace.
            ("\\$\\{(?:[^{}\\n]|\\$\\{[^{}\\n]*\\})*\\}", .keyword),
            ("\\{(?<=\\$\\{)[^{}\\n]+(?:\\$\\{[^{}\\n]*\\}[^{}\\n]*)*", .variable),
            ("\\$\\{", .keyword),
            ("\\$[A-Za-z_]\\w*", .variable),
            ("(?<==)[ \\t]*[+-]?\\d+(?:\\.\\d+)?(?=[ \\t]*(?:#|$))", .number),
            ("(?<==)[ \\t]*(?i:true|false|yes|no|null)(?=[ \\t]*(?:#|$))", .number),
        ]
}
