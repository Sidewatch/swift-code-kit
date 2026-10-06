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
/// `@inject`, whose type and namespace names are types), control flow (`@if`, `@foreach`), `@{ }` /
/// `@( )` / `@:` and implicit `@Model.Name` expressions, `@@` escapes — and the C# of the code blocks
/// (`@{ }`, `@code { }`, `@functions { }`, closed by a `}` at the start of a line) and of a control
/// statement's parentheses: `//` and `/* */` comments, keywords (a statement's first word anywhere),
/// types (declared, generic, attribute and `new` ones), calls and numbers. Strings are C#'s (`"…"`,
/// `$"…"` whose `{ }` holes stay code, `@"…"`, `"""…"""`, `'c'`) and HTML's attribute values; a value
/// that holds an `@` expression keeps only its quotes in the string colour. An apostrophe in the
/// page's text opens none. A page's `<script>` blocks get JavaScript's words and strings, its `<style>`
/// blocks CSS's numbers and units.
extension RuleTables {
    static let razor: [(String, TokenKind)] =
        [
            htmlComment,
            (insideRazorCode + "//.*$", .comment),
            (insideRazorCode + "/\\*[\\s\\S]*?\\*/", .comment),
            ("\"\"\"[\\s\\S]*?\"\"\"", .string),
            ("@\"(?:[^\"]|\"\")*\"", .string),
            // A C# string opens after an operator, a bracket or a space, never right after a name or a
            // `)`, which is where an HTML attribute value closes; an attribute value is its own rule.
            ("\"(?<![\\w)=]\")(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
            ("'(?:\\\\.|[^'\\\\\\n])'", .string),
            ("(?<==)\"(?:[^\"@\\n]|@@)*\"", .string),
            ("(?<==)'[^'@\\n]*'", .string),
            // An attribute value that holds an `@` expression: its quotes.
            ("(?<==)[\"'](?=[^\"'\\n]*@)|\"(?<=[\\w)]\")(?=[\\s/>])", .string),
            ("@@", .string),
            // `@addTagHelper *, Assembly` and its kin take the rest of their line as a string.
            (" (?<=^@(?:addTagHelper|removeTagHelper|tagHelperPrefix) )\\S.*$", .string),
        ] + interpolatedCSharpStrings + [
            ("</?[A-Za-z][\\w:.-]*|/>|>", .keyword),
            ("\\b[A-Za-z-]+=", .attribute),
            // An implicit expression (`@Model.User.Name`); its `@` is repainted a keyword just below.
            ("@(?<![\\w@]@)[A-Za-z_][\\w.]*", .variable),
            // The transitions: a directive or control word with its `@`, `@{` / `@(` / `@:`, and the `@` of
            // an implicit expression or a template (`@<p>…</p>`).
            (
                "@(?:page|model|using|namespace|inject|inherits|implements|layout|attribute|addTagHelper|removeTagHelper|tagHelperPrefix"
                    + "|typeparam|preservewhitespace|rendermode|functions|code|section|if|else|for|foreach|while|do|switch|try|catch"
                    + "|finally|lock|await)\\b|@[{(:]|(?<![\\w@])@(?=[A-Za-z_<])",
                .keyword
            ),
            // `else` at a line's start; a statement's first word, in a control block's body as much as in a
            // code block; `new`; a `}` that starts a line.
            (
                "^[ \\t]*\\}?[ \\t]*(?:else(?:[ \\t]+if)?|case|default|break|continue|return|var|finally|throw|yield|goto|using)\\b|^\\}",
                .keyword
            ),
            ("\\bnew\\b(?=[ \\t]*[({\\[A-Za-z])", .keyword),
            // A code block's other braces — the `{` after `@code`, `@functions` or `@section Name`, a `}` that
            // ends a line that starts with `@` — and a `)` after an `@(` on its line.
            (inside(opens: ["@(?:code|functions|section[ \\t]+\\w+)[ \\t]*\\{"], closes: [""], within: 0) + "\\{", .keyword),
            (inside(opens: ["(?m)^@"], closes: ["\\n"], within: 400) + "\\}(?=[ \\t]*$)", .keyword),
            (inside(opens: ["@\\("], closes: ["\\n"], within: 400) + "\\)", .keyword),
            // A call, a generic one too (`GetValues<OrderStatus>()`).
            ("\\b[A-Za-z_]\\w*(?=\\s*\\(|<[^<>()\\n]*>\\()", .function),
            scopedTrie(
                [
                    "abstract", "as", "async", "await", "base", "break", "case", "catch", "class", "const", "continue", "default",
                    "delegate",
                    "do", "else", "enum", "event", "explicit", "extern", "field", "finally", "fixed", "for", "foreach", "get", "goto", "if",
                    "implicit", "in", "init", "interface", "internal", "is", "lock", "namespace", "new", "operator", "out", "override",
                    "params", "private", "protected", "public", "readonly", "record", "ref", "required", "return", "sealed", "set",
                    "sizeof", "static", "struct", "switch", "this", "throw", "try", "typeof", "using", "value", "var", "virtual", "when",
                    "where", "while", "yield",
                ], .keyword, insideRazorCode),
            scopedTrie(
                [
                    "bool", "byte", "char", "decimal", "double", "dynamic", "float", "int", "long", "object", "sbyte", "short", "string",
                    "uint", "ulong", "ushort", "void",
                ], .type, insideRazorCode),
            // Type names: a directive's, a generic one and its arguments (`List<Order>`), a declared one
            // before a name (`Task OnInitializedAsync()`, `ElementReference inputRef;`), an attribute's
            // (`[Parameter]`), and the one a `new`, `record` or `class` names.
            (directiveLine + "\\b[A-Za-z_]\\w*\\b", .type),
            // A built-in type outside a code block, where only a type can stand: before a member access, a
            // `?`, a `[`, a variable name, or a closing bracket (`int.Parse`, `(int v)`, `List<int>`).
            (
                "\\b[A-Z]\\w*(?=<(?:[A-Za-z_][\\w.]*(?:,[ \\t]*[A-Za-z_][\\w.]*)*|,*)>(?!\\())|[A-Z](?<=\\w<[A-Z])\\w*"
                    + "|[A-Z](?<=[\\[,][ \\t]?[A-Z])\\w*(?=[ \\t]*[\\](,])"
                    + "|\\b(?:bool|byte|char|decimal|double|dynamic|float|int|long|object|sbyte|short|string|uint|ulong|ushort)\\b"
                    + "(?=\\??(?:[.\\[>)]|[ \\t]+[a-z_]\\w*[ \\t]*[=;,)]))"
                    + "|[A-Z](?<=\\b(?:new|record|class)[ \\t][A-Z])\\w*",
                .type
            ),
            (insideRazorCode + "\\b[A-Z]\\w*(?=\\??[ \\t]+[A-Za-z_]\\w*[ \\t]*(?:[;={)(,]|=>))", .type),
            (directiveLine + "\\bstatic\\b", .keyword),
            tagWords(["true", "false", "null"], .number, insideRazorCode),
            decimal,
        ] + templateLiteralHeads + pageScriptRules + pageStyleNumbers

    /// A C# interpolated string, `$"a {b} c"`: its text is string, a `{ }` hole holding no quote or brace
    /// stays code (a doubled `{{` is a brace of the text). One whose holes nest paints whole.
    static let interpolatedCSharpStrings: [(String, TokenKind)] = {
        let text = "[^\"\\\\{}\\n`$]|\\\\.|\\{\\{|\\}\\}|\\$(?!\\{)"
        let hole = "\\{(?!\\{)[^{}\"\\n]*\\}"
        let simple = inside(opens: ["\\$\"(?:\(text)|\(hole))*\""], closes: [""], within: 0)
        return [
            ("\\$\"(?:\(text))*(?:\"|(?=\(hole)(?:\(text)|\(hole))*\"))", .string),
            ("\\$\"(?!(?:\(text)|\(hole))*\")(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
            // One pass finds the pieces after a hole of a C# string and of a script's template literal.
            (
                simple + insideSimpleTemplateLiteral
                    + "(?<=\\})(?:(?:\(text))++(?:\"|(?=\\{(?!\\{)))|\"|(?:\(templateLiteralText))++(?:`|(?=\\$\\{))|`)",
                .string
            ),
        ]
    }()

    /// A directive line that names types (`@model`, `@inject`, `@using` a namespace, …), after its word;
    /// `@addTagHelper`, `@removeTagHelper` and `@tagHelperPrefix` take a string.
    static let directiveLine = inside(
        opens: ["(?m)^@(?:model|inject|inherits|implements|layout|typeparam|rendermode|namespace|using(?![ \\t]*\\())\\b"],
        closes: ["\\n"], within: 300)

    /// Inside a Razor code block — `@{`, `@code {` or `@functions {` up to a `}` that starts a line —
    /// or inside a control statement's parentheses on its line (`@foreach (var o in …)`).
    static let insideRazorCode =
        inside(opens: ["@(?:code|functions)?[ \\t]{0,8}\\{"], closes: ["\\n\\}"], within: 20000)
        + inside(
            opens: ["(?:@(?:if|for|foreach|while|switch|using|lock|await)|\\belse if|\\bcatch|\\bwhile)[ \\t]{0,8}\\("], closes: ["\\n"],
            within: 240)
}
