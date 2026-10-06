//
//  SvelteRules.swift
//  CodeHighlighting
//
//  The regex rule table for Svelte's markup.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for Svelte's markup. The code in it (`{ … }`, block tags' conditions, `<script>`,
/// `<style>`) is painted by ``EmbeddedMarkupHighlighter`` with its own grammar; this table paints the rest.
/// Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let svelte: [(String, TokenKind)] = [
        htmlComment,
        // An attribute's quoted value is a string, except a number with an optional unit (`min="0"`,
        // `style:--gap="1rem"`), which is a number (the `decimal` rule) between string quotes, as VS Code's Svelte grammar paints it.
        // Quotes in the markup's text are text.
        ("(?<==)\"(?![0-9][0-9.]*(?:[a-z]{1,4}|%)?\")(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        ("(?<==)\"(?=[0-9][0-9.]*(?:[a-z]{1,4}|%)?\")", .string),
        ("\"(?<==\"[0-9][0-9.]{0,11}(?:[a-z]{1,4}|%)?\")", .string),
        ("(?<==)'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        // Block tags: `{#if`, `{:else if`, `{/each}`, `{@render`.
        ("\\{[#:@][a-z]+(?: if\\b)?|\\{/[a-z]+\\}", .keyword),
        ("\\{#each\\b[^}\\n]*?\\bas\\b|\\{#await\\b[^}\\n]*?\\bthen\\b", .keyword),  // `as`, `then` (the code between repaints)
        ("</?[A-Za-z][\\w.:-]*", .keyword),  // tags, `svelte:head` included
        ("\\b(?:on|bind|use|class|style|transition|in|out|animate|let|attach):[\\w-]+(?:\\|[\\w|]+)?", .attribute),  // directives
        decimal,
    ]
}
