//
//  TreeSitterHighlighter+SyntaxTree.swift
//  CodeHighlighting
//
//  TreeSitterHighlighter: the parse of a text as an S-expression.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation
import CodeLanguage
import SwiftTreeSitter

extension TreeSitterHighlighter {
    /// The tree `language`'s grammar builds for `text`, as tree-sitter's S-expression (named nodes only,
    /// MISSING nodes shown). Nil when the language has no tree-sitter grammar here. For tests that pin a
    /// parse's shape, which an ERROR count alone cannot.
    static func syntaxTree(of text: String, language: CodeLanguage.Language) -> String? {
        guard let g = grammar(for: language) else { return nil }
        let parser = Parser()
        try? parser.setLanguage(g.language)
        return parser.parse(text)?.rootNode?.sExpressionString
    }
}
