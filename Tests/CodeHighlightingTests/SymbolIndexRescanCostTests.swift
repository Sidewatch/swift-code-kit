//
//  SymbolIndexRescanCostTests.swift
//  CodeHighlightingTests
//
//  A rescan of a file whose names the whole project shares stays cheap on the main thread.
//
//  Created by David Sherlock on 10/3/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import CodeLanguage
@testable import CodeHighlighting

/// A rescan swaps one file's definitions; removing the old ones must not cost a file-system call
/// per definition of every name the file shares with the rest of the project (`init`, `run`).
@MainActor
final class SymbolIndexRescanCostTests: XCTestCase {

    /// 1,500 files defining the same three names; twenty of them rescanned. Prints the main-thread
    /// time the swap took (the before/after measure) and checks the index stays right.
    func testRescanningFilesThatShareCommonNamesIsCheap() throws {
        try XCTSkipUnless(TreeSitterHighlighter.supports(.python))
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let body = "def run():\n    pass\n\ndef setup():\n    pass\n\ndef teardown():\n    pass\n"
        var files: [URL] = []
        for i in 0..<1500 {
            let url = dir.appendingPathComponent("module_\(i).py")
            try body.write(to: url, atomically: true, encoding: .utf8)
            files.append(url)
        }
        let idx = ProjectSymbolIndex()
        let built = expectation(description: "build completes")
        idx.build(root: dir) { built.fulfill() }
        wait(for: [built], timeout: 60)
        XCTAssertEqual(idx.definitions(of: "run").count, 1500)

        let edited = Array(files.prefix(20))
        for url in edited { try (body + "\ndef extra():\n    pass\n").write(to: url, atomically: true, encoding: .utf8) }
        let start = Date()
        for url in edited { idx.updateFile(url) }
        let deadline = Date().addingTimeInterval(120)
        while idx.rescannedFiles < edited.count, Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.005)) }
        let elapsed = Date().timeIntervalSince(start)
        print("RESCAN-COST: 20 rescans over 1,500 files sharing 3 names: \(Int(elapsed * 1000)) ms")
        XCTAssertEqual(idx.rescannedFiles, edited.count)
        XCTAssertEqual(idx.definitions(of: "run").count, 1500, "replaced, never duplicated or lost")
        XCTAssertEqual(idx.definitions(of: "extra").count, 20)
        XCTAssertEqual(idx.pathResolvingRemovals, 0, "every removal compared URLs; none resolved a path per definition")

        // A second rescan of the same files finds the URLs the first one recorded.
        for url in edited { try body.write(to: url, atomically: true, encoding: .utf8); idx.updateFile(url) }
        let again = Date().addingTimeInterval(120)
        while idx.rescannedFiles < 2 * edited.count, Date() < again { RunLoop.main.run(until: Date().addingTimeInterval(0.005)) }
        XCTAssertEqual(idx.definitions(of: "extra").count, 0, "the second rescan removed what the first added")
        XCTAssertEqual(idx.definitions(of: "run").count, 1500)
        XCTAssertEqual(idx.pathResolvingRemovals, 0)
    }
}
