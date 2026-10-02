//
//  SPARQLRules.swift
//  CodeHighlighting
//
//  The regex rule table for SPARQL.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// SPARQL 1.1: Turtle's terms (literals in all four quote forms, IRIs, prefixed names, numbers),
/// `?var` / `$var` variables, the query and update keywords in any case, and the built-in calls.
extension RuleTables {
    static let sparql: [(String, TokenKind)] =
        [
            (
                "(?i)(?<![\\w:?$-])(abs|avg|bnode|bound|ceil|coalesce|concat|contains|count|datatype|day|encode_for_uri|floor|group_concat|hours|if|iri|isblank|isiri|isliteral|isnumeric|isuri|lang|langmatches|lcase|max|md5|min|minutes|month|now|rand|regex|replace|round|sameterm|sample|seconds|sha1|sha256|sha384|sha512|str|strafter|strbefore|strdt|strends|strlang|strlen|strstarts|struuid|substr|sum|timezone|tz|ucase|uri|uuid|year)(?=\\s*\\()",
                .function
            )
        ] + rdfTerms + [
            ("[?$][A-Za-z_]\\w*", .variable),
            (
                "(?i)(?<![\\w:?$-])(add|all|as|asc|ask|base|bind|by|clear|construct|copy|create|data|default|delete|desc|describe|distinct|drop|exists|filter|from|graph|group|having|in|insert|into|limit|load|minus|move|named|not|offset|optional|order|prefix|reduced|select|separator|service|silent|to|undef|union|using|values|where|with)(?![\\w:-])",
                .keyword
            ),
        ]
}
