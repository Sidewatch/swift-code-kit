//
//  AppleScriptRules.swift
//  CodeHighlighting
//
//  The regex rule table for AppleScript.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// AppleScript: `--` and `#` line comments (a `#!` shebang among them), `(* … *)` block comments that
/// nest, `"…"` strings with backslash escapes, `«…»` raw codes, the reserved words of the AppleScript
/// Language Guide (`using terms from` among them), the handler an `on` / `to` line defines, and numbers.
extension RuleTables {
    static let applescript: [(String, TokenKind)] = [
        dashComment,
        hashComment,
        nestedBlock("(*", "*)"),
        doubleQuoted,
        ("«[^»\\n]*»", .type),
        callee,
        // The handler an `on` or `to` line defines.
        ("^[ \\t]*(?:on|to)[ \\t]+[A-Za-z_]\\w*", .function),
        keywords([
            "about", "above", "after", "against", "and", "apart", "around", "as", "aside", "at", "back", "before",
            "beginning", "behind", "below", "beneath", "beside", "between", "but", "by", "considering", "contain",
            "contains", "continue", "copy", "div", "does", "eighth", "else", "end", "equal", "equals", "error", "every",
            "exit", "fifth", "first", "for", "fourth", "from", "front", "get", "given", "global", "if", "ignoring", "in",
            "instead", "into", "is", "it", "its", "last", "local", "me", "middle", "mod", "my", "ninth", "not", "of",
            "on", "onto", "or", "out", "over", "prop", "property", "put", "ref", "reference", "repeat", "return",
            "returning", "script", "second", "set", "seventh", "since", "sixth", "some", "tell", "tenth", "that",
            "the", "then", "third", "through", "thru", "timeout", "times", "to", "transaction", "try", "until", "use",
            "where", "while", "whose", "with", "without", "using", "terms",
        ]),
        constants(["true", "false", "missing value"]),
        decimal,
    ]
}
