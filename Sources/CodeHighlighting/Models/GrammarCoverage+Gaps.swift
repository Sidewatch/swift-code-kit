//
//  GrammarCoverage+Gaps.swift
//  CodeHighlighting
//
//  GrammarCoverage: what is missing, and how much is covered.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

extension GrammarCoverage {
    /// Named node types the grammar defines and the text never produced, sorted.
    public var missingNodes: [String] { nodes.subtracting(seenNodes).sorted() }
    /// Anonymous tokens the grammar defines and the text never produced, sorted.
    public var missingTokens: [String] { tokens.subtracting(seenTokens).sorted() }
    /// The share of named node types the text produced, 0…1 (1 for a grammar with none).
    public var nodeShare: Double { nodes.isEmpty ? 1 : Double(nodes.intersection(seenNodes).count) / Double(nodes.count) }
    /// The share of anonymous tokens the text produced, 0…1 (1 for a grammar with none).
    public var tokenShare: Double { tokens.isEmpty ? 1 : Double(tokens.intersection(seenTokens).count) / Double(tokens.count) }
}
