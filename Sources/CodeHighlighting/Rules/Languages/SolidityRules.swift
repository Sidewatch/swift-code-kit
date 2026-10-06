//
//  SolidityRules.swift
//  CodeHighlighting
//
//  The regex rule table for Solidity.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Solidity: `"…"` and `'…'` strings, the `hex` / `unicode` prefix of `hex"…"` and `unicode"…"` as a keyword
/// before its string, the language's
/// keywords, `uint256` / `bytes32` / `address` value types, ether and time units. Calls paint
/// before keywords, so `returns (`, `require(` and `mapping(` stay keywords.
extension RuleTables {
    static let solidity: [(String, TokenKind)] = [
        doubleQuoted,
        singleQuoted,
        call,
        keywords([
            "pragma", "solidity", "import", "as", "from", "contract", "interface", "library", "abstract", "is", "function",
            "modifier", "event", "error", "struct", "enum", "mapping", "constructor", "fallback", "receive", "returns",
            "return", "if", "else", "for", "while", "do", "break", "continue", "try", "catch", "emit", "revert", "require",
            "assert", "using", "new", "delete", "public", "private", "internal", "external", "pure", "view", "payable",
            "constant", "immutable", "override", "virtual", "memory", "storage", "calldata", "transient", "indexed",
            "anonymous", "unchecked", "assembly", "let", "leave", "switch", "case", "default", "type", "this", "super",
            "global", "layout", "at",
        ]),
        ("\\b(?:hex|unicode)(?=[\"'])", .keyword),
        types(["address", "bool", "string", "bytes\\d*", "u?int\\d*", "u?fixed[\\dx]*", "byte"]),
        constants(["true", "false"]),
        decimal,
        keywords(["wei", "gwei", "ether", "seconds", "minutes", "hours", "days", "weeks"]),
    ]
}
