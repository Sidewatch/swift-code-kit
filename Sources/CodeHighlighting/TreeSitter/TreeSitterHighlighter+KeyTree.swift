//
//  TreeSitterHighlighter+KeyTree.swift
//  CodeHighlighting
//
//  A data file's outline: its keys (JSON, YAML, TOML) or elements (XML) to a fixed depth.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation
import CodeLanguage
import SwiftTreeSitter

extension TreeSitterHighlighter {
    /// The languages whose outline is their key tree.
    public static let keyTreeLanguages: Set<CodeLanguage.Language> = [.json, .jsonc, .yaml, .toml, .xml]

    /// A data file's keys to `maxDepth` levels, at most `limit` of them, in document order: each
    /// key's `range` its name, its `scopeRange` the whole member (so ``OutlineTree`` nests a
    /// member's keys under it). A walk, not a query: it stops at the depth and at the limit, so a
    /// 2 MB lock file costs what its first few thousand keys cost. Thread-safe; parses `text`.
    public static func keyTreeSymbols(
        in text: String, language: CodeLanguage.Language, maxDepth: Int = 3, limit: Int = 3000
    ) -> [Symbol] {
        guard keyTreeLanguages.contains(language), let g = grammar(for: language) else { return [] }
        let parser = Parser()
        try? parser.setLanguage(g.language)
        guard let tree = parser.parse(text), let root = tree.rootNode else { return [] }
        return keyTreeSymbols(root: root, ns: text as NSString, language: language, maxDepth: maxDepth, limit: limit)
    }

    /// The walk half of ``keyTreeSymbols(in:language:maxDepth:limit:)``, over an already-parsed
    /// tree (``HighlightSession`` passes its cached one).
    static func keyTreeSymbols(root: Node, ns: NSString, language: CodeLanguage.Language, maxDepth: Int, limit: Int) -> [Symbol] {
        var found: [(name: String, kind: SymbolKind, range: NSRange, scope: NSRange)] = []
        var stack: [(node: Node, depth: Int)] = [(root, 0)]
        while let item = stack.popLast(), found.count < limit {
            let (node, depth) = item
            var childDepth = depth
            if let entry = entry(node, ns: ns, language: language) {
                found.append((entry.name, entry.kind, entry.range, node.range))
                childDepth = depth + 1
                if childDepth >= maxDepth { continue }
            }
            // Reversed onto the stack, so the walk pops them in document order.
            for i in stride(from: node.namedChildCount - 1, through: 0, by: -1) {
                if let child = node.namedChild(at: i) { stack.append((child, childDepth)) }
            }
        }
        var out: [Symbol] = []
        out.reserveCapacity(found.count)
        var line = 1
        var scanned = 0
        var block = [unichar](repeating: 0, count: 4096)
        for item in found {
            while scanned < item.range.location {
                let n = min(block.count, item.range.location - scanned)
                ns.getCharacters(&block, range: NSRange(location: scanned, length: n))
                for i in 0..<n where block[i] == 0x0A { line += 1 }
                scanned += n
            }
            out.append(Symbol(name: item.name, kind: item.kind, range: item.range, line: line, scopeRange: item.scope))
        }
        return out
    }

    /// The outline entry `node` is, if it is one: a JSON / YAML member, a TOML table or key, an XML
    /// element — its name, kind and the name's range.
    private static func entry(_ node: Node, ns: NSString, language: CodeLanguage.Language) -> (
        name: String, kind: SymbolKind, range: NSRange
    )? {
        let type = node.nodeType ?? ""
        let nameNode: Node?
        var kind = SymbolKind.property
        switch language {
        case .json, .jsonc, .yaml:
            guard type == "pair" || type == "block_mapping_pair" || type == "flow_pair" else { return nil }
            nameNode = node.child(byFieldName: "key")
        case .toml:
            guard type == "table" || type == "table_array_element" || type == "pair" else { return nil }
            if type != "pair" { kind = .module }
            nameNode = (0..<node.namedChildCount).lazy.compactMap { node.namedChild(at: $0) }
                .first { ["bare_key", "dotted_key", "quoted_key"].contains($0.nodeType ?? "") }
        case .xml:
            guard type == "element" else { return nil }
            let tag = (0..<node.namedChildCount).lazy.compactMap { node.namedChild(at: $0) }
                .first { $0.nodeType == "STag" || $0.nodeType == "EmptyElemTag" }
            nameNode = tag.flatMap { t in (0..<t.namedChildCount).lazy.compactMap { t.namedChild(at: $0) }.first { $0.nodeType == "Name" } }
        default:
            return nil
        }
        guard let nameNode, nameNode.range.length > 0, NSMaxRange(nameNode.range) <= ns.length else { return nil }
        var name = ns.substring(with: nameNode.range).trimmingCharacters(in: .whitespacesAndNewlines)
        if name.count >= 2, let first = name.first, first == name.last, first == "\"" || first == "'" {
            name = String(name.dropFirst().dropLast())
        }
        if name.count > 80 { name = String(name.prefix(80)) + "…" }
        guard !name.isEmpty else { return nil }
        return (name, kind, nameNode.range)
    }
}
