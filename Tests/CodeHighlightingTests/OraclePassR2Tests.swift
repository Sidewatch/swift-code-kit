//
//  OraclePassR2Tests.swift
//  CodeHighlightingTests
//
//  Mermaid checked against VS Code's Mermaid grammar run on its own (not only inside a Markdown fence):
//  each snippet is the smallest piece of the showcase that the whole-file check found painted wrong.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// Mermaid's diagrams through the regex tier: directives, and per diagram the words, arrows, names and
/// labels VS Code's grammar scopes.
@MainActor
final class OraclePassR2Tests: XCTestCase {
    nonisolated private static let kinds: [TokenKind] = [
        .comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property, .added, .removed,
    ]

    private struct OneColourPerKind: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            if kind == .identifier { return foreground }
            let index = OraclePassR2Tests.kinds.firstIndex(of: kind) ?? 0
            return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
        }
    }

    /// The kind every character of the `occurrence`-th `marker` in `text` is painted; nil when plain or
    /// mixed.
    private func kind(of marker: String, in text: String, occurrence: Int = 1) -> TokenKind? {
        let colours = OneColourPerKind()
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        SyntaxHighlighter(language: .mermaid, colors: colours).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = text as NSString
        var range = NSRange(location: 0, length: 0)
        var from = 0
        for _ in 0..<occurrence {
            range = ns.range(of: marker, range: NSRange(location: from, length: ns.length - from))
            guard range.location != NSNotFound else { break }
            from = NSMaxRange(range)
        }
        XCTAssertNotEqual(range.location, NSNotFound, "marker \(marker) missing")
        guard range.location != NSNotFound else { return nil }
        let found = Set(
            (range.location..<NSMaxRange(range)).map { storage.attribute(.foregroundColor, at: $0, effectiveRange: nil) as? NSColor })
        guard found.count == 1, let colour = found.first ?? nil else { return nil }
        return Self.kinds.first { colours.color(for: $0) == colour }
    }

    func testDirectiveIsNotAComment() {
        let text = """
            %%{init: {"theme": "neutral"}}%%
            flowchart TB
                %% a real comment
                A --> B

            """
        XCTAssertEqual(kind(of: "%%{init", in: text), .keyword)
        XCTAssertEqual(kind(of: "\"theme\"", in: text), .string)
        XCTAssertEqual(kind(of: "}%%", in: text), .keyword)
        XCTAssertEqual(kind(of: "%% a real comment", in: text), .comment)
    }

    func testFlowchartLinksShapesAndMetadata() {
        let text = """
            flowchart TB
                direction LR
                B -- fail --> D([Quarantine])
                B -->|pass| C(Shelve)
                I --> J[/Parallelogram/]
                M --> N@{ shape: cloud, label: "Cloud" }
                subgraph one [One]
                end
                classDef hot fill:#f96,stroke:#333
                class A,B hot

            """
        XCTAssertEqual(kind(of: "TB", in: text), .function)
        XCTAssertEqual(kind(of: "LR", in: text), .function)
        XCTAssertEqual(kind(of: "fail", in: text), .string)
        XCTAssertEqual(kind(of: "pass", in: text), .string)
        XCTAssertEqual(kind(of: "/Parallelogram/", in: text), .string)
        XCTAssertEqual(kind(of: "cloud", in: text), .function)
        XCTAssertEqual(kind(of: "label", in: text), .keyword)
        XCTAssertEqual(kind(of: "one", in: text), .function)
        XCTAssertEqual(kind(of: "fill:#f96,stroke:#333", in: text), .string)
        XCTAssertEqual(kind(of: "hot", in: text, occurrence: 2), .string)
    }

    func testSequenceMessagesBlocksAndNotes() {
        let text = """
            sequenceDiagram
                participant W as Warehouse
                U->>W: Request pick list
                API-xW: Rejected
                Note over U,W: Both agree
                alt in stock
                    W->>U: Ship
                end

            """
        XCTAssertEqual(kind(of: "Warehouse", in: text), .string)
        XCTAssertEqual(kind(of: "->>", in: text), .keyword)
        XCTAssertEqual(kind(of: "-x", in: text), .keyword)
        XCTAssertEqual(kind(of: "Request pick list", in: text), .string)
        XCTAssertEqual(kind(of: "over", in: text), .function)
        XCTAssertEqual(kind(of: "in stock", in: text), .string)
    }

    func testClassDiagramNamesMembersAndRelations() {
        let text = """
            classDiagram
                class Item {
                    +String sku
                    +restock(int amount) bool
                }
                Item <|-- Widget : inherits
                Animal : +int age

            """
        XCTAssertEqual(kind(of: "Item", in: text), .type)
        XCTAssertEqual(kind(of: "String", in: text), .keyword)
        XCTAssertEqual(kind(of: "restock", in: text), .function)
        XCTAssertEqual(kind(of: "int", in: text), .keyword)
        XCTAssertEqual(kind(of: "bool", in: text), .keyword)
        XCTAssertEqual(kind(of: "Widget", in: text), .type)
        XCTAssertEqual(kind(of: "inherits", in: text), .string)
        XCTAssertEqual(kind(of: "Animal", in: text), .type)
        XCTAssertNotEqual(kind(of: "age", in: text), .string)
    }

    func testStateNotesAndPositions() {
        let text = """
            stateDiagram-v2
                [*] --> Paid : payment ok
                note right of Paid
                    A paid order can be cancelled.
                end note

            """
        XCTAssertEqual(kind(of: "[*]", in: text), .keyword)
        XCTAssertEqual(kind(of: "payment ok", in: text), .string)
        XCTAssertEqual(kind(of: "right", in: text), .keyword)
        XCTAssertEqual(kind(of: "A paid order can be cancelled.", in: text), .string)
        XCTAssertEqual(kind(of: "end", in: text), .keyword)
    }

    func testEntityRelationshipCardinalitiesAndAttributes() {
        let text = """
            erDiagram
                CUSTOMER ||--o{ ORDER : places
                CUSTOMER {
                    string name PK "Full name"
                }

            """
        XCTAssertEqual(kind(of: "||--o{", in: text), .keyword)
        XCTAssertEqual(kind(of: "places", in: text), .string)
        XCTAssertEqual(kind(of: "string", in: text), .keyword)
        XCTAssertEqual(kind(of: "PK", in: text), .keyword)
    }

    func testGanttJourneyAndQuadrantNames() {
        let text = """
            gantt
                dateFormat YYYY-MM-DD
                Order placed :done, a1, 2025-01-06, 3d
                Task :vert, v1, 17:30, 2m
            journey
                Scan badge: 5: Picker
            quadrantChart
                x-axis Low --> High
                quadrant-1 Expand
                Widget: [0.3, 0.6]

            """
        XCTAssertEqual(kind(of: "YYYY-MM-DD", in: text), .function)
        XCTAssertEqual(kind(of: "Order placed", in: text), .string)
        XCTAssertEqual(kind(of: "done", in: text), .function)
        XCTAssertNotEqual(kind(of: "vert", in: text), .string)  // a task's name ends at its first colon
        XCTAssertEqual(kind(of: "Scan badge", in: text), .string)
        XCTAssertEqual(kind(of: "Low", in: text), .string)
        XCTAssertEqual(kind(of: "High", in: text), .string)
        XCTAssertEqual(kind(of: "quadrant-1", in: text), .keyword)
        XCTAssertEqual(kind(of: "Expand", in: text), .string)
        XCTAssertEqual(kind(of: "Widget", in: text), .string)
    }

    func testMindmapRequirementXYChartAndArchitecture() {
        let text = """
            mindmap
              root((Inventory))
                Receiving
                :::someclass fa fa-book
            requirementDiagram
                requirement stock_req {
                    text: keep stock above reorder point
                    risk: high
                }
            xychart-beta
                x-axis [jan, feb]
                bar [10, 40]
            architecture-beta
                db:L -- R:server

            """
        XCTAssertEqual(kind(of: "Receiving", in: text), .string)
        XCTAssertEqual(kind(of: "someclass fa fa-book", in: text), .string)
        XCTAssertEqual(kind(of: "keep stock above reorder point", in: text), .string)
        XCTAssertEqual(kind(of: "high", in: text), .function)
        XCTAssertEqual(kind(of: "jan", in: text), .string)
        XCTAssertEqual(kind(of: "feb", in: text), .string)
        XCTAssertEqual(kind(of: "bar", in: text), .keyword)
        XCTAssertEqual(kind(of: "L", in: text), .function)
    }

    /// A rule of one diagram never paints another: a sequence note's `over` is a function, a state note's
    /// `right` a keyword; a class member's text after `: ` is no string, a sequence message's is.
    func testRulesStayInTheirDiagram() {
        let text = """
            stateDiagram-v2
                note left of A : waiting
            classDiagram
                Animal : +int age
            sequenceDiagram
                Note left of A: waiting

            """
        XCTAssertEqual(kind(of: "left", in: text), .keyword)
        XCTAssertEqual(kind(of: "left of", in: text, occurrence: 2), .function)
        XCTAssertNotEqual(kind(of: "+int age", in: text), .string)
        XCTAssertEqual(kind(of: "waiting", in: text, occurrence: 2), .string)
    }
}
