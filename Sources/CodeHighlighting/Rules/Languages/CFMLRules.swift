//
//  CFMLRules.swift
//  CodeHighlighting
//
//  The regex rule table for CFML (ColdFusion).
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// CFML: `<!--- --->` comments, which nest; CFScript's `//` and `/* */` comments where a statement
/// could start (a line's start, or after `;` `{` `}`), so a `//` in a URL in the page's text opens
/// none; strings whose quote doubles as its escape (`"Order ##12"`, `'it''s'`), which span lines
/// only inside a tag or a script; `cf` tags, and inside them and `<cfscript>` the keywords and word
/// operators in any case, calls (also inside a page's `#expression#`) and numbers; the keywords of a
/// `<script>` block and the selectors, properties and colours of a `<style>` block.
extension RuleTables {
    static let cfml: [(String, TokenKind)] =
        [
            nestedBlock("<!---", "--->"),
            htmlComment,
            ("(?:^|(?<=[;{}]))[ \\t]*//.*$", .comment),
            ("(?:^|(?<=[;{}]))[ \\t]*/\\*[\\s\\S]*?\\*/", .comment),
            ("\"(?:[^\"\\n]|\"\")*\"", .string),
            ("'(?:[^'\\n]|'')*'", .string),
            // In a tag or a script a string may span lines.
            (insideCFMLCode + "\"(?:[^\"]|\"\")*\"", .string),
            ("</?[A-Za-z][\\w:-]*|/>|>", .keyword),
            ("\\b[A-Za-z-]+=", .attribute),
            // A `#expression#` in the page; the calls inside it are painted below.
            ("#[A-Za-z_][\\w.]*(?:\\([^#\\n]*\\))?#", .variable),
            ("\\b([a-zA-Z_]\\w*)\\s*\\(", .function),
            (
                insideCFMLCode
                    + "(?i)\\b(?:abstract|break|case|catch|component|continue|default|do|else|extends|final|finally|for|function|if|implements|import|in|include|interface|new|output|package|param|private|property|public|remote|required|return|static|switch|throw|transaction|try|var|while|and|or|not|mod|eq|neq|lt|lte|gt|gte|is|isnot|contains|does|xor|eqv|imp)\\b",
                .keyword
            ),
            // A type name, but not a member of a scope (`local.query`).
            (insideCFMLCode + "(?i)(?<!\\.)\\b(?:any|array|binary|boolean|date|guid|numeric|query|string|struct|uuid|void|xml)\\b", .type),
            (insideCFMLCode + "(?i)\\b(?:true|false|null|yes|no)\\b", .number),
            // `throw(…)` is the function form of `throw`.
            ("(?i)\\bthrow(?=\\s*\\()", .function),
            // A number's digits up to any letter after them (CFML has no `0x` literal: `0x1F` is 0 and a name).
            (insideCFMLCode + "\\b\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?", .number),
        ] + pageScriptRules + pageStyleRules

    /// Inside a `<cf…>` tag or a `<cfscript>` block (which may run long): the page's text between them
    /// is HTML, where `for`, `and` or a number is prose.
    static let insideCFMLCode =
        inside(opens: ["<cf"], closes: [">"]) + inside(opens: ["<cfscript>"], closes: ["</cfscript>"], within: 20000)
}
