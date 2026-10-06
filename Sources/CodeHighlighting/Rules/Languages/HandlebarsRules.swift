//
//  HandlebarsRules.swift
//  CodeHighlighting
//
//  The regex rule table for Handlebars.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Handlebars: `{{!-- --}}` and the short `{{! }}` comments, the `{{ }}` / `{{{ }}}` delimiters with
/// their `~` trims, block helpers (`#each` … `/each`), `else` / `as` / `this`, `@data` variables, and
/// literals inside a mustache, with the HTML around them and a `<script>` block's keywords and strings.
extension RuleTables {
    static let handlebars: [(String, TokenKind)] =
        [
            ("\\{\\{~?!--[\\s\\S]*?--~?\\}\\}", .comment),
            ("\\{\\{~?!(?!--)[\\s\\S]*?\\}\\}", .comment),
            htmlComment,
            // A literal ends on its line: one that holds braces (`"with }} braces"`) cannot then send a
            // quote it contains off as the start of a string that runs on.
            (insideTemplateTag + "\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
            (insideTemplateTag + "'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        ] + templateAttributeStrings + [
            ("</?[A-Za-z][\\w:-]*|/>|>", .keyword),
            ("\\b[A-Za-z-]+=", .property),
            ("\\{\\{\\{?~?[#/^>&]?|~?\\}\\}\\}?", .keyword),
            ("(?<=\\{\\{~?[#/^])[\\w-]+", .keyword),
            templateTagKeywords(["else", "as", "this"]),
            (insideTemplateTag + "@[\\w.]+", .variable),
            templateTagConstants(["true", "false", "null", "undefined"]),
            (insideTemplateTag + "-?\\b\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?\\b", .number),
        ] + pageScriptRules
}
