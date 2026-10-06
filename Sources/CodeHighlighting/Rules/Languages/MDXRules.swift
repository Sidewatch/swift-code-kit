//
//  MDXRules.swift
//  CodeHighlighting
//
//  The regex rule table for MDX.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// MDX: Markdown with JSX and JavaScript, painted as VS Code's MDX grammar paints them where a regex can
/// tell — the YAML front matter; headings, list markers, task boxes, quote markers, emphasis, inline code,
/// links and HTML entities; fenced blocks (fences, language word, and a JavaScript, shell or Python body);
/// JSX tags and attributes; and the JavaScript of `import` / `export` statements, `{ }` expressions and
/// attribute values. `{/* … */}` comments come from the language table. A prose quote opens nothing: an
/// apostrophe (`author's`) or a `"quoted"` word is text.
extension RuleTables {
    static let mdx: [(String, TokenKind)] =
        [
            // The YAML front matter: its fences, keys, values, numbers and flags.
            (frontMatter + "^---[ \\t]*$", .string),
            (frontMatter + "^[ \\t]*[\\w-]+(?=:(?:[ \\t]|$))", .property),
            // A value after `key: ` or a list's `- ` (a flow sequence `[a, b]` paints whole as one value).
            (frontMatter + " (?<=: |- )(?![{\\\"'#]|(?:-?\\d+(?:\\.\\d+)?|true|false|null|~)[ \\t]*$)[^\\n#]*[^\\s#]", .string),
            (frontMatter + "\\\"(?:[^\\\"\\\\\\n]|\\\\.)*\\\"|'[^'\\n]*'", .string),
            (frontMatter + "\\b(?:true|false|null)\\b|(?<![\\w.-])-?\\d+(?:\\.\\d+)?(?=[ \\t]*(?:$|[,\\]#]))", .number),
            // Markdown: headings, list markers (an ordered one's number a string), task boxes, quote markers.
            ("^#{1,6}[ \\t]+.*$", .keyword),
            ("^[ \\t>]*[-*+](?=[ \\t])", .keyword),
            ("^[ \\t>]*\\d+(?=[.)][ \\t])", .string),
            ("(?<=[-*+] )\\[[ xX]\\](?=[ \\t])", .keyword),
            ("^[ \\t]*(?:>[ \\t]?)+", .comment),
            // Emphasis and strong emphasis paint whole, markers included, as in the Markdown table.
            ("(?<!\\*)\\*(?![\\s*])[^*\\n]+?(?<![\\s*])\\*(?!\\*)", .type),
            ("(?<!\\w)_(?![\\s_])[^_\\n]+?(?<![\\s_])_(?!\\w)", .type),
            ("\\*\\*(?:[^*\\n]|\\*(?!\\*))+?\\*\\*", .function),
            ("__(?:[^_\\n]|_(?!_))+?__", .function),
            (strikethrough + "~~?", .string),
            ("(?<!`)(`+)(?!`)(?:(?!\\$\\{)[^\\n])*?(?<!`)\\1(?!`)", .string),
            // Links: the brackets, destination and title of `[text](url "title")`, `[text][ref]`, a shortcut
            // `[ref]`, `[ref]: url` (an angle-bracketed destination may hold spaces), `[^note]`; an autolink
            // `<https://…>`; a bare URL, `www.` host or e-mail address.
            (
                "!?\\[\\^?(?=[^\\]\\n]*\\](?:\\(|\\[|:))|\\]\\((?:<[^>\\n]*>|[^)\\s]*)(?:[ \\t]+(?:\\\"[^\\\"\\n]*\\\"|'[^'\\n]*'|\\([^)\\n]*\\)))?\\)",
                .string
            ),
            (linkBrackets + "\\]|!?\\[\\^?", .string),
            (" (?<=\\]: )(?<!\\[\\^[^\\]\\n]{1,60}\\]: )(?:<[^>\\n]*>|\\S+)(?:[ \\t]+(?:\\\"[^\\\"\\n]*\\\"|'[^'\\n]*'|\\([^)\\n]*\\)))?", .string),
            ("(?:https?|ftp|mailto):(?<=<(?:https?|ftp|mailto):)[^\\s<>]*>", .string),
            (
                "\\bhttps?://[^\\s<>()\\[\\]]*[^\\s<>()\\[\\].,;:]|\\bwww\\.[\\w-]+(?:\\.[\\w-]+)+|\\b[\\w.+-]+@[\\w-]+(?:\\.[\\w-]+)+\\b",
                .string
            ),
            // An HTML entity, a numeric one's digits a number.
            ("&(?:[A-Za-z][A-Za-z0-9]*|#[xX]?[0-9a-fA-F]+);", .keyword),
            ("\\d[0-9a-fA-F]*(?=;)(?<=&#[xX]?\\d[0-9a-fA-F]{0,8})", .number),
            // A fenced block: its fences, the language word, and the body by language — JavaScript's below,
            // a shell command's name and arguments, Python's strings; other bodies stay text.
            ("^[ \\t>]*(?:`{3,}|~{3,})", .string),
            ("(?:`{3,}|~{3,})[\\w+#.-]+", .function),
            (shellFence + "^[ \\t>]*[\\w./@-]+", .function),
            (shellFence + " (?<=\\S )[^\\s|;&<>\\\"'][^\\s|;&<>]*", .string),
            (shellFence + pythonFence + "\\\"(?:[^\\\"\\\\\\n]|\\\\.)*\\\"|'(?:[^'\\\\\\n]|\\\\.)*'", .string),
            // JSX: tags, attribute names and quoted values.
            ("</?[A-Za-z][\\w.:-]*|</?>|/?>", .keyword),
            ("\\b[A-Za-z_][\\w:-]*(?==)", .function),
            (jsxTag + "(?<==)\\\"[^\\\"\\n]*\\\"|(?<==)'[^'\\n]*'", .string),
            // JavaScript — `import` / `export` statements, `{ }` expressions and attribute values, and the
            // bodies of JavaScript fences: comments, strings, regular expressions, keywords, constants, numbers,
            // calls, the names a declaration gives a function or a type, generic and declared types.
            (javaScript + "//[^\\n]*|/\\*[\\s\\S]*?\\*/", .comment),
            // A string never opens right after a name (an apostrophe in prose) or an `=` (a fence's `title="…"`).
            (javaScript + "\\\"(?<![\\w=]\\\")(?:[^\\\"\\\\\\n]|\\\\.)*\\\"|'(?<!\\w')(?:[^'\\\\\\n]|\\\\.)*'", .string),
            (javaScript + "/(?<=(?:[(,=:{\\[!&|?]|return)[ \\t]?/)(?:[^/\\\\\\s]|\\\\.)(?:[^/\\\\\\n]|\\\\.)*/", .string),
            (javaScript + "/[dgimsuy]{1,6}(?=[\\s}),;.\\]])", .keyword),
            (javaScript + "\\b[A-Za-z_$][\\w$]*(?=[ \\t]*\\()", .function),
            (javaScript + "\\b(?:class|interface|type|enum|extends|implements)[ \\t]+[A-Z][\\w$]*|\\b[A-Z][\\w$]*(?=<)", .type),
            (
                javaScript
                    + "\\b(?:function[ \\t]*\\*?[ \\t]+|(?:const|let|var)[ \\t]+)[A-Za-z_$][\\w$]*(?=[ \\t]*(?:\\(|=[ \\t]*(?:async[ \\t]*)?(?:function\\b|\\([^()\\n]*\\)[ \\t]*(?::[^=\\n]*)?=>|[A-Za-z_$][\\w$]*[ \\t]*=>)))",
                .function
            ),
            scopedTrie(
                [
                    "as", "async", "await", "break", "case", "catch", "class", "const", "continue", "debugger", "default", "delete",
                    "do", "else", "export", "extends", "finally", "for", "from", "function", "get", "if", "import", "in",
                    "instanceof", "interface", "let", "new", "of", "return", "set", "static", "switch", "this", "throw", "try",
                    "type", "typeof", "var", "void", "while", "with", "yield",
                ], .keyword, javaScript),
            (javaScript + "=>|\\b\\d[\\d_]*n\\b", .keyword),
            (javaScript + "\\b(?:true|false|null|undefined|NaN|Infinity)\\b", .number),
            (
                javaScript
                    + "\\b(?:0[xXbBoO][0-9a-fA-F_]+|\\d[\\d_]*(?:\\.\\d[\\d_]*)?(?:[eE][+-]?\\d+)?)|\\B\\.\\d[\\d_]*(?:[eE][+-]?\\d+)?",
                .number
            ),
        ]
        // A template literal opens in the JavaScript; the scan for whole ones steps over fence lines, the
        // prose's multi-backtick code spans and escapes (`\``), whose backticks are not a literal's.
        + templateLiteralPieces(skip: ["(?m:^)[ \\t>]*`{3,}[^\\n]*", "``+(?:[^`\\n]|`(?!`))*?``+", "\\\\[\\s\\S]"], scope: javaScript)

    /// The YAML front matter: from a `---` that opens the file to the `---` that closes it.
    private static let frontMatter = inside(opens: ["\\A---[ \\t]*\\n"], closes: ["\\n---[ \\t]*(?=\\n|$)"], within: 4000)

    /// The JavaScript of an MDX file: an `import` / `export` statement (to the next blank line, so an
    /// exported function's body is in it), a `{ }` expression in the prose or an attribute (braces nest
    /// three deep and may span lines), and the body of a JavaScript, TypeScript or JSON fence.
    private static let javaScript =
        inside(opens: ["(?m)^(?:import|export)\\b"], closes: ["\\n[ \\t]*\\n"], within: 4000)
        + inside(opens: ["\\{(?:[^{}]|\\{(?:[^{}]|\\{(?:[^{}]|\\{[^{}]*\\})*\\})*\\})*\\}"], closes: [""], within: 0) + jsFence

    /// The body of a fence in a JavaScript dialect (`js`, `jsx`, `ts`, `tsx`, `json5`, …).
    private static let jsFence = fence("js|jsx|ts|tsx|mjs|cjs|javascript|typescript|json5?|jsonc")

    /// The body of a shell fence.
    private static let shellFence = fence("bash|sh|shell|zsh|console|shellsession")

    /// The body of a Python fence.
    private static let pythonFence = fence("python|py")

    /// A link's closing bracket and the brackets of its reference (`[text][ref]`), a footnote's `[^` and
    /// `]`, a definition's `[label]:`, and a shortcut reference (`[label]`, `![label]`), which the MDX grammar
    /// reads in any bracketed prose. A shortcut's label holds no comma, quote, brace or bracket, and its `[`
    /// follows no name, bracket, brace, `=`, `$`, `.` or backslash: that is a JavaScript array or index, or an
    /// escape. A list item's task box (`- [x]`) is not one.
    private static let linkBrackets = inside(
        opens: [
            "!?\\[[^\\]\\n]*\\](?:\\[[^\\]\\n]*\\]|:)|\\[\\^[^\\]\\n]+\\]",
            "(?:!\\[(?<![\\w\\])}{=$.\\\\]!\\[)|\\[(?<![\\w\\])}{=$.!\\\\]\\[))(?!(?<=[-*+] \\[)[ xX]\\])[^\\]\\[\\n,\"'{}()=;<>]+\\](?![(\\[:])",
        ], closes: [""], within: 0)

    /// A JSX tag, from its `<name` to its `>` (an attribute value in braces may hold quotes and braces).
    private static let jsxTag = inside(
        opens: [
            "<[A-Za-z][\\w.:-]*(?:[^<>{}\\\"']|\\\"[^\\\"\\n]*\\\"|'[^'\\n]*'|\\{(?:[^{}]|\\{(?:[^{}]|\\{(?:[^{}]|\\{[^{}]*\\})*\\})*\\})*\\})*>"
        ], closes: [""], within: 0)

    /// A `~~strikethrough~~` (or `~one~`) span, whose tildes are painted.
    private static let strikethrough = inside(opens: ["(?<!~)~~?(?=[^~\\s])[^~\\n]*[^~\\s]~~?(?!~)"], closes: [""], within: 0)

    /// The body of a fence whose language word is one of `languages` (a regex alternation), from the line
    /// opening fence to the closing one, the info string included; a fence may sit in a block quote
    /// (`> ```bash`).
    private static func fence(_ languages: String) -> String {
        inside(
            opens: ["(?m)^[ \\t>]{0,8}(?:`{3,8}|~{3,8})(?:" + languages + ")\\b"], closes: ["(?m)^[ \\t>]*(?:`{3,}|~{3,})[ \\t]*$"],
            within: 20000)
    }
}
