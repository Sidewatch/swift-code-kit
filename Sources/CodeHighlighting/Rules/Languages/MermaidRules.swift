//
//  MermaidRules.swift
//  CodeHighlighting
//
//  The regex rule table for Mermaid.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Mermaid, painted the way VS Code's Mermaid grammar reads each diagram: `%%` comments, a
/// `%%{init: …}%%` directive (its delimiters and name keywords, its JSON strings strings — never a
/// comment), front matter keys and values, the diagram header, every diagram's arrows and structure words,
/// and per diagram the text Mermaid treats as a label: a node shape's text, an edge's text, a message, a
/// note, a block's description (`alt in stock`), a gantt task's name, a mindmap node, an axis label. Names
/// a diagram declares are typed where the grammar types them (a class diagram's classes, a member's type,
/// a method), and a direction (`TB`, `LR`) or a gantt date format is a function name, as VS Code paints it.
///
/// A file may hold several diagrams one after another, so each diagram's rules are scoped to its own
/// region: from its header line to the next header line (``mermaidDiagram(_:)``).
extension RuleTables {
    /// The table. Its `%%` comment rule is added with every language's own comments (``mermaidComment``).
    static let mermaid: [(String, TokenKind)] = mermaidCode + mermaidStrings

    // MARK: Code

    /// The code rules, in paint order: a later rule repaints an earlier one. Every rule scans the whole file,
    /// so rules of one kind share a pattern wherever each branch is safe outside its own diagram, and only a
    /// branch that is not stays scoped. A branch anchored at `^` or opening on any character slows a shared
    /// pattern, so it stays alone.
    static let mermaidCode: [(String, TokenKind)] =
        [
            // A node name at a line's start; the rules below repaint the structure words among them.
            (#"^[ \t]*[A-Za-z_][\w-]*"#, .variable),
            // The diagram header, and an XY chart's series (`bar [10, 40]`).
            (
                #"^[ \t]*(?:"# + prefixTree(mermaidHeaderWords) + #"(?=\s|$)(?:[ \t]+horizontal\b)?|(?:bar|line)(?=[ \t]*\[))"#,
                .keyword
            ),
            // Front matter keys (`title:`, `config:`), YAML-style.
            (mermaidFrontMatter + #"^[ \t]*[\w-]+(?=[ \t]*:)"#, .property),
            // Links and arrows: `-->`, `==>`, `-.->`, `<-->`, `->>`, `<<->>`; each diagram's own forms come below.
            (#"<<-{1,2}>>|<?(?:-{1,5}|={2,5}|-\.{1,4}-?)>{0,2}"#, .type),
            (#"\b\d+(?:\.\d+)?%?\b|\b(?:true|false)\b"#, .number),
        ] + mermaidDiagramCode
        + [
            // Last, so a diagram's own rules cannot repaint them: the structure words; a `[*]` state,
            // `<<interface>>`, a `%%{init: …}%%` directive's delimiters and name, an ER cardinality (`||--o{`)
            // and key (`PK, FK`), a gitGraph or requirement option (`id:`), a quadrant's name, a mindmap
            // `::icon`, the brackets and punctuation.
            wordTrie(mermaidWords, .keyword),
            (#"\b(?:id|tag|type|order|text|docref)(?=:)"#, .keyword),
            (
                #"\[\*\]|<<[-\w]+>>|%%\{[ \t]*\w*|\}%%|(?:\|o|\|\||\}o|\}\|)(?:--|\.\.)(?:o\||\|\||o\{|\|\{)|::icon\b"#
                    + #"|[\[\](){}|,:@]"#,
                .keyword
            ),
            // After the words, what VS Code's grammar names a function: a direction (`flowchart TB`,
            // `direction LR`), a gantt task's tags (`done`, `after`) and date format, a `@{ … }`'s shape
            // (`shape: rect`), a requirement's risk and verification method, a gitGraph commit type; a sequence
            // note's position (`over`, `left of`).
            (#"\b(?:TB|TD|BT|RL|LR)(?=[ \t]*$)|\b(?:NORMAL|REVERSE|HIGHLIGHT|crit|done|active|after)\b"#, .function),
            (
                #"[ \t](?<=[t:][ \t])(?:(?<=\b(?:dateFormat|axisFormat)[ \t])[-.%/\\\w]+"#
                    + #"|(?<=\bshape:[ \t])[^,}\n]*|(?<=\b(?:risk|verifymethod):[ \t])\w+)"#,
                .function
            ),
            (mermaidSequence + #"\b(?:(?:left|right)[ \t]+of|over)\b"#, .function),
        ]

    /// The structure words of every diagram.
    static let mermaidWords = [
        "subgraph", "end", "direction", "title", "note", "Note", "left", "right", "of", "over", "participant", "actor",
        "activate", "deactivate", "loop", "alt", "else", "opt", "par", "and", "critical", "break", "option", "rect", "box",
        "autonumber", "section", "class", "state", "click", "style", "classDef", "linkStyle", "dateFormat", "axisFormat",
        "excludes", "todayMarker", "tickInterval", "as", "commit", "branch", "checkout", "merge", "cherry-pick",
        "namespace", "accTitle", "accDescr", "showData", "fork", "join", "choice", "x-axis", "y-axis", "requirement",
        "element", "satisfies", "verifymethod", "risk", "shape", "label", "PK", "FK", "UK", "quadrant-1", "quadrant-2",
        "quadrant-3", "quadrant-4",
    ]

    /// Each diagram's own code rules, where a pattern means something else in another diagram.
    static let mermaidDiagramCode: [(String, TokenKind)] = [
        // Flowchart: a subgraph's id (a function to VS Code's grammar); the full link forms (`--o`, `x--x`,
        // `-.->`) and an asymmetric shape's `>` (`G>Flag]`).
        (mermaidFlowchart + #"\bsubgraph[ \t]+[ 0-9<>\p{L}]+(?![\[\w])"#, .function),
        (mermaidFlowchart + #"[<ox]?(?:-{2,5}|={2,5}|-?\.{1,4}-|-\.)[>ox]?|>(?<=\w>)(?=[^\s>-])"#, .keyword),
        // Sequence diagram: every message arrow (`->>`, `-x`, `--)`, with `+`/`-` activation).
        (mermaidSequence + #"<<-{1,2}>>|--?[)>x]>?[-+]?"#, .keyword),
        // Class diagram: class names (declared, related, owning a member) are types; a method's name a
        // function; the relation arrows, a member's type, a method's parameter and return types, generics
        // (`~T~`), visibility marks and classifiers keywords.
        (
            mermaidClass
                + #"^[ \t]*[-\w]+(?=[ \t]?:[ \t]|[ \t]*(?:"[^"\n]*"[ \t]*)?(?:<\||\*--|o--|<--|<\.\.|--|\.\.))"#,
            .type
        ),
        (mermaidClass + #"\bclass[ \t]+[-\w]+|(?:--\|?>?|\.\.\|?>?|--[o*])[ \t]*(?:"[^"\n]*"[ \t]*)?[-\w]+|>>[ \t]*[-\w]+"#, .type),
        // A method's name after its visibility mark (`+restock(`) or at a body line's start; the mark is
        // repainted a keyword below.
        (mermaidClass + #"[-#+~][-\w]++(?=\()|\n[ \t]+[-\w]++(?=\()"#, .function),
        (
            mermaidClass
                + #"<\|--|--\|>|<\|\.\.|\.\.\|>|--o|--\*|o--|\*--|<--|-->|<\.\.|\.\.>|--|\.\.|~[-\w]+(?=~)"#
                + #"|[-#+~](?=[-\w]+\()|[(,][ \t]*[-\w]+(?=[ \t]+[-\w]+[ \t]*[,)])|\)[$*]{0,2}[ \t]*[-\w]*"#,
            .keyword
        ),
        (mermaidClass + #"[ \t](?<=:[ \t])[-#+~]?[-\w]+(?=(?:~[-\w]+~)?[ \t]+[-\w]+[ \t]*$)"#, .keyword),
        (mermaidClassBody + #"^[ \t]+[-#+~]?[-\w]+(?![-\w(])"#, .keyword),
        // Entity relationship: an attribute's type.
        (mermaidStateOrER + #"^[ \t]+[-\w]+(?=[ \t]+[A-Za-z_])"#, .keyword),
        // Architecture: a port's side (`db:L`), a function to VS Code's grammar; the declaration words.
        (mermaidArchitecture + #"\b[BLRT](?=:)|:[BLRT]\b"#, .function),
        (mermaidArchitecture + #"\b(?:group|service|junction|in)\b"#, .keyword),
    ]

    // MARK: Strings

    /// The strings: quoted text everywhere, then each diagram's labels. Each rule opens on a narrow set of
    /// characters (a space, a line break, a quote, a word's first letter) and only then checks what precedes
    /// it with a short lookbehind: a pattern that opens with a lookbehind is tried at every character of
    /// the file. A fixed two-character lookbehind before a long one turns most candidates away at once.
    static let mermaidStrings: [(String, TokenKind)] = [
        ("\"[^\"\\n]*\"", .string),
        // After a space, each branch checking the words before it (a `[-=.\w:>][ \t]` lookbehind first turns
        // indentation away at once): `title Restock plan`, `section Morning`, a gantt `excludes`, `tickInterval`
        // or `todayMarker` value, a requirement's `text:`, a sequence block's description (`alt in stock`,
        // `rect rgb(…)`) — the rest of the line; a participant's alias (`participant W as Warehouse`); a
        // `@{ … }`'s `label:`; a flowchart link's text between its halves (`-- fail -->`); a quadrant axis's
        // labels around `-->` and a quadrant's name; a style list (`classDef hot fill:#f96`, `style C …`,
        // `linkStyle 0 …`) and the class a `class` statement applies (`class A,B hot`).
        (
            #"[ \t](?<=[-=.\w:>][ \t])(?:(?<=(?:le|on|es|al|er|t:)[ \t])(?<=\b(?:title|section|excludes|tickInterval|todayMarker|text:)[ \t])[^\n]+"#
                + #"|(?<=(?:lt|se|pt|op|ar|nd|al|on|ak|ct|ox|er)[ \t])"#
                + #"(?<=\b(?:alt|else|opt|loop|par|and|critical|option|break|rect|box|autonumber)[ \t])[^#;\n]+"#
                + #"|(?<=\bas[ \t])(?<=\b(?:participant|actor)[ \t][^\n]{1,60}[ \t]as[ \t])[^\n]+"#
                + #"|(?<=l:[ \t])(?<=\blabel:[ \t])[^,}\n]+|(?<=(?:--|==|-\.)[ \t])[^|\n]*?(?=[ \t]*(?:-{2,5}|={2,5}|\.{1,3}-)[>ox]?)"#
                + #"|(?<=is[ \t])(?<=\b[xy]-axis[ \t])(?=[A-Za-z])[^\n]*?(?=[ \t]*-->|[ \t]*$)"#
                + #"|(?<=-[1-4][ \t])(?<=\bquadrant-[1-4][ \t])[^\n]+"#
                + #"|(?<=->[ \t])(?=[A-Za-z])(?<=\b[xy]-axis[ \t][^\n]{1,40})[^\n]+"#
                + #"|(?=[-#,;\w]*+:)(?<=\b(?:classDef|style|linkStyle)[ \t][-,\w]{1,24}[ \t])[-#,:;\w]+"#
                + #"|(?=[A-Za-z_]\w*+[ \t]*$)(?<=\bclass[ \t][-,\w]{1,24}[ \t])[A-Za-z_]\w*)"#,
            .string
        ),
        // A node shape's text (`[Receive goods]`, `((Return))`, `>Flag]`, `[/Parallelogram/]`, a mindmap's
        // `))bang((`) and a link's text between its bars (`-->|pass|`): never the node after an arrow (`-->B`),
        // nor a `@{ … }`'s (its first character is a space); a mindmap line's `:::` class list.
        (
            mermaidShapes
                + #"(?:\b\w|[/\\])(?<=[\[({>)|:].)(?:(?:(?<=[\[({>)].)(?<![-=]>.)|(?<=[-=.>ox]\|.))"#
                + #"(?:[^\[\](){}|"\n]*[^\[\](){}|"\n\s])?|(?<=:::.)(?<=\n[ \t]{0,40}:::.)[^\n]*)"#,
            .string
        ),
        // The text after `: `, to the line's end: a front matter value, a message or a note (never a quoted key's
        // value), a state transition's label or description, an entity relation's label; a class relation's
        // label.
        (mermaidFrontMatter + mermaidSequence + mermaidStateOrER + #"[ \t](?<=:[ \t])(?<=[^"\s][ \t]?:[ \t])[^\n]+"#, .string),
        (
            mermaidClass
                + #"[ \t](?<=:[ \t])(?<=[-.>|o*"][ \t][-\w]{1,40}[ \t]?:[ \t])[^\n]+"#,
            .string
        ),
        // A state note's lines, from the line after `note right of X` (no `:`) to `end note`.
        (
            #"\n(?<=[-\w]\n)(?<=\bof[ \t][-\w]{1,24}\n)(?<=\bnote[ \t](?:left|right)[ \t]of[ \t][-\w]{1,24}\n)[\s\S]*?(?=\n[ \t]*end[ \t]+note\b)"#,
            .string
        ),
        // A gantt or journey task's name and a quadrant point's name, to the first colon (Mermaid's gantt lexer
        // ends a task's text at its first `:`).
        (
            mermaidGanttJourneyOrQuadrant
                + #"\n[ \t](?![ \t]*(?:%%|title\b|section\b|dateFormat\b|axisFormat\b|excludes\b|includes\b|todayMarker\b|tickInterval\b|weekday\b))"#
                + #"[^:\n]*+(?=:)"#,
            .string
        ),
        // Mindmap: a bare node line.
        (mermaidMindmap + #"\n[ \t]*[^\s:(){}\[\]%][^(){}\[\]\n]*+(?=\n|$)"#, .string),
        // An item of a bracketed list (an XY chart axis's categories `[jan, feb]`), up to its comma.
        (#"\b[A-Za-z_](?<=[\[,].|,[ \t].)[^,\[\]\n"]*(?<=\w)(?=[ \t]*[,\]])(?=[^\[\]\n]*\])"#, .string),
        // A single-quoted value after `: ` (a `@{ … }`'s `assigned: 'picker'`).
        (#"'(?<=:[ \t]')[^'\n]*'"#, .string),
    ]

    /// A Mermaid line comment: `%%` to the line's end, except a `%%{init: …}%%` directive (neither its `%%{`
    /// nor its `}%%` opens one).
    static let mermaidComment: (String, TokenKind) = (#"%%(?<!\}%%)(?!\{).*$"#, .comment)

    // MARK: Scopes

    /// Every diagram header Mermaid knows, as words.
    static let mermaidHeaderWords: Set<String> = [
        "graph", "flowchart", "sequenceDiagram", "classDiagram", "classDiagram-v2", "stateDiagram", "stateDiagram-v2",
        "erDiagram", "journey", "gantt", "pie", "quadrantChart", "requirementDiagram", "gitGraph", "C4Context",
        "C4Container", "C4Component", "C4Dynamic", "C4Deployment", "mindmap", "timeline", "zenuml", "sankey",
        "sankey-beta", "xychart", "xychart-beta", "block", "block-beta", "packet", "packet-beta", "kanban",
        "architecture", "architecture-beta", "radar-beta", "treemap-beta", "info",
    ]

    /// Scopes a rule to the diagrams `header` opens: from the header line to the next diagram's header. The
    /// region is one pattern that steps a line at a time (a character-by-character scan to a close is slower
    /// on every paint), and reaches 20,000 characters back for a header above the painted range.
    static func mermaidDiagram(_ header: String) -> String {
        let nextHeader = #"[ \t]*"# + prefixTree(mermaidHeaderWords) + #"(?=\s|\z)"#
        return RuleScope.marker(
            opens: [#"(?m:^)[ \t]*(?:"# + header + #")(?=\s|\z)[^\n]*+(?:\n(?!"# + nextHeader + #")[^\n]*+)*+"#],
            closes: [""], within: 20000)
    }

    static let mermaidFlowchart = mermaidDiagram("graph|flowchart")
    static let mermaidSequence = mermaidDiagram("sequenceDiagram")
    static let mermaidClass = mermaidDiagram("classDiagram(?:-v2)?")
    /// State and entity-relationship diagrams: one scope, as their rules agree (a region costs a scan of its
    /// own on every paint).
    static let mermaidStateOrER = mermaidDiagram("stateDiagram(?:-v2)?|erDiagram")
    static let mermaidGanttJourneyOrQuadrant = mermaidDiagram("gantt|journey|quadrantChart")
    static let mermaidMindmap = mermaidDiagram("mindmap")
    static let mermaidArchitecture = mermaidDiagram("architecture(?:-beta)?")

    /// The diagrams whose nodes have bracketed shapes with a text label.
    static let mermaidShapes = mermaidFlowchart + mermaidMindmap + mermaidArchitecture

    /// A class body, `class Name {` to its `}`.
    static let mermaidClassBody = RuleScope.marker(opens: [#"(?m:^)[ \t]*class\b[^{\n]*\{"#], closes: [#"\}"#], within: 4000)

    /// Front matter: the `---` fenced YAML block at the file's top.
    static let mermaidFrontMatter = RuleScope.marker(opens: [#"\A---[ \t]*\n"#], closes: [#"\n---"#], within: 4000)
}
