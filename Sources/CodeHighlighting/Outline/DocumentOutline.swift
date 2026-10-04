//
//  DocumentOutline.swift
//  CodeHighlighting
//
//  One answer to "what is this file's outline?", for every language.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation
import CodeLanguage

/// One answer to "what is this file's outline?", for every language: Markdown-family headings,
/// stylesheet sections, a page's or template's structure and code, tree-sitter definitions, a data
/// file's key tree, Nix bindings, reST sections, or the regex tier's declarations. The host passes its highlight session so the tree-backed sources read the
/// session's cached tree; without one they answer empty rather than parse on the caller's thread.
public enum DocumentOutline {
    /// Where a language's outline comes from.
    public enum Source: Sendable, Equatable {
        /// ATX headings (Markdown, Quarto, R Markdown, MDX).
        case headings
        /// `/* Section */` banners and their rules (CSS, SCSS, Less).
        case stylesheet
        /// The tree-sitter symbol query, from the session's cached tree.
        case syntaxTree
        /// A data file's keys or elements to three levels, from the session's cached tree.
        case keyTree
        /// An XML property list's keys to three levels, read by ``PlistStructure``.
        case propertyList
        /// Headings, ids and landmarks, plus the code a page or template carries (HTML, Vue, Svelte,
        /// Astro, Razor, ERB, EJS, JSP).
        case markup
        /// A Nix file's attribute and `let` bindings, two levels deep.
        case bindings
        /// reStructuredText section titles.
        case sections
        /// The regex tier's declaration patterns.
        case lines
        /// No outline: prose without headings, data without names.
        case none
    }

    /// The headings languages: Markdown and the formats that embed it.
    static let headingLanguages: Set<Language> = [.markdown, .quarto, .rmarkdown, .mdx]

    /// Where `language`'s outline comes from.
    public static func source(for language: Language) -> Source {
        if headingLanguages.contains(language) { return .headings }
        if StylesheetOutline.supports(language) { return .stylesheet }
        if MarkupOutline.supports(language) { return .markup }
        if language == .nix { return .bindings }
        if language == .restructuredtext { return .sections }
        if RegexOutline.supports(language) { return .lines }
        if SymbolQueries.sources[language] != nil { return .syntaxTree }
        if TreeSitterHighlighter.keyTreeLanguages.contains(language) { return .keyTree }
        if language == .plist { return .propertyList }
        return .none
    }

    /// The outline symbols of `text` in `language`, in document order and scoped for
    /// ``OutlineTree``. `session` is the open document's highlight session: the tree-backed
    /// sources read its cached tree and answer empty without one (or before its first parse). A
    /// page or template parses the code it carries itself, so like a big file it belongs off the
    /// main thread when large.
    public static func symbols(in text: String, language: Language, session: HighlightSession?) -> [Symbol] {
        switch source(for: language) {
        case .headings: return MarkdownOutline.headings(in: text)
        case .stylesheet: return StylesheetOutline.symbols(in: text, language: language)
        case .syntaxTree: return session?.symbols(text: text) ?? []
        case .keyTree: return session?.keyTreeSymbols(text: text) ?? []
        case .propertyList: return PlistStructure.outlineSymbols(in: text)
        case .markup: return MarkupOutline.symbols(in: text, language: language)
        case .bindings: return NixOutline.symbols(in: text)
        case .sections: return RestructuredTextOutline.symbols(in: text)
        case .lines: return RegexOutline.symbols(in: text, language: language)
        case .none: return []
        }
    }

    /// The same, parsing `text` itself for the tree-backed sources — for a file that is not open
    /// (tests, tools). Thread-safe; a full parse, so not for the main thread on a big file.
    public static func symbols(parsing text: String, language: Language) -> [Symbol] {
        switch source(for: language) {
        case .syntaxTree: return TreeSitterHighlighter.symbols(in: text, language: language)
        case .keyTree: return TreeSitterHighlighter.keyTreeSymbols(in: text, language: language)
        default: return symbols(in: text, language: language, session: nil)
        }
    }

    /// Whether the breadcrumb path should come from this outline's scopes rather than the
    /// session's syntax-tree walk (which only knows definitions).
    public static func pathComesFromOutline(_ language: Language) -> Bool {
        let source = source(for: language)
        return source != .syntaxTree && source != .none
    }
}
