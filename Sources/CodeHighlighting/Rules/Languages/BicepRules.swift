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

/// Bicep: `'…'` strings with `\` escapes and `'''…'''` verbatim ones, the declaration keywords
/// (`param`, `var`, `resource`, `module`, `output`, `extension`, `assert`, …), `@decorators`,
/// `#disable-next-line` linter directives. Calls paint before keywords, so `if (` and `for` stay keywords.
extension RuleTables {
    static let bicep: [(String, TokenKind)] = [
        tripleSingleQuoted,
        singleQuoted,
        call,
        keywords([
            "targetScope", "metadata", "import", "from", "as", "using", "with", "extension", "provider", "param", "var",
            "resource", "existing", "module", "output", "type", "func", "for", "in", "if", "assert",
        ]),
        types(["string", "int", "bool", "object", "array", "any", "resourceInput", "resourceOutput"]),
        constants(["true", "false", "null"]),
        decimal,
        ("@[A-Za-z_][\\w.]*", .attribute),
        ("^[ \\t]*#disable-(?:next-line|diagnostics)\\b.*$", .keyword),
    ]
}
