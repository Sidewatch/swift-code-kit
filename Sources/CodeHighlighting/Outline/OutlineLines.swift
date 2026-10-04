//
//  OutlineLines.swift
//  CodeHighlighting
//
//  The line starts of a text, for turning an outline symbol's offset into its line.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The line starts of a text, for turning an outline symbol's offset into its line and for
/// moving symbols found in an embedded region (a `<script>` body, a `@code` block) to their place
/// in the whole file.
struct OutlineLines {
    /// The UTF-16 offset each line starts at; the first is 0.
    let starts: [Int]

    init(_ ns: NSString) {
        var starts = [0]
        let length = ns.length
        var buffer = [unichar](repeating: 0, count: length)
        ns.getCharacters(&buffer, range: NSRange(location: 0, length: length))
        for i in 0..<length where buffer[i] == 0x0A { starts.append(i + 1) }
        self.starts = starts
    }

    /// The 0-based line holding UTF-16 offset `offset`.
    func index(of offset: Int) -> Int {
        var lo = 0, hi = starts.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if starts[mid] <= offset { lo = mid } else { hi = mid - 1 }
        }
        return lo
    }

    /// `symbols`, found in a piece of text that starts at `origin` in this file, moved to their
    /// place in the file. `textOffset` is how far into that piece the file's text begins (a wrapper
    /// added before parsing), and `textLines` how many lines that wrapper added.
    func moved(_ symbols: [Symbol], to origin: Int, textOffset: Int = 0, textLines: Int = 0) -> [Symbol] {
        let firstLine = index(of: origin)
        let shift = origin - textOffset
        return symbols.compactMap { s in
            guard s.range.location >= textOffset else { return nil }
            let range = NSRange(location: s.range.location + shift, length: s.range.length)
            let scope = s.scopeRange.map { r -> NSRange in
                let start = max(r.location, textOffset)
                return NSRange(location: start + shift, length: max(0, NSMaxRange(r) - start))
            }
            return Symbol(name: s.name, kind: s.kind, range: range, line: firstLine + s.line - textLines, scopeRange: scope)
        }
    }
}
