//
//  SMLRules.swift
//  CodeHighlighting
//
//  The regex rule table for Standard ML.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Standard ML: nesting `(* *)` comments (the language table adds them) — there is no `--` comment;
/// `"…"` strings with backslash escapes and `#"a"` character literals, while a type variable `'a` opens
/// nothing; the Definition's reserved words (core and modules); `~1` negatives, `0wx` words and reals.
/// The name a `fun` binds and every `| name args =` clause of it (and an `and name args =` sibling) is a
/// function; the type constructor a `type` / `datatype` / `eqtype` / `withtype` / `abstype` binds, after
/// its type variables, and the argument type of an `exception E of …` are types.
extension RuleTables {
    static let sml: [(String, TokenKind)] = [
        ("#?\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        ("\\bfun\\s+(?:'+\\w+\\s+|\\([^)]*\\)\\s+)?[a-z_][\\w']*", .function),
        ("\\|[ \\t]*[a-z_][\\w']*(?=[ \\t][^=\\n]*=(?!>))", .function),
        ("\\band\\s+[a-z_][\\w']*(?=[ \\t]+[^=\\s])", .function),
        (
            "\\b(?:type|datatype|eqtype|withtype|abstype)\\s+(?:'+\\w+\\s+|\\([^)]*\\)\\s*)?[a-z_][\\w']*|\\band\\s+(?:'+\\w+\\s+|\\([^)]*\\)\\s*)[a-z_][\\w']*",
            .type
        ),
        (smlExceptionPayload + "\\b[a-z_][\\w']*", .type),
        (smlTypeExpression + "\\b[a-z_][\\w']*(?![\\w']|\\s*:(?!:))", .type),
        keywords([
            "abstype", "and", "andalso", "as", "case", "datatype", "do", "else", "end", "eqtype", "exception", "fn",
            "fun", "functor", "handle", "if", "in", "include", "infix", "infixr", "let", "local", "nonfix", "of", "op",
            "open", "orelse", "raise", "rec", "sharing", "sig", "signature", "struct", "structure", "then", "type",
            "val", "where", "while", "with", "withtype",
        ]),
        constants(["true", "false", "nil"]),
        ("'+[A-Za-z_][\\w']*", .type),
        ("\\b[A-Z][A-Za-z0-9_']*", .type),
        ("(?<![\\w'])~?(?:0w?x[0-9a-fA-F]+|0w\\d+|\\d+(?:\\.\\d+)?(?:[eE]~?\\d+)?)\\b", .number),
    ]

    /// A type expression: what a `val name :` specification or annotation gives (`val add : sku * int * t -> t`),
    /// and the right side of a `type` / `eqtype` abbreviation (`type id = int`), each up to the next declaration
    /// word, an `=`, an unbalanced `)` or the line's end. Its lowercase names are type constructors, except a
    /// record field's label (`{ name : string }`); its keywords are repainted after it.
    static let smlTypeExpression: String = {
        let body =
            "(?:[^=()\\n]|\\([^()\\n]*\\))*?"
            + "(?=\\b(?:val|type|eqtype|datatype|fun|end|and|exception|structure|sig|struct|in|local)\\b|[=)]|\\n|$)"
        return RuleScope.marker(
            steppingOver: [], regions: "\\bval\\s+(?:op\\s+)?[a-z_][\\w']*\\s*:(?!:)" + RuleScope.region(body), within: 300)
            + RuleScope.marker(
                steppingOver: [],
                regions: "\\b(?:type|eqtype)\\s+(?:'+\\w+\\s+|\\([^)]*\\)\\s*)?[a-z_][\\w']*\\s*=(?!>)" + RuleScope.region(body),
                within: 300)
    }()

    /// The argument type of an exception declaration: `exception E of …` to the end of its line.
    static let smlExceptionPayload = RuleScope.marker(opens: ["\\bexception\\s+[A-Z][\\w']*\\s+of\\b"], closes: ["\\n"], within: 200)
}
