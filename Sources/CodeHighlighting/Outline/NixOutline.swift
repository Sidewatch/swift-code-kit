//
//  NixOutline.swift
//  CodeHighlighting
//
//  The outline of a Nix file: its attribute bindings and `let` bindings, two levels deep.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The outline of a Nix file: every `name = …;` binding of an attribute set or a `let`, each
/// holding its value up to its own `;`, kept to two levels (a flake's `inputs`, `outputs` and what
/// they bind). One pass over the text with strings (`"…"`, `''…''`) and comments (`#`, `/* */`)
/// skipped, so a `=` inside a shell script in an indented string is not a binding.
enum NixOutline {
    /// How deep the outline goes: top-level bindings and the bindings directly inside them.
    static let maxDepth = 2

    static func symbols(in text: String) -> [Symbol] {
        let ns = text as NSString
        let length = ns.length
        guard length > 0 else { return [] }
        var c = [unichar](repeating: 0, count: length)
        ns.getCharacters(&c, range: NSRange(location: 0, length: length))
        let lines = OutlineLines(ns)

        func isNameStart(_ u: unichar) -> Bool { (u >= 0x41 && u <= 0x5A) || (u >= 0x61 && u <= 0x7A) || u == 0x5F }
        func isName(_ u: unichar) -> Bool { isNameStart(u) || (u >= 0x30 && u <= 0x39) || u == 0x27 || u == 0x2D }
        func isSpace(_ u: unichar) -> Bool { u == 0x20 || u == 0x09 || u == 0x0A || u == 0x0D }

        /// A binding waiting for its `;`: the bracket depth it was made at, its symbol's index.
        var pending: [(depth: Int, index: Int)] = []
        /// The bracket depths at which a `let` is open (its bindings are variables) until `in`.
        var lets: [Int] = []
        var out: [Symbol] = []
        var scopes: [NSRange?] = []
        var depth = 0
        /// Whether the last significant token lets a binding start here: `{`, `;`, `let`, `rec {`.
        var atStatement = true
        var i = 0

        while i < length {
            let u = c[i]
            if isSpace(u) { i += 1; continue }
            // Comments.
            if u == 0x23 { while i < length, c[i] != 0x0A { i += 1 }; continue }
            if u == 0x2F, i + 1 < length, c[i + 1] == 0x2A {
                i += 2
                while i + 1 < length, !(c[i] == 0x2A && c[i + 1] == 0x2F) { i += 1 }
                i += 2
                continue
            }
            // "…" strings (with ${ } inside them skipped as text).
            if u == 0x22 {
                i += 1
                while i < length, c[i] != 0x22 { if c[i] == 0x5C { i += 1 }; i += 1 }
                i += 1; atStatement = false; continue
            }
            // ''…'' indented strings; '' followed by ' or $ or \ is an escape, not the end.
            if u == 0x27, i + 1 < length, c[i + 1] == 0x27 {
                i += 2
                while i + 1 < length {
                    if c[i] == 0x27, c[i + 1] == 0x27 {
                        if i + 2 < length, c[i + 2] == 0x27 || c[i + 2] == 0x24 || c[i + 2] == 0x5C { i += 3; continue }
                        break
                    }
                    i += 1
                }
                i += 2; atStatement = false; continue
            }
            switch u {
            case 0x7B, 0x5B, 0x28:  // { [ (
                depth += 1; i += 1; atStatement = u == 0x7B; continue
            case 0x7D, 0x5D, 0x29:  // } ] )
                depth -= 1; i += 1; atStatement = false
                while let last = lets.last, last > depth { lets.removeLast() }
                continue
            case 0x3B:  // ; ends the bindings made at this depth
                while let last = pending.last, last.depth >= depth {
                    if last.index >= 0 {  // -1: a binding below the outline's depth
                        let start = lines.starts[out[last.index].line - 1]
                        scopes[last.index] = NSRange(location: start, length: i + 1 - start)
                    }
                    pending.removeLast()
                }
                i += 1; atStatement = true; continue
            default: break
            }
            guard isNameStart(u) || u == 0x22 else { i += 1; atStatement = false; continue }
            // A word: a keyword, or (at a statement start) an attribute path followed by `=`.
            let start = i
            while i < length, isName(c[i]) || c[i] == 0x2E { i += 1 }
            let word = ns.substring(with: NSRange(location: start, length: i - start))
            if word == "let" { lets.append(depth); atStatement = true; continue }
            if word == "in", lets.last == depth { lets.removeLast(); atStatement = false; continue }
            if word == "rec" { continue }  // `rec {` keeps the statement start for its `{`
            if word == "inherit" { atStatement = false; continue }
            var j = i
            while j < length, c[j] == 0x20 || c[j] == 0x09 { j += 1 }
            let isBinding = atStatement && j < length && c[j] == 0x3D && !(j + 1 < length && c[j + 1] == 0x3D)
            atStatement = false
            guard isBinding else { continue }
            // Nested under the bindings still open, which bounds the outline's depth.
            let level = pending.count
            if level < maxDepth {
                let kind: SymbolKind = lets.last == depth ? .variable : .property
                out.append(
                    Symbol(
                        name: word, kind: kind, range: NSRange(location: start, length: i - start),
                        line: lines.index(of: start) + 1))
                scopes.append(nil)
                pending.append((depth, out.count - 1))
            } else {
                pending.append((depth, -1))
            }
            i = j + 1
        }
        return out.indices.map { k in
            Symbol(name: out[k].name, kind: out[k].kind, range: out[k].range, line: out[k].line, scopeRange: scopes[k])
        }
    }
}
