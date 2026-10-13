//
//  HighlighterCache.swift
//  CodeHighlighting
//
//  One highlighter per language (and per custom definition), built once and shared, never
//  blocking on a grammar compile.
//
//  Created by David Sherlock on 7/9/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation
import CodeLanguage

/// One highlighter per language, shared by every surface that paints code. Highlighters are
/// stateless and read their colours live through `colors`, but building one compiles a grammar
/// query, so each is made once. Clear it when the colours or the custom definitions change.
@MainActor
public final class HighlighterCache {
    private let colors: TokenColorProviding
    private var builtIn: [Language: CodeHighlighter] = [:]
    /// Languages whose grammar is compiling in the background on this cache's behalf.
    private var compiling: Set<Language> = []
    /// Custom (JSON-defined) languages by name, with the definition each was built from: two
    /// files that both say `"name": "DSL"` but differ must not share one compiled highlighter.
    private var custom: [String: (definition: CustomLanguageDefinition, highlighter: CodeHighlighter)] = [:]

    /// Called on the main queue when a grammar this cache started compiling is ready, so a
    /// surface showing that language can ask again and get the tree-sitter highlighter.
    public var onGrammarReady: ((Language) -> Void)?

    /// Creates a cache whose regex and region tiers colour through `colors`.
    public init(colors: TokenColorProviding) {
        self.colors = colors
    }

    /// The highlighter for `language`: tree-sitter where a grammar exists; for a single-file
    /// component (.astro, .vue, .svelte — several languages stacked in one file) the
    /// region-splitting tier; otherwise the regex tables.
    ///
    /// Never blocks on a grammar compile (150–230 ms for Swift on a cold launch): while the
    /// language's grammar is still compiling, the regex tier stands in — returned, not cached —
    /// the grammar compiles in the background, and ``onGrammarReady`` says when to ask again.
    public func highlighter(for language: Language) -> CodeHighlighter {
        if let hit = builtIn[language] { return hit }
        if !TreeSitterHighlighter.isGrammarReady(language) {
            if compiling.insert(language).inserted {
                TreeSitterHighlighter.compileGrammarInBackground(language) { [weak self] in
                    self?.compiling.remove(language)
                    self?.onGrammarReady?(language)
                }
            }
            return fallback(for: language)
        }
        let h: CodeHighlighter = TreeSitterHighlighter(language: language) ?? fallback(for: language)
        builtIn[language] = h
        return h
    }

    /// The regex highlighter compiled from a custom language definition.
    public func highlighter(for definition: CustomLanguageDefinition) -> CodeHighlighter {
        if let entry = custom[definition.name], entry.definition == definition { return entry.highlighter }
        let h = SyntaxHighlighter(custom: definition, colors: colors)
        custom[definition.name] = (definition, h)
        return h
    }

    /// Drops every highlighter, so the next request builds against the current colours.
    public func clear() {
        builtIn.removeAll()
        custom.removeAll()
    }

    /// The tier below tree-sitter: the region splitter for a stacked-language file, else the
    /// regex tables.
    private func fallback(for language: Language) -> CodeHighlighter {
        EmbeddedMarkupHighlighter(language: language, colors: colors) ?? SyntaxHighlighter(language: language, colors: colors)
    }
}
