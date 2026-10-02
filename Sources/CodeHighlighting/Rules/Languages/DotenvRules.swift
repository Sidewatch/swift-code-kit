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
/// `` `…` `` values, `$NAME` / `${NAME:-default}` expansions, and a value that is wholly a number or a
/// boolean.
extension RuleTables {
    static let dotenv: [(String, TokenKind)] = [
        ("\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        ("'[^']*'", .string),
        ("`[^`\\n]*`", .string),
        ("^[ \\t]*(?:export[ \\t]+)?[A-Za-z_][\\w.-]*(?=[ \\t]*=)", .property),
        ("^[ \\t]*export\\b", .keyword),
        ("\\$(?:\\{[^}\\n]*\\}|[A-Za-z_]\\w*)", .variable),
        ("(?<==)[ \\t]*[+-]?\\d+(?:\\.\\d+)?(?=[ \\t]*(?:#|$))", .number),
        ("(?<==)[ \\t]*(?i:true|false|yes|no|null)(?=[ \\t]*(?:#|$))", .number),
    ]
}
