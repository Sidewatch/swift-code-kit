//
//  LocatedValue+Outline.swift
//  CodeHighlighting
//
//  A located document's keys as outline symbols, to a fixed depth.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

extension LocatedValue {
    /// The keys of this value to `maxDepth` levels, at most `limit`, in document order: each key's
    /// `range` its name, its `scopeRange` the key through its value, so ``OutlineTree`` nests a
    /// member's keys under it. A sequence's members are walked without adding a level. Keys with
    /// no range of their own (a gathered `#text`) are skipped.
    func outlineSymbols(in ns: NSString, maxDepth: Int = 3, limit: Int = 3000) -> [Symbol] {
        var found: [(name: String, range: NSRange, scope: NSRange)] = []
        func walk(_ value: LocatedValue, depth: Int) {
            guard found.count < limit else { return }
            switch value.node {
            case .mapping(let pairs):
                for pair in pairs where found.count < limit {
                    guard let key = pair.keyRange else { continue }
                    let end = pair.value.range.map(NSMaxRange) ?? NSMaxRange(key)
                    found.append((pair.key, key, NSRange(location: key.location, length: max(key.length, end - key.location))))
                    if depth + 1 < maxDepth { walk(pair.value, depth: depth + 1) }
                }
            case .sequence(let items):
                for item in items where found.count < limit { walk(item, depth: depth) }
            case .scalar:
                break
            }
        }
        walk(self, depth: 0)
        found.sort { $0.range.location < $1.range.location }
        var out: [Symbol] = []
        out.reserveCapacity(found.count)
        var line = 1
        var scanned = 0
        var block = [unichar](repeating: 0, count: 4096)
        for item in found where NSMaxRange(item.range) <= ns.length {
            while scanned < item.range.location {
                let n = min(block.count, item.range.location - scanned)
                ns.getCharacters(&block, range: NSRange(location: scanned, length: n))
                for i in 0..<n where block[i] == 0x0A { line += 1 }
                scanned += n
            }
            out.append(Symbol(name: item.name, kind: .property, range: item.range, line: line, scopeRange: item.scope))
        }
        return out
    }
}
