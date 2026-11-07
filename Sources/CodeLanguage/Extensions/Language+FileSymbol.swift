//
//  Language+FileSymbol.swift
//  CodeLanguage
//
//  The SF Symbol for any file by its name (a few dotfiles, the non-code kinds, else its language's), and its kind.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension Language {
    /// The SF Symbol for a file named `filename`: `.env` files a key, ignore files an eye slash,
    /// the non-code kinds (images, sound, video, archives, databases, fonts, PDFs, lockfiles)
    /// their own glyph, and everything else its detected language's ``symbolName``.
    static func symbolName(forFilename filename: String) -> String {
        let lower = filename.lowercased()
        if lower == ".env" || lower.hasPrefix(".env.") || lower.hasSuffix(".env") || lower == ".dev.vars" || lower.hasPrefix(".dev.vars.") {
            return "key"
        }
        if lower == ".gitignore" || lower == ".ignore" { return "eye.slash" }
        if let kind = symbolName(forKindExtension: (lower as NSString).pathExtension) { return kind }
        return detect(filename: filename).symbolName
    }

    /// The glyph for a non-code file kind by its lower-cased extension, or nil for anything else:
    /// a ``FileKind``'s own, then the video and archive formats no preview opens, and lockfiles.
    static func symbolName(forKindExtension ext: String) -> String? {
        if let kind = fileKind(forExtension: ext) { return kind.symbolName(forExtension: ext) }
        return ext == "lock" ? "lock" : nil
    }

    /// The kind of a non-code file named `filename`, or nil for code and text: a ``FileKind``'s own
    /// extensions, then the video and archive formats no preview opens. The one answer a file list
    /// groups by and draws its glyph from, so a file is never an archive by its icon and Plain Text
    /// by its group.
    static func fileKind(forFilename filename: String) -> FileKind? {
        fileKind(forExtension: (filename.lowercased() as NSString).pathExtension)
    }

    /// ``fileKind(forFilename:)`` by a lower-cased extension.
    static func fileKind(forExtension ext: String) -> FileKind? {
        if let kind = FileKind(extension: ext) { return kind }
        switch ext {
        case "avi", "mkv": return .video
        case "gz", "tgz", "bz2", "xz", "7z", "rar": return .archive
        default: return nil
        }
    }

    /// The symbol for a file with extension `ext`.
    static func symbolName(forExtension ext: String) -> String { symbolName(forFilename: "file.\(ext)") }
}
