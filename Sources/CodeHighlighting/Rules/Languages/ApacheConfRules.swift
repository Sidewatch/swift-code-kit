//
//  ApacheConfRules.swift
//  CodeHighlighting
//
//  The regex rule table for Apache httpd configuration.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Apache httpd configuration: a `#` comment is a whole line (`IndexIgnore *#` keeps its hash, and a `;`
/// opens nothing), `"…"` strings, `<Section args>` tags with their arguments as strings, directives,
/// `%{VAR}` / `${VAR}` / `$1` references, `on`/`off` switches, and numbers.
extension RuleTables {
    static let apacheconf: [(String, TokenKind)] = [
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        // The match starts on the space after the tag name: a leading lookbehind would be tried at every
        // character of the file, the space only where one stands.
        ("[ \\t](?<=<[A-Za-z][A-Za-z0-9]{0,30}[ \\t])(?!\")[^<>\\n\"]+(?=>)", .string),
        ("^[ \\t]*</?[A-Za-z]\\w*|>[ \\t]*$", .keyword),
        ("^[ \\t]*[A-Za-z][\\w-]*", .function),
        ("%\\{[^}\\n]*\\}|\\$\\{[^}\\n]*\\}|\\$\\d", .variable),
        ("(?i)(?<![\\w-])(on|off|none|all)(?![\\w-])", .number),
        ("(?<![\\w.-])\\d+(?:\\.\\d+)*(?![\\w-])", .number),
    ]
}
