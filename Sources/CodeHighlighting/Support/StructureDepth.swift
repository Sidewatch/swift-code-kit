//
//  StructureDepth.swift
//  CodeHighlighting
//
//  How deep a structure reader follows a document's nesting.
//
//  Created by David Sherlock on 10/9/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import DataConverter

/// The nesting the structure readers follow. Every reader converts a grammar's tree by one call
/// per level, so a document nested tens of thousands of levels deep (a line of `[` or `<a>`) would
/// exhaust the stack it runs on; past `limit` a value is read as ``exceeded`` instead.
public enum StructureDepth {
    /// Levels of mappings and sequences a reader follows; the same limit the JSON readers keep.
    public static let limit = 256
    /// What stands in for a value nested past the limit.
    public static let exceeded: StructuredValue = .string("(nested past \(limit) levels)")
    /// A whole document refused for its depth: one row that says so.
    static var exceededDocument: LocatedValue {
        LocatedValue(
            node: .mapping([LocatedPair(key: "document", keyRange: nil, value: LocatedValue(node: .scalar(exceeded), range: nil))]),
            range: nil)
    }

    /// Whether `markup` (XML) nests elements past the limit: one pass over the bytes counting
    /// open tags against close tags, leaving as soon as the limit is crossed. A declaration, a
    /// comment, a processing instruction and a self-closing tag do not nest; a CDATA section is
    /// skipped whole.
    public static func exceedsLimit(markup: String) -> Bool {
        let bytes = Array(markup.utf8)
        var depth = 0
        var i = 0
        func skip(past marker: String, from start: Int) -> Int {
            let m = Array(marker.utf8)
            var j = start
            while j + m.count <= bytes.count {
                if bytes[j] == m[0], Array(bytes[j..<j + m.count]) == m { return j + m.count }
                j += 1
            }
            return bytes.count
        }
        func starts(with marker: String, at start: Int) -> Bool {
            let m = Array(marker.utf8)
            return start + m.count <= bytes.count && Array(bytes[start..<start + m.count]) == m
        }
        while i < bytes.count {
            guard bytes[i] == UInt8(ascii: "<") else { i += 1; continue }
            if starts(with: "<![CDATA[", at: i) { i = skip(past: "]]>", from: i); continue }
            if starts(with: "<!--", at: i) { i = skip(past: "-->", from: i); continue }
            if starts(with: "<!", at: i) || starts(with: "<?", at: i) { i = skip(past: ">", from: i); continue }
            let closing = starts(with: "</", at: i)
            let end = skip(past: ">", from: i)
            if closing {
                depth = max(0, depth - 1)
            } else if end >= 2, bytes[end - 2] != UInt8(ascii: "/") {
                depth += 1
                if depth > limit { return true }
            }
            i = end
        }
        return false
    }
}
