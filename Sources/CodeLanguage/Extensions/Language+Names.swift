//
//  Language+Names.swift
//  CodeLanguage
//
//  The names the detector answers a language from — for a coverage check to enumerate.
//
//  Created by David Sherlock on 9/25/26.
//

import Foundation

public extension Language {
    /// Every extension and every exact filename the detector maps to `language` (25 Sep 2026,
    /// for a corpus check that asks "is there a fixture for EVERY name we claim?"). Extensions
    /// are bare (`"toml"`), filenames exact and lower-cased (`".npmrc"`, `"cargo.lock"`).
    static func names(for language: Language) -> (extensions: [String], filenames: [String]) {
        let extensions = extensionMap.filter { $0.value == language }.keys.sorted()
            + compoundExtensionMap.filter { $0.value == language }.keys.sorted()
        let filenames = filenameMap.filter { $0.value == language }.keys.sorted()
        return (extensions, filenames)
    }
}
