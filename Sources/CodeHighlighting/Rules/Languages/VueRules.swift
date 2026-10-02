//
//  VueRules.swift
//  CodeHighlighting
//
//  The regex rule table for Vue / Svelte.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for Vue / Svelte.
/// Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let vue: [(String, TokenKind)] = [
        // Single-file components: tags, interpolation, and framework directives /
        // blocks. The embedded <script>/<style> aren't separately parsed here.
        htmlComment,
        // A directive's value (`v-if="count > 5"`, `:items="visible"`, `@click="go"`) is a JavaScript
        // expression, not a string — neither its opening quote nor its closing one starts a string; the two
        // quotes are painted alone, and quotes inside it are strings of their own.
        ("(?<=\\s(?:v-|[:@#])[\\w.:\\[\\]-]{0,60}=(?:\"[^\"\\n]{0,400})?)\"", .string),
        (
            "(?<!\\s(?:v-[\\w.:\\[\\]-]|[:@#])[\\w.:\\[\\]-]{0,60}=(?:\"[^\"\\n]{0,400})?)"
                + "\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"",
            .string
        ),
        // A `'…'` ends on its line: an apostrophe in the markup's text cannot pair with one lines away.
        ("'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        ("\\{[#/:][^}]*\\}", .keyword),  // {#if}/{/each}/{:else} (Svelte)
        ("\\{\\{[^}]*\\}\\}", .property),  // {{ mustache }} (Vue)
        ("</?[A-Za-z][\\w.-]*", .keyword),  // tags
        ("v-[a-z-]+|@[a-z:.-]+|:[a-z-]+|(?:on|bind|use|class):[a-z]+", .attribute),  // directives
        decimal,
    ]
}
