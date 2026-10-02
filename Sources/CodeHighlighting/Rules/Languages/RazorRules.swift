//
//  RazorRules.swift
//  CodeHighlighting
//
//  The regex rule table for Razor (ASP.NET).
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Razor: `@* *@` comments (the language's own), the `@` transitions — directives (`@page`,
/// `@inject`), control flow (`@if`, `@foreach`), `@{ }` / `@( )` / `@:` and implicit `@Model.Name`
/// expressions — and the C# of the code blocks (`@{ }`, `@code { }`, `@functions { }`, closed by a
/// `}` at the start of a line) and of a control statement's parentheses: `//` and `/* */` comments,
/// keywords, types and numbers. Strings are C#'s (`"…"`, `$"…"`, `@"…"`, `"""…"""`, `'c'`) and HTML's
/// attribute values; an apostrophe in the page's text opens none.
extension RuleTables {
    static let razor: [(String, TokenKind)] = [
        htmlComment,
        (insideRazorCode + "//.*$", .comment),
        (insideRazorCode + "/\\*[\\s\\S]*?\\*/", .comment),
        ("\"\"\"[\\s\\S]*?\"\"\"", .string),
        ("@\"(?:[^\"]|\"\")*\"", .string),
        ("\\$?\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("'(?:\\\\.|[^'\\\\\\n])'", .string),
        ("(?<==)'[^'\\n]*'", .string),
        ("</?[A-Za-z][\\w:.-]*|/>|>", .keyword),
        ("\\b[A-Za-z-]+=", .attribute),
        ("(?<=(?<![\\w@])@)[A-Za-z_][\\w.]*", .variable),
        ("(?<![\\w@])@(?=[A-Za-z_])", .keyword),
        (
            "@(?:page|model|using|namespace|inject|inherits|implements|layout|attribute|addTagHelper|removeTagHelper|tagHelperPrefix|typeparam|preservewhitespace|rendermode|functions|code|section|if|else|for|foreach|while|do|switch|try|catch|finally|lock|await)\\b|@[{(:]",
            .keyword
        ),
        ("^[ \\t]*\\}?[ \\t]*else(?:[ \\t]+if)?\\b", .keyword),
        (insideRazorCode + "\\b([A-Za-z_]\\w*)(?=\\s*\\()", .function),
        tagWords(
            [
                "abstract", "as", "async", "await", "base", "break", "case", "catch", "class", "const", "continue", "default", "delegate",
                "do", "else", "enum", "event", "explicit", "extern", "field", "finally", "fixed", "for", "foreach", "get", "goto", "if",
                "implicit", "in", "init", "interface", "internal", "is", "lock", "namespace", "new", "operator", "out", "override",
                "params", "private", "protected", "public", "readonly", "record", "ref", "required", "return", "sealed", "set",
                "sizeof", "static", "struct", "switch", "this", "throw", "try", "typeof", "using", "value", "var", "virtual", "when",
                "where", "while", "yield",
            ], .keyword, insideRazorCode),
        tagWords(
            [
                "bool", "byte", "char", "decimal", "double", "dynamic", "float", "int", "long", "object", "sbyte", "short", "string",
                "uint", "ulong", "ushort", "void",
            ], .type, insideRazorCode),
        tagWords(["true", "false", "null"], .number, insideRazorCode),
        (insideRazorCode + decimal.0, .number),
    ]

    /// Inside a Razor code block — `@{`, `@code {` or `@functions {` up to a `}` that starts a line —
    /// or inside a control statement's parentheses on its line (`@foreach (var o in …)`).
    static let insideRazorCode =
        inside(opens: ["@(?:code|functions)?[ \\t]{0,8}\\{"], closes: ["\\n\\}"], within: 20000)
        + inside(
            opens: ["(?:@(?:if|for|foreach|while|switch|using|lock|await)|\\belse if|\\bcatch|\\bwhile)[ \\t]{0,8}\\("], closes: ["\\n"],
            within: 240)
}
