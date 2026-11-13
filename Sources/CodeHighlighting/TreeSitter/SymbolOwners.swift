//
//  SymbolOwners.swift
//  CodeHighlighting
//
//  Ownership: which type a method/property belongs to, derived purely from the symbol list's
//  scope ranges (no parse, no language table).
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Ownership: which type a method/property belongs to, derived purely from the
/// symbol list's scope ranges (no parse, no language table). Works for every
/// language whose methods nest inside the type's body — the containment
/// languages; Go's receiver-based methods and C++ out-of-line definitions simply
/// yield nil and stay on the un-narrowed path.
public enum SymbolOwners {

    /// The kinds that can own members.
    private static let typeKinds: Set<SymbolKind> = [.type, .structure, .enumeration, .interface]

    /// Name of the INNERMOST type whose scope contains `range` (nil when none does).
    /// `all` is one file's symbols, as `TreeSitterHighlighter.symbols` returns them.
    public static func enclosingType(of range: NSRange, in all: [Symbol]) -> String? {
        innermost(containing: range, among: all.filter { typeKinds.contains($0.kind) })
    }

    /// The innermost of `types` (type symbols only) whose scope contains `range`.
    private static func innermost(containing range: NSRange, among types: [Symbol]) -> String? {
        var best: Symbol?
        for s in types {
            guard let scope = s.scopeRange, NSLocationInRange(range.location, scope),
                scope != range
            else { continue }
            if let b = best, let bScope = b.scopeRange, bScope.length <= scope.length { continue }
            best = s
        }
        return best?.name
    }

    /// Owner per symbol for a whole file, keyed by array index — the scan-time
    /// companion to ``enclosingType(of:in:)`` (a member's owner is the innermost
    /// type whose scope contains its name).
    public static func owners(in all: [Symbol]) -> [Int: String] {
        // The types are picked out once: a generated file's ten thousand members each ask only
        // its few types, not every other symbol.
        let types = all.filter { typeKinds.contains($0.kind) }
        guard !types.isEmpty else { return [:] }
        var out: [Int: String] = [:]
        for (i, s) in all.enumerated() where !typeKinds.contains(s.kind) {
            if let o = innermost(containing: s.range, among: types) { out[i] = o }
        }
        return out
    }
}
