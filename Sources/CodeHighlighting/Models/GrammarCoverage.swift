//
//  GrammarCoverage.swift
//  CodeHighlighting
//
//  Which of a grammar's constructs a text uses, and which it never does.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The constructs a tree-sitter grammar defines, set against the ones a parse of some text produced.
/// `nodes` are the grammar's visible named node types (`function_declaration`, `string_literal`), `tokens`
/// its anonymous tokens (`async`, `?.`, `>>>=`) — both read from the compiled grammar's own symbol table, so
/// "every construct" is the language's definition, not a checklist's.
public struct GrammarCoverage: Sendable, Equatable {
    /// Every visible named node type the grammar can produce.
    public let nodes: Set<String>
    /// Every anonymous token the grammar can produce (keywords, operators, punctuation).
    public let tokens: Set<String>
    /// The named node types the parse produced.
    public let seenNodes: Set<String>
    /// The anonymous tokens the parse produced.
    public let seenTokens: Set<String>
    /// ERROR and MISSING nodes in the parse — where the text and the grammar disagree.
    public let errors: Int

    /// Creates a coverage record.
    public init(nodes: Set<String>, tokens: Set<String>, seenNodes: Set<String>, seenTokens: Set<String>, errors: Int) {
        self.nodes = nodes; self.tokens = tokens; self.seenNodes = seenNodes; self.seenTokens = seenTokens; self.errors = errors
    }
}
