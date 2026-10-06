//
//  BicepRules.swift
//  CodeHighlighting
//
//  The regex rule table for Bicep.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Bicep: `'…'` strings with `\` escapes and nested `${ … }` interpolations, `'''…'''` verbatim ones, the
/// declaration keywords (`param`, `var`, `resource`, `module`, `output`, `extension`, `assert`, …), type names
/// (one before `(` is its conversion function), `@decorators`, `#disable-next-line` linter directives. Calls
/// paint before keywords, so `if (` and `for` stay keywords.
extension RuleTables {
    static let bicep: [(String, TokenKind)] = [
        tripleSingleQuoted,
        // A `'…'` string whose `${ … }` interpolations may hold quoted strings that interpolate again, two levels
        // deep: `'a ${'b ${'c'}'}'` is one string.
        (
            "'(?:[^'\\\\$]|\\\\[\\s\\S]|\\$(?!\\{)|\\$\\{(?:[^{}'\\n]|'(?:[^'\\\\$\\n]|\\\\.|\\$(?!\\{)|\\$\\{[^{}\\n]*\\})*')*\\})*'",
            .string
        ),
        call,
        keywords([
            "targetScope", "metadata", "import", "from", "as", "using", "with", "extension", "provider", "param", "var",
            "resource", "existing", "module", "output", "type", "func", "for", "in", "if", "assert",
        ]),
        // A type name followed by `(` is the conversion function of that name (`int('42')`, `any(1)`).
        ("\\b(?:string|int|bool|object|array|any|resourceInput|resourceOutput)\\b(?![ \\t]*\\()", .type),
        constants(["true", "false", "null"]),
        decimal,
        ("@[A-Za-z_][\\w.]*", .attribute),
        ("^[ \\t]*#disable-(?:next-line|diagnostics)\\b.*$", .keyword),
    ]
}
