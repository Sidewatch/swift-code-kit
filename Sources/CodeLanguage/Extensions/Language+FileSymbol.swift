//
//  Language+FileSymbol.swift
//  CodeLanguage
//
//  The SF Symbol for any file by its name: a few dotfiles, the non-code kinds, else its language's.
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
        if lower == ".env" || lower.hasPrefix(".env.") || lower.hasSuffix(".env") { return "key" }
        if lower == ".gitignore" || lower == ".ignore" { return "eye.slash" }
        if let kind = symbolName(forKindExtension: (lower as NSString).pathExtension) { return kind }
        return detect(filename: filename).symbolName
    }

    /// The glyph for a non-code file kind by its lower-cased extension, or nil for anything else.
    static func symbolName(forKindExtension ext: String) -> String? {
        switch ext {
        case "png", "jpg", "jpeg", "gif", "webp", "ico", "bmp", "tiff", "heic": return "photo"
        case "svg": return "square.on.circle"
        case "mp3", "wav", "m4a", "flac", "aac", "ogg", "aiff", "aif": return "waveform"
        case "mp4", "mov", "m4v", "webm", "avi", "mkv": return "film"
        case "zip", "tar", "gz", "tgz", "bz2", "xz", "7z", "rar": return "archivebox"
        case "db", "sqlite", "sqlite3": return "cylinder"
        case "ttf", "otf", "woff", "woff2": return "textformat"
        case "pdf": return "doc.fill"
        case "lock": return "lock"
        default: return nil
        }
    }

    /// The symbol for a file with extension `ext`.
    static func symbolName(forExtension ext: String) -> String { symbolName(forFilename: "file.\(ext)") }
}
