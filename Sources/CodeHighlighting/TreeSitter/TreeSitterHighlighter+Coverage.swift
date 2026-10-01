//
//  TreeSitterHighlighter+Coverage.swift
//  CodeHighlighting
//
//  TreeSitterHighlighter: grammar coverage of a text.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation
import CodeLanguage
import SwiftTreeSitter
import TreeSitter

extension TreeSitterHighlighter {
    /// How much of `language`'s grammar `text` exercises: every visible named node type and anonymous
    /// token the compiled grammar defines (from its symbol table; hidden and auxiliary symbols, which never
    /// appear in a tree, are left out), against the ones a parse of `text` produced. Nil when the language
    /// has no tree-sitter grammar here.
    public static func grammarCoverage(of text: String, language: CodeLanguage.Language) -> GrammarCoverage? {
        guard let grammar = grammar(for: language) else { return nil }
        let lang = grammar.language
        var nodes = Set<String>(), tokens = Set<String>()
        for id in 1..<max(lang.symbolCount, 1) {  // symbol 0 is the runtime's end-of-input marker
            guard let name = lang.symbolName(for: id), !name.isEmpty, !name.hasPrefix("_"), name != "ERROR" else { continue }
            switch ts_language_symbol_type(lang.tsLanguage, TSSymbol(id)) {
            case TSSymbolTypeRegular: nodes.insert(name)
            case TSSymbolTypeAnonymous:
                if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { tokens.insert(name) }
            default: break  // auxiliary and supertype symbols never stand as a node of their own
            }
        }
        let parser = Parser()
        try? parser.setLanguage(lang)
        guard let tree = parser.parse(text), let root = tree.rootNode else { return nil }
        var seenNodes = Set<String>(), seenTokens = Set<String>(), errors = 0
        func walk(_ node: Node) {
            if let type = node.nodeType {
                if type == "ERROR" || node.isMissing {
                    errors += 1
                } else if node.isNamed {
                    seenNodes.insert(type)
                } else {
                    seenTokens.insert(type)
                }
            }
            for i in 0..<node.childCount { if let c = node.child(at: i) { walk(c) } }
        }
        walk(root)
        return GrammarCoverage(nodes: nodes, tokens: tokens, seenNodes: seenNodes, seenTokens: seenTokens, errors: errors)
    }
}
