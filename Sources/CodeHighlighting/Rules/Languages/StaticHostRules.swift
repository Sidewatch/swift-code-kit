//
//  StaticHostRules.swift
//  CodeHighlighting
//
//  The regex rule tables for a static host's `_headers` and `_redirects` files.
//
//  Created by David Sherlock on 10/10/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// `_headers` and `_redirects` (Cloudflare Pages / Workers Static Assets and Netlify): whole-line `#`
/// comments (a `#` inside a URL is part of it), URL patterns and destinations in the type colour (a
/// string would paint over their placeholders: strings resolve first), with their `*` splats and `:name`
/// placeholders, and per file — a header block's `Name: value` lines and its `! Name` detach lines,
/// or a redirect's destination, status code (`!` forces it) and `Key=value` conditions.
extension RuleTables {
    static let staticheaders: [(String, TokenKind)] = [
        // An unindented line is the URL pattern its header block applies to.
        ("^[^ \\t\\n#][^\\n]*$", .type),
        (indentedHeaderValue + "\\S[^\\n]*$", .string),
        ("^[ \\t]+[A-Za-z][\\w-]*(?=[ \\t]*:)", .property),
        // `! Name` takes a header an earlier block set off this path.
        ("^[ \\t]+![ \\t]*[A-Za-z][\\w-]*[ \\t]*$", .keyword),
        // Splats and placeholders in the pattern; a `*` in a header value stays the value's (strings resolve first).
        ("\\*|:[A-Za-z_]\\w*", .variable),
    ]

    static let staticredirects: [(String, TokenKind)] = [
        // The source is a line's first field, the destination its second.
        ("^[ \\t]*[^ \\t\\n#]\\S*", .type),
        ("(?<=[ \\t])(?:https?://|/)\\S*", .type),
        ("(?<=[ \\t])[A-Za-z][\\w-]*(?==)", .property),
        ("(?<=[ \\t])[1-5]\\d\\d(?=!?(?:[ \\t]|$))", .number),
        ("(?<=\\d\\d\\d)!(?=[ \\t]|$)", .keyword),
        ("\\*|:[A-Za-z_]\\w*", .variable),
    ]

    /// The value of each indented `Name: value` line (a name of 1-81 word characters or dashes, up to
    /// 8 blanks after the colon).
    private static let indentedHeaderValue = RuleScope.marker(
        steppingOver: [], regions: "(?m)^[ \\t]+[A-Za-z][\\w-]{0,80}:[ \\t]{0,8}" + RuleScope.region("\\S[^\\n]*"), within: 4000)
}
