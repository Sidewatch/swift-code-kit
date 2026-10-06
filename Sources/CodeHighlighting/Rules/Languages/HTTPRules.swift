//
//  HTTPRules.swift
//  CodeHighlighting
//
//  The regex rule table for `.http` request files.
//
//  Created by David Sherlock on 10/3/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// `.http` request files (the JetBrains HTTP Client / VS Code REST Client format): `###` block
/// separators and `#` / `//` comments, the request method and an optional `HTTP/1.1`, the address,
/// `{{variable}}` placeholders and `@name = value` definitions, header names and values, and a JSON
/// body's strings, numbers and literals. The HTTP client tool and every editor surface share it.
extension RuleTables {
    static let http: [(String, TokenKind)] = [
        ("^[ \\t]*(?:#|//).*$", .comment),
        ("(?i)^(?:GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS|TRACE|CONNECT)(?=[ \\t])", .keyword),
        ("\\bHTTP/\\d(?:\\.\\d)?\\b", .keyword),
        ("\\{\\{[^}\\n]*\\}\\}", .type),
        ("^@[\\w.-]+", .type),
        ("(?i)\\bhttps?://[^\\s{]+", .string),
        ("^[A-Za-z][\\w-]*(?=[ \\t]*:)", .property),
        // A header's value: everything after `Name:` on a header-shaped line. One forward scan finds the
        // values (a scope region), where a look back to the line's start would run at every character.
        (headerValue + "\\S[^\\n]*$", .string),
        // A JSON body's strings (keys included: strings resolve before every other rule), literals and
        // numbers.
        doubleQuoted,
        constants(["true", "false", "null"]),
        decimal,
    ]

    /// The value of each `Name: value` line (a name of 1-81 word characters or dashes at the line's start,
    /// up to 8 blanks after the colon).
    private static let headerValue = RuleScope.marker(
        steppingOver: [], regions: "(?m)^[A-Za-z][\\w-]{0,80}:[ \\t]{0,8}" + RuleScope.region("\\S[^\\n]*"), within: 4000)
}
