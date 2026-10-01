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
/// escapes (a `\'` does not end one), `#{ … }` interpolation that may itself hold a string, `'''` and
/// `"""` heredocs, `///` block regexes, backtick JavaScript, `->` / `=>` arrows, `@` members.
extension RuleTables {
    static let coffeescript: [(String, TokenKind)] = [
        ("###[\\s\\S]*?###", .comment),
        hashComment,
        ("\"\"\"[\\s\\S]*?\"\"\"", .string),
        ("'''[\\s\\S]*?'''", .string),
        ("///[\\s\\S]*?///[gimsuy]*", .string),
        ("\"(?:[^\"\\\\#]|\\\\[\\s\\S]|#(?!\\{)|#\\{(?:[^{}]|\\{[^{}]*\\})*\\})*\"", .string),
        singleQuoted,
        backQuoted,
        keywords([
            "if", "else", "unless", "then", "for", "while", "until", "loop", "when", "switch", "break", "continue",
            "return", "throw", "try", "catch", "finally", "new", "delete", "typeof", "instanceof", "in", "of",
            "by", "and", "or", "not", "is", "isnt", "class", "extends", "super", "this", "do", "yield", "await",
            "import", "export", "from", "as", "default", "debugger", "with", "own", "async",
        ]),
        constants(["true", "false", "yes", "no", "on", "off", "null", "undefined", "NaN", "Infinity"]),
        ("@[A-Za-z_$][\\w$]*", .property),
        ("(?:->|=>)", .keyword),
        ("\\b0[xX][0-9a-fA-F_]+n?\\b|\\b0[oO][0-7_]+n?\\b|\\b0[bB][01_]+n?\\b|\\b\\d[\\d_]*(\\.\\d+)?([eE][+-]?\\d+)?n?\\b", .number),
        ("\\b([A-Z][\\w$]*)\\b", .type),
        ("\\b([a-zA-Z_$][\\w$]*)\\s*\\(", .function),
    ]
}
