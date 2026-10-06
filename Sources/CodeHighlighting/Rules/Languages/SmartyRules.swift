//
//  SmartyRules.swift
//  CodeHighlighting
//
//  The regex rule table for Smarty.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Smarty: `{* *}` comments (the language's own), tags that open with a `{` and no space after it,
/// their names and `{/closers}` — a control tag (`{if}`, `{foreach}`, `{block}`) as a keyword, any other
/// (`{assign}`, `{include}`, `{html_options}`, which the Smarty manual calls functions) as a function —
/// `$variables`, `|modifiers`, and the strings, numbers and constants inside a tag, with the HTML around
/// them. A `{ ` followed by a space is a literal brace (Smarty's auto-literal rule), so CSS and script
/// blocks stay out of it, and so is every brace in a `{literal}` block; a page's `<script>` is JavaScript.
extension RuleTables {
    static let smarty: [(String, TokenKind)] =
        [
            htmlComment,
            (insideSmartyTag + "\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
            (insideSmartyTag + "'(?:[^'\\\\\\n]|\\\\.)*'", .string),
            ("(?<==)\"[^\"{\\n]*\"", .string),
            ("(?<==)'[^'{\\n]*'", .string),
            ("</?[A-Za-z][\\w:-]*|/>|>", .keyword),
            ("\\b[A-Za-z-]+=", .property),
            (insideSmartyTag + "\\{", .keyword),
            // `{literal}` itself, which the tag scan steps over with the block it opens.
            ("\\{literal\\}", .keyword),
            (insideSmartyTag + "\\}", .keyword),
            ("\\$[A-Za-z_]\\w*", .variable),
            ("\\|@?[a-z_]\\w*", .function),
            (
                insideSmartyTag
                    + "\\b(?:as|and|or|not|mod|is|div|by|even|odd|eq|ne|neq|gt|lt|gte|ge|lte|le|from|item|key|name|to|step|in|loop|nocache)\\b",
                .keyword
            ),
            // After the words above: a tag named like one of them (`{nocache}`) is still a tag name. A
            // control tag (`{if}`, `{foreach}`) is a keyword, as every template language's control words are;
            // the other tags (`{assign}`, `{include}`, `{html_options}`) are the functions the manual calls them.
            (insideSmartyTag + "(?<=\\{)/?[a-z_]\\w*", .function),
            (
                insideSmartyTag
                    + "(?<=\\{)/?(?:if|elseif|else|foreach|foreachelse|for|forelse|while|section|sectionelse|literal|strip|nocache|block|capture|function|call|setfilter)\\b",
                .keyword
            ),
            (insideSmartyTag + "\\b(?:true|false|null|TRUE|FALSE|NULL)\\b", .number),
            (insideSmartyTag + "-?\\b(?:0[xX][0-9a-fA-F]+|\\d+(?:\\.\\d+)?)\\b", .number),
            // The page's `<script>` JavaScript: its words and strings, numbers and `//` comments.
            (insideScript + "\\b\\d+(?:\\.\\d+)?\\b", .number),
            (insideScript + "(?<![:\"'])//.*$", .comment),
        ] + pageScriptRules

    /// Inside a Smarty tag, its closing `}` included: a `{` with no space or `*` after it, up to the
    /// next brace on its line. A `{literal}…{/literal}` block is stepped over, `{literal}` included: its braces are text.
    static let insideSmartyTag = RuleScope.marker(
        steppingOver: ["\\{literal\\}[\\s\\S]*?(?=\\{/literal\\})"], regions: "\\{(?=[^{}\\s*])[^{}\\n]{0,200}\\}?",
        within: 20000)
}
