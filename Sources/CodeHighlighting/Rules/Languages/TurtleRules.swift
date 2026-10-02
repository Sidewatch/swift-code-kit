//
//  TurtleRules.swift
//  CodeHighlighting
//
//  The regex rule table for Turtle (RDF), and the RDF term rules SPARQL shares with it.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Turtle: `#` comments, the four quote forms of a literal (`"…"`, `'…'`, `"""…"""`, `'''…'''`),
/// `<iri>` references, `prefix:local` names, `@lang` tags, signed numbers, and the directives.
extension RuleTables {
    static let turtle: [(String, TokenKind)] =
        rdfTerms + [
            ("(?i)(?<![\\w:.-])(?:@prefix|@base|@version|prefix|base|version)(?![\\w:.-])", .keyword)
        ]

    /// The terms Turtle and SPARQL write the same way: literals, IRIs, prefixed names, blank-node
    /// labels, language tags, the `a` shorthand, booleans and numbers. A `#` inside an IRI
    /// (`<http://…/schema#>`) is part of it; the comment rule is the language's own, which opens only
    /// after whitespace or at a line's start.
    static let rdfTerms: [(String, TokenKind)] = [
        ("\"\"\"(?:[^\"\\\\]|\\\\[\\s\\S]|\"{1,2}(?!\"))*\"\"\"", .string),
        ("'''(?:[^'\\\\]|\\\\[\\s\\S]|'{1,2}(?!'))*'''", .string),
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        ("(?<![\\w<?$/.-])(?:[A-Za-z][\\w.-]*)?:(?=[\\w%\\\\]|\\s|$)", .type),
        ("<[^\\s<>\"{}|^`\\\\]*>", .attribute),
        ("\\b_:[\\w.-]*\\w", .variable),
        ("(?<=[\"'])@[A-Za-z]+(?:-[A-Za-z0-9]*)*", .attribute),
        ("(?<![\\w:.-])a(?![\\w:.-])", .keyword),
        ("(?<![\\w:.-])(?:true|false)(?![\\w:.-])", .number),
        ("(?<![\\w:.-])[+-]?(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][+-]?\\d+)?(?![\\w:-])", .number),
    ]
}
