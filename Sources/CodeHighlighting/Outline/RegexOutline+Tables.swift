//
//  RegexOutline+Tables.swift
//  CodeHighlighting
//
//  The declaration patterns per language for the regex outline.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation
import CodeLanguage
import DataConverter

// Every pattern starts at a line (`^`, the tables compile with `.anchorsMatchLines`) and has ONE
// capturing group, the name; everything else is `(?:…)`. `(?i:…)` makes a pattern case-blind.
// Languages left out on purpose: prose and markup without headings, data without names (CSV, logs,
// JSON Lines, hosts, requirements), embedded-language templates (Vue, Svelte, ERB…), and the few
// whose declarations a line pattern cannot find reliably (reStructuredText's underlined titles).
extension RegexOutline {
    private static func r(_ pattern: String, _ kind: SymbolKind, _ level: Int = 0) -> Rule {
        Rule(pattern: pattern, kind: kind, level: level)
    }

    /// Optional leading modifiers, then the keyword: `^[ \t]*(?:public[ \t]+)*keyword[ \t]+`.
    private static func lead(_ modifiers: String, _ keywords: String) -> String {
        #"^[ \t]*(?:(?:"# + modifiers + #")[ \t]+)*(?:"# + keywords + #")[ \t]+"#
    }

    /// `Type name(` on a line with no `;` — a C-family function definition. Statement keywords
    /// are refused in the type position so `return f(x)` is not a definition.
    private static let cFunction =
        #"^[ \t]*(?:(?:static|inline|extern|const|constexpr|virtual|kernel|__global__|__device__|__host__|__kernel|fragment|vertex|override|public|private|protected|final|abstract|async|unsafe|pure|nothrow|@\w+)[ \t]+)*(?!(?:return|else|new|throw|case|if|while|for|switch|delete|do|goto|typedef|using|sizeof)\b)[A-Za-z_][\w:<>,*&\[\]. ]*?[ \t*&]+([A-Za-z_]\w*)[ \t]*\([^;\n]*$"#

    static let tables: [Language: Table] = {
        var t: [Language: Table] = [:]

        // MARK: Shells and build files
        let sh = Table(
            rules: [
                r(#"^[ \t]*function[ \t]+([A-Za-z_][\w.:-]*)[ \t]*(?:\(\))?[ \t]*\{?[ \t]*$"#, .function),
                r(#"^[ \t]*([A-Za-z_][\w.:-]*)[ \t]*\(\)"#, .function),
            ], scoping: .braces, lineComment: "#")
        t[.sh] = sh
        t[.zsh] = sh
        t[.fish] = Table(rules: [r(#"^[ \t]*function[ \t]+([^\s;]+)"#, .function)], scoping: .indentation)
        t[.powershell] = Table(
            rules: [
                r(#"(?i:^[ \t]*(?:function|filter|workflow)[ \t]+([\w-]+))"#, .function),
                r(#"(?i:^[ \t]*class[ \t]+(\w+))"#, .type),
                r(#"(?i:^[ \t]*enum[ \t]+(\w+))"#, .enumeration),
            ], scoping: .braces, lineComment: "#")
        t[.batch] = Table(rules: [r(#"^:([A-Za-z_][\w.-]*)"#, .function)], scoping: .flat)
        // Special targets (`.PHONY`, `.SUFFIXES`…) configure make; they are not recipes.
        t[.makefile] = Table(rules: [r(#"^(?!\.[A-Z])([\w./%-]+(?:[ \t]+[\w./%-]+)*)[ \t]*::?(?![=:])"#, .function)], scoping: .flat)
        t[.just] = Table(rules: [r(#"^@?([A-Za-z_][\w-]*)(?=[^:=\n]*:(?!=))"#, .function)], scoping: .flat)
        t[.cmake] = Table(rules: [r(#"(?i:^[ \t]*(?:function|macro)[ \t]*\([ \t]*([\w.-]+))"#, .function)], scoping: .flat)
        t[.ninja] = Table(rules: [r(#"^rule[ \t]+(\S+)"#, .function)], scoping: .flat)
        t[.dockerfile] = Table(
            rules: [
                r(#"(?i:^[ \t]*FROM[ \t]+(?:--\S+[ \t]+)*\S+[ \t]+AS[ \t]+(\S+))"#, .module, 1),
                r(#"(?i:^[ \t]*FROM[ \t]+(?:--\S+[ \t]+)*(\S+)[ \t]*$)"#, .module, 1),
            ], scoping: .levels)
        t[.awk] = Table(rules: [r(#"^[ \t]*func(?:tion)?[ \t]+(\w+)"#, .function)], scoping: .braces, lineComment: "#")
        t[.tcl] = Table(
            rules: [
                r(#"^[ \t]*proc[ \t]+(\S+)"#, .function),
                r(#"^[ \t]*namespace[ \t]+eval[ \t]+(\S+)"#, .module),
            ], scoping: .braces, lineComment: "#")
        t[.nushell] = Table(
            rules: [
                r(#"^[ \t]*(?:export[ \t]+)?def(?:-env)?[ \t]+"?([\w -]+?)"?[ \t]+\["#, .function),
                r(#"^[ \t]*(?:export[ \t]+)?module[ \t]+(\w+)"#, .module),
            ], scoping: .braces, lineComment: "#")

        // MARK: Perl, Raku, R, Julia
        t[.perl] = Table(
            rules: [
                r(#"^[ \t]*package[ \t]+([\w:]+)"#, .module),
                r(#"^[ \t]*sub[ \t]+([\w:]+)"#, .function),
            ], scoping: .braces, lineComment: "#")
        t[.raku] = Table(
            rules: [
                r(#"^[ \t]*(?:(?:my|our|unit)[ \t]+)?(?:class|grammar|module|package)[ \t]+([\w:-]+)"#, .type),
                r(#"^[ \t]*(?:(?:my|our|unit)[ \t]+)?role[ \t]+([\w:-]+)"#, .interface),
                r(#"^[ \t]*(?:(?:multi|proto|only|our|my)[ \t]+)*(?:sub|method|submethod|token|rule|regex)[ \t]+([\w:'-]+)"#, .function),
            ], scoping: .braces, lineComment: "#")
        t[.r] = Table(
            rules: [
                r(#"^[ \t]*([A-Za-z.][\w.]*)[ \t]*(?:<-|<<-|=)[ \t]*function\b"#, .function),
                r(#"^[ \t]*([A-Za-z.][\w.]*)[ \t]*(?:<-|=)[ \t]*R6Class\b"#, .type),
                r(#"^[ \t]*setClass\([ \t]*["']([\w.]+)"#, .type),
            ], scoping: .braces, lineComment: "#")
        t[.julia] = Table(
            rules: [
                r(#"^[ \t]*(?:bare)?module[ \t]+(\w+)"#, .module),
                r(#"^[ \t]*(?:mutable[ \t]+)?struct[ \t]+(\w+)"#, .structure),
                r(#"^[ \t]*(?:abstract|primitive)[ \t]+type[ \t]+(\w+)"#, .type),
                r(#"^[ \t]*(?:@\w+[ \t]+)*(?:function|macro)[ \t]+([\w.!]+)"#, .function),
                r(#"^([A-Za-z_][\w!]*)\([^)\n]*\)[ \t]*=[^=]"#, .function),
            ], scoping: .indentation)

        // MARK: Ruby-likes and indentation languages
        t[.elixir] = Table(
            rules: [
                r(#"^[ \t]*(?:defmodule|defprotocol|defimpl)[ \t]+([\w.]+)"#, .module),
                r(#"^[ \t]*(?:def|defp|defmacro|defmacrop|defguard|defguardp|defdelegate|defn|defnp)[ \t]+([\w?!]+)"#, .function),
            ], scoping: .indentation)
        t[.crystal] = Table(
            rules: [
                r(#"^[ \t]*(?:abstract[ \t]+)?(?:class|struct)[ \t]+([\w:]+)"#, .type),
                r(#"^[ \t]*(?:module|lib)[ \t]+([\w:]+)"#, .module),
                r(#"^[ \t]*enum[ \t]+([\w:]+)"#, .enumeration),
                r(#"^[ \t]*(?:(?:private|protected|abstract)[ \t]+)*(?:def|macro)[ \t]+(?:self\.)?([\w?!=<>\[\]+*/%-]+)"#, .function),
            ], scoping: .indentation)
        t[.nim] = Table(
            rules: [
                r(#"^[ \t]*(?:proc|func|method|iterator|converter|template|macro)[ \t]+`?(\w+)"#, .function),
                r(
                    #"^[ \t]+([A-Z]\w*)\*?(?:\[[^\]]*\])?[ \t]*=[ \t]*(?:ref[ \t]+|ptr[ \t]+)?(?:object|enum|tuple|concept|distinct)\b"#,
                    .type),
            ], scoping: .indentation)
        t[.gdscript] = Table(
            rules: [
                r(#"^[ \t]*class(?:_name)?[ \t]+(\w+)"#, .type),
                r(#"^[ \t]*enum[ \t]+(\w+)"#, .enumeration),
                r(#"^[ \t]*signal[ \t]+(\w+)"#, .property),
                r(#"^[ \t]*(?:static[ \t]+)?func[ \t]+(\w+)"#, .function),
            ], scoping: .indentation)
        let pythonLike = Table(
            rules: [
                r(#"^[ \t]*class[ \t]+(\w+)"#, .type),
                r(#"^[ \t]*(?:async[ \t]+)?def[ \t]+(\w+)"#, .function),
                r(#"^([A-Za-z_]\w*)[ \t]*=[ \t]*(?:rule|macro|repository_rule|aspect|provider)\("#, .function),
            ], scoping: .indentation)
        t[.starlark] = pythonLike
        t[.vyper] = Table(
            rules: [
                r(#"^[ \t]*(?:struct|interface)[ \t]+(\w+)"#, .structure),
                r(#"^[ \t]*event[ \t]+(\w+)"#, .property),
                r(#"^[ \t]*def[ \t]+(\w+)"#, .function),
            ], scoping: .indentation)
        t[.coffeescript] = Table(
            rules: [
                r(#"^[ \t]*class[ \t]+([\w.]+)"#, .type),
                r(#"^[ \t]*@?([\w.$]+)[ \t]*[:=][ \t]*(?:\([^)\n]*\)[ \t]*)?[-=]>"#, .function),
            ], scoping: .indentation)
        t[.matlab] = Table(
            rules: [
                r(#"^[ \t]*classdef[ \t]+(?:\([^)]*\)[ \t]*)?(\w+)"#, .type),
                r(#"^[ \t]*function[ \t]+(?:\[?[\w, ~]*\]?[ \t]*=[ \t]*)?([\w.]+)"#, .function),
            ], scoping: .indentation)

        // MARK: ML and Haskell families
        let haskell = Table(
            rules: [
                r(#"^module[ \t]+([\w.]+)"#, .module),
                r(#"^(?:data|newtype)[ \t]+(?:family[ \t]+|instance[ \t]+)?([A-Z][\w']*)"#, .type),
                r(#"^type[ \t]+(?:family[ \t]+|alias[ \t]+)?([A-Z][\w']*)"#, .type),
                r(#"^class[ \t]+(?:\([^)\n]*\)[ \t]*=>[ \t]*)?([A-Z][\w']*)"#, .interface),
                r(#"^instance[ \t]+(?:\([^)\n]*\)[ \t]*=>[ \t]*)?([A-Z][^\n=]*?)[ \t]+where"#, .type),
                r(#"^(?:foreign[ \t]+import[ \t]+)?([a-z_][\w']*)[ \t]*::"#, .function),
            ], scoping: .indentation)
        t[.haskell] = haskell
        t[.purescript] = haskell
        t[.elm] = Table(
            rules: [
                r(#"^(?:port[ \t]+)?module[ \t]+([\w.]+)"#, .module),
                r(#"^type[ \t]+(?:alias[ \t]+)?([A-Z]\w*)"#, .type),
                r(#"^([a-z_]\w*)[ \t]*:[^:]"#, .function),
            ], scoping: .indentation)
        let dependentlyTyped = Table(
            rules: [
                r(#"^[ \t]*(?:module|namespace|section)[ \t]+([\w.]+)"#, .module),
                r(
                    #"^[ \t]*(?:(?:private|public|export|partial|total|noncomputable|protected)[ \t]+)*(?:data|record|structure|inductive|class|interface|codata)[ \t]+([A-Za-z][\w'.]*)"#,
                    .type),
                r(
                    #"^[ \t]*(?:(?:private|public|export|partial|total|noncomputable|protected)[ \t]+)*(?:def|theorem|lemma|abbrev|instance|axiom|postulate)[ \t]+([A-Za-z_][\w'.]*)"#,
                    .function),
                r(#"^([a-z_][\w']*)[ \t]*:[^:=]"#, .function),
            ], scoping: .indentation)
        t[.idris] = dependentlyTyped
        t[.agda] = dependentlyTyped
        t[.lean] = dependentlyTyped
        let ml = Table(
            rules: [
                r(#"^[ \t]*module[ \t]+(?:type[ \t]+|rec[ \t]+)?([A-Z][\w']*)"#, .module),
                r(#"^[ \t]*(?:type|and)[ \t]+(?:nonrec[ \t]+)?(?:\([^)\n]*\)[ \t]+|'\w+[ \t]+)?([a-z_][\w']*)[ \t]*(?:=|$)"#, .type),
                r(#"^[ \t]*class[ \t]+(?:virtual[ \t]+)?([a-z_][\w']*)"#, .type),
                r(#"^[ \t]*(?:let|val|external)[ \t]+(?:rec[ \t]+)?([a-z_][\w']*)"#, .function),
            ], scoping: .indentation)
        t[.ocaml] = ml
        t[.reason] = ml
        t[.rescript] = ml
        t[.sml] = Table(
            rules: [
                r(#"^[ \t]*(?:structure|signature|functor)[ \t]+([A-Z][\w']*)"#, .module),
                r(#"^[ \t]*(?:datatype|type|abstype)[ \t]+(?:'\w+[ \t]+)?([a-z_][\w']*)"#, .type),
                r(#"^[ \t]*(?:fun|val)[ \t]+(?:rec[ \t]+)?([a-z_][\w']*)"#, .function),
            ], scoping: .indentation)
        t[.fsharp] = Table(
            rules: [
                r(#"^[ \t]*(?:namespace|module)[ \t]+(?:rec[ \t]+)?([\w.]+)"#, .module),
                r(#"^[ \t]*type[ \t]+(?:private[ \t]+|internal[ \t]+)?([A-Z][\w]*)"#, .type),
                r(#"^[ \t]*(?:static[ \t]+)?(?:member|override|abstract|default)[ \t]+(?:\w+\.)?(\w+)"#, .method),
                r(#"^[ \t]*let[ \t]+(?:(?:rec|inline|private|mutable)[ \t]+)*([a-z_][\w']*)"#, .function),
            ], scoping: .indentation)

        // MARK: Lisps and Erlang (flat)
        t[.clojure] = Table(
            rules: [
                r(#"^[ \t]*\(ns[ \t]+(?:\^\S+[ \t]+)?([^\s()\[\]]+)"#, .module),
                r(#"^[ \t]*\((?:defrecord|deftype|defprotocol)[ \t]+([^\s()\[\]]+)"#, .type),
                r(#"^[ \t]*\((?:defn-?|defmacro|defmulti|defmethod)[ \t]+(?:\^\S+[ \t]+)?([^\s()\[\]]+)"#, .function),
                r(#"^[ \t]*\((?:def|defonce)[ \t]+(?:\^\S+[ \t]+)?([^\s()\[\]]+)"#, .variable),
            ], scoping: .flat)
        let lisp = Table(
            rules: [
                r(#"^[ \t]*\((?:defclass|defstruct|define-record-type|define-struct|cl-defstruct|deftype)[ \t]+\(?([^\s()]+)"#, .type),
                r(
                    #"^[ \t]*\((?:defun|defmacro|defgeneric|defmethod|defsubst|cl-defun|cl-defmacro|define-syntax|define-syntax-rule|fn|macro|lambda\*)[ \t]+\(?([^\s()]+)"#,
                    .function),
                r(#"^[ \t]*\((?:define|define-values|define/contract|define-inline)[ \t]+\(?([^\s()]+)"#, .function),
                r(#"^[ \t]*\((?:defvar|defparameter|defconstant|defcustom|defface|local|global|var)[ \t]+([^\s()]+)"#, .variable),
            ], scoping: .flat)
        t[.commonlisp] = lisp
        t[.elisp] = lisp
        t[.scheme] = lisp
        t[.racket] = lisp
        t[.fennel] = lisp
        t[.erlang] = Table(
            rules: [
                r(#"^-module\(([\w]+)\)"#, .module),
                r(#"^-record\(([\w]+)"#, .structure),
                r(#"^([a-z][\w]*)\([^\n]*\)[^\n]*->"#, .function),
            ], scoping: .flat)
        t[.prolog] = Table(rules: [r(#"^([a-z]\w*)[ \t]*(?:\(|:-)"#, .function)], scoping: .flat)
        t[.clips] = Table(
            rules: [
                r(
                    #"^[ \t]*\((?:deffunction|defrule|deftemplate|defclass|defmodule|defglobal|defgeneric|defmethod)[ \t]+([^\s()]+)"#,
                    .function)
            ],
            scoping: .flat)

        // MARK: Brace languages
        t[.gleam] = Table(
            rules: [
                r(#"^[ \t]*(?:pub[ \t]+)?(?:opaque[ \t]+)?type[ \t]+(\w+)"#, .type),
                r(#"^[ \t]*(?:pub[ \t]+)?const[ \t]+(\w+)"#, .constant),
                r(#"^[ \t]*(?:pub[ \t]+)?fn[ \t]+(\w+)"#, .function),
            ], scoping: .braces, lineComment: "//")
        t[.zig] = Table(
            rules: [
                r(
                    #"^[ \t]*(?:pub[ \t]+)?const[ \t]+(\w+)[ \t]*=[ \t]*(?:packed[ \t]+|extern[ \t]+)?(?:struct|union|opaque)\b"#,
                    .structure),
                r(#"^[ \t]*(?:pub[ \t]+)?const[ \t]+(\w+)[ \t]*=[ \t]*enum\b"#, .enumeration),
                r(
                    #"^[ \t]*(?:pub[ \t]+)?(?:export[ \t]+|extern[ \t]+(?:"\w+"[ \t]+)?|inline[ \t]+|noinline[ \t]+)?fn[ \t]+(\w+)"#,
                    .function),
                r(#"^[ \t]*test[ \t]+"([^"\n]*)""#, .function),
            ], scoping: .braces, lineComment: "//")
        t[.odin] = Table(
            rules: [
                r(#"^[ \t]*(\w+)[ \t]*::[ \t]*(?:struct|union|enum|bit_set)\b"#, .structure),
                r(#"^[ \t]*(\w+)[ \t]*::[ \t]*(?:#\w+[ \t]+)*proc\b"#, .function),
            ], scoping: .braces, lineComment: "//", blockComments: true)
        t[.v] = Table(
            rules: [
                r(#"^[ \t]*module[ \t]+(\w+)"#, .module),
                r(#"^[ \t]*(?:pub[ \t]+)?(?:struct|union)[ \t]+(\w+)"#, .structure),
                r(#"^[ \t]*(?:pub[ \t]+)?enum[ \t]+(\w+)"#, .enumeration),
                r(#"^[ \t]*(?:pub[ \t]+)?interface[ \t]+(\w+)"#, .interface),
                r(#"^[ \t]*(?:pub[ \t]+)?fn[ \t]+(?:\([^)]*\)[ \t]*)?([\w.]+)"#, .function),
            ], scoping: .braces, lineComment: "//", blockComments: true)
        let cTypes = [
            r(
                #"^[ \t]*(?:(?:public|private|protected|export|static|final|abstract|template)[ \t]+)*(?:class|interface)[ \t]+(\w+)"#,
                .type),
            r(#"^[ \t]*(?:typedef[ \t]+)?(?:struct|union)[ \t]+(\w+)[ \t]*(?:\{|:|$)"#, .structure),
            r(#"^[ \t]*(?:enum(?:[ \t]+class)?)[ \t]+(\w+)"#, .enumeration),
            r(#"^[ \t]*namespace[ \t]+([\w:]+)"#, .module),
        ]
        let shader = Table(rules: cTypes + [r(cFunction, .function)], scoping: .braces, lineComment: "//", blockComments: true)
        t[.cuda] = shader
        t[.opencl] = shader
        t[.metal] = shader
        t[.hlsl] = shader
        t[.glsl] = shader
        t[.d] = shader
        t[.wgsl] = Table(
            rules: [
                r(#"^[ \t]*struct[ \t]+(\w+)"#, .structure),
                r(#"^[ \t]*(?:@\w+(?:\([^)]*\))?[ \t]+)*fn[ \t]+(\w+)"#, .function),
            ], scoping: .braces, lineComment: "//", blockComments: true)
        t[.vala] = Table(
            rules: cTypes + [r(cFunction, .method)], scoping: .braces, lineComment: "//", blockComments: true)
        t[.haxe] = Table(
            rules: [
                r(lead("public|private|extern|final|abstract|@:\\w+", "class|interface|abstract") + #"(\w+)"#, .type),
                r(#"^[ \t]*(?:enum|typedef)[ \t]+(\w+)"#, .type),
                r(lead("public|private|static|override|inline|macro|dynamic|extern|final", "function") + #"(\w+)"#, .function),
            ], scoping: .braces, lineComment: "//", blockComments: true)
        t[.actionscript] = Table(
            rules: [
                r(lead("public|internal|final|dynamic", "class|interface") + #"(\w+)"#, .type),
                r(
                    lead("public|private|protected|internal|static|override|final", "function") + #"(?:get[ \t]+|set[ \t]+)?(\w+)"#,
                    .function),
            ], scoping: .braces, lineComment: "//", blockComments: true)
        let groovy = Table(
            rules: [
                r(lead("public|private|protected|static|abstract|final", "class|interface|enum|trait") + #"(\w+)"#, .type),
                r(#"^[ \t]*task[ \t]+(\w+)"#, .function),
                r(lead("public|private|protected|static|final|synchronized", "def") + #"(\w+)[ \t]*\("#, .function),
            ], scoping: .braces, lineComment: "//", blockComments: true)
        t[.groovy] = groovy
        t[.gradle] = groovy
        t[.hack] = Table(
            rules: [
                r(lead("abstract|final|async|public|private|protected|static", "class|interface|trait|enum") + #"(\w+)"#, .type),
                r(lead("abstract|final|async|public|private|protected|static", "function") + #"(\w+)"#, .function),
            ], scoping: .braces, lineComment: "//", blockComments: true)
        t[.solidity] = Table(
            rules: [
                r(#"^[ \t]*(?:abstract[ \t]+)?contract[ \t]+(\w+)"#, .type),
                r(#"^[ \t]*interface[ \t]+(\w+)"#, .interface),
                r(#"^[ \t]*library[ \t]+(\w+)"#, .module),
                r(#"^[ \t]*struct[ \t]+(\w+)"#, .structure),
                r(#"^[ \t]*enum[ \t]+(\w+)"#, .enumeration),
                r(#"^[ \t]*(?:function|modifier|event|error)[ \t]+(\w+)"#, .function),
            ], scoping: .braces, lineComment: "//", blockComments: true)
        t[.move] = Table(
            rules: [
                r(#"^[ \t]*module[ \t]+([\w:]+)"#, .module),
                r(#"^[ \t]*(?:public[ \t]+)?struct[ \t]+(\w+)"#, .structure),
                r(#"^[ \t]*(?:(?:public(?:\([^)]*\))?|entry|native|inline)[ \t]+)*fun[ \t]+(\w+)"#, .function),
            ], scoping: .braces, lineComment: "//", blockComments: true)
        t[.cairo] = Table(
            rules: [
                r(#"^[ \t]*(?:pub[ \t]+)?mod[ \t]+(\w+)"#, .module),
                r(#"^[ \t]*(?:#\[[^\]]*\][ \t]*)?(?:pub[ \t]+)?struct[ \t]+(\w+)"#, .structure),
                r(#"^[ \t]*(?:pub[ \t]+)?enum[ \t]+(\w+)"#, .enumeration),
                r(#"^[ \t]*(?:pub[ \t]+)?trait[ \t]+(\w+)"#, .interface),
                r(#"^[ \t]*(?:pub[ \t]+)?impl[ \t]+(\w+)"#, .type),
                r(#"^[ \t]*(?:pub[ \t]+)?fn[ \t]+(\w+)"#, .function),
            ], scoping: .braces, lineComment: "//")
        t[.carbon] = Table(
            rules: [
                r(#"^[ \t]*package[ \t]+(\w+)"#, .module),
                r(#"^[ \t]*(?:abstract[ \t]+|base[ \t]+)?(?:class|interface|choice)[ \t]+(\w+)"#, .type),
                r(#"^[ \t]*(?:virtual[ \t]+|impl[ \t]+)?fn[ \t]+(\w+)"#, .function),
            ], scoping: .braces, lineComment: "//")
        t[.qsharp] = Table(
            rules: [
                r(#"^[ \t]*namespace[ \t]+([\w.]+)"#, .module),
                r(#"^[ \t]*newtype[ \t]+(\w+)"#, .type),
                r(#"^[ \t]*(?:internal[ \t]+)?(?:operation|function)[ \t]+(\w+)"#, .function),
            ], scoping: .braces, lineComment: "//")
        t[.objectivec] = Table(
            rules: [
                r(#"^@(?:interface|implementation|protocol)[ \t]+(\w+(?:[ \t]*\([^)]*\))?)"#, .type, 1),
                r(#"^[-+][ \t]*\([^)]*\)[ \t]*(\w+:?)"#, .method, 2),
            ], scoping: .levels)
        t[.objectivecpp] = t[.objectivec]

        // MARK: Interface languages
        t[.protobuf] = Table(
            rules: [
                r(#"^[ \t]*message[ \t]+(\w+)"#, .structure),
                r(#"^[ \t]*enum[ \t]+(\w+)"#, .enumeration),
                r(#"^[ \t]*service[ \t]+(\w+)"#, .interface),
                r(#"^[ \t]*rpc[ \t]+(\w+)"#, .method),
                r(#"^[ \t]*extend[ \t]+([\w.]+)"#, .type),
            ], scoping: .braces, lineComment: "//", blockComments: true)
        t[.thrift] = Table(
            rules: [
                r(#"^[ \t]*(?:struct|union|exception)[ \t]+(\w+)"#, .structure),
                r(#"^[ \t]*enum[ \t]+(\w+)"#, .enumeration),
                r(#"^[ \t]*service[ \t]+(\w+)"#, .interface),
            ], scoping: .braces, lineComment: "//", blockComments: true)
        t[.capnp] = Table(
            rules: [
                r(#"^[ \t]*struct[ \t]+(\w+)"#, .structure),
                r(#"^[ \t]*interface[ \t]+(\w+)"#, .interface),
                r(#"^[ \t]*enum[ \t]+(\w+)"#, .enumeration),
            ], scoping: .braces, lineComment: "#")
        t[.avdl] = Table(
            rules: [
                r(#"^[ \t]*protocol[ \t]+(\w+)"#, .module),
                r(#"^[ \t]*(?:record|error)[ \t]+(\w+)"#, .structure),
                r(#"^[ \t]*enum[ \t]+(\w+)"#, .enumeration),
            ], scoping: .braces, lineComment: "//", blockComments: true)
        t[.graphql] = Table(
            rules: [
                r(#"^[ \t]*(?:extend[ \t]+)?(?:type|interface|input|union|scalar)[ \t]+(\w+)"#, .type),
                r(#"^[ \t]*(?:extend[ \t]+)?enum[ \t]+(\w+)"#, .enumeration),
                r(#"^[ \t]*(?:query|mutation|subscription|fragment)[ \t]+(\w+)"#, .function),
                r(#"^[ \t]*directive[ \t]+@(\w+)"#, .function),
            ], scoping: .braces, lineComment: "#")
        t[.prisma] = Table(
            rules: [
                r(#"^[ \t]*(?:model|view|type)[ \t]+(\w+)"#, .structure),
                r(#"^[ \t]*enum[ \t]+(\w+)"#, .enumeration),
                r(#"^[ \t]*(?:datasource|generator)[ \t]+(\w+)"#, .module),
            ], scoping: .braces, lineComment: "//")
        let hcl = Table(
            rules: [
                r(#"^[ \t]*(?:resource|data)[ \t]+((?:"[^"\n]+"[ \t]*){1,2})"#, .structure),
                r(#"^[ \t]*(?:module|provider)[ \t]+("[^"\n]+")"#, .module),
                r(#"^[ \t]*(?:variable|output)[ \t]+("[^"\n]+")"#, .variable),
            ], scoping: .braces, lineComment: "#", cleanNames: true)
        t[.terraform] = hcl
        t[.hcl] = hcl
        t[.bicep] = Table(
            rules: [
                r(#"^[ \t]*(?:resource|module)[ \t]+(\w+)"#, .module),
                r(#"^[ \t]*(?:param|var|output|type)[ \t]+(\w+)"#, .variable),
                r(#"^[ \t]*func[ \t]+(\w+)"#, .function),
            ], scoping: .braces, lineComment: "//")
        t[.rego] = Table(
            rules: [
                r(#"^package[ \t]+([\w.]+)"#, .module),
                r(#"^(?:default[ \t]+)?([a-z_]\w*)(?:\[[^\]\n]*\])?[ \t]*(?:\{|:=|=|if\b|contains\b)"#, .function),
            ], scoping: .flat)

        // MARK: Server configuration
        t[.nginx] = Table(
            rules: [
                r(
                    #"^[ \t]*((?:server|http|events|stream|mail|upstream[ \t]+\S+|location[ \t]+[^{\n]+?|if[ \t]*\([^)\n]*\)))[ \t]*\{"#,
                    .module)
            ],
            scoping: .braces, lineComment: "#")
        t[.caddyfile] = Table(rules: [r(#"^([^\s#{][^{\n]*?)[ \t]*\{"#, .module)], scoping: .braces, lineComment: "#")
        t[.apacheconf] = Table(
            rules: [
                r(
                    #"^[ \t]*<((?:VirtualHost|Directory|DirectoryMatch|Location|LocationMatch|Files|FilesMatch|IfModule|Proxy)\b[^>\n]*)>"#,
                    .module)
            ],
            scoping: .flat)
        let ini = Table(
            rules: [
                r(#"^[ \t]*\[([^\]\n]+)\]"#, .module, 1),
                r(#"^[ \t]*([^\s=:;#\[][^=:\n]*?)[ \t]*[=:]"#, .property, 2),
            ], scoping: .levels, continuation: .deeperIndent(keyLevel: 2))
        t[.ini] = ini
        t[.editorconfig] = ini
        t[.gitconfig] = ini
        t[.systemd] = ini
        // A key runs to its first unescaped `=`, `:` or blank (`key\=with\:separators` is one key) and
        // is named with its escapes read; a line continuing a value above it declares nothing.
        t[.properties] = Table(
            rules: [r(#"^[ \t\f]*((?:\\.|[^\s=:#!\\])(?:\\.|[^\s=:\\])*)(?:[ \t\f]*[=:]|[ \t\f]+\S)"#, .property)],
            scoping: .flat, continuation: .backslash, readName: PropertiesStructure.unescaped)
        t[.dotenv] = Table(rules: [r(#"^[ \t]*(?:export[ \t]+)?([A-Za-z_][\w.]*)[ \t]*="#, .constant)], scoping: .flat)
        t[.xcconfig] = Table(rules: [r(#"^[ \t]*([A-Za-z_]\w*(?:\[[^\]\n]*\])*)[ \t]*="#, .property)], scoping: .flat)
        t[.strings] = Table(rules: [r(#"^[ \t]*"((?:[^"\\\n]|\\.)*)"[ \t]*="#, .property)], scoping: .flat)

        // JSON5 and Hjson have no grammar: their keys, nested by indentation (a string continued
        // with a backslash onto an unindented line ends no scope).
        let looseJSON = Table(
            rules: [r(#"^[ \t]*["']?([\w$-]+)["']?[ \t]*:"#, .property)], scoping: .indentation, continuation: .backslash)
        t[.json5] = looseJSON
        t[.hjson] = looseJSON

        // MARK: SQL dialects
        let sql = Table(
            rules: [
                r(
                    #"(?i:^[ \t]*create[ \t]+(?:or[ \t]+(?:replace|alter)[ \t]+)?(?:(?:temporary|temp|external|materialized|unique|global|local|recursive)[ \t]+)*(?:table|view)[ \t]+(?:if[ \t]+not[ \t]+exists[ \t]+)?([\w.`"\[\]]+))"#,
                    .structure),
                r(
                    #"(?i:^[ \t]*create[ \t]+(?:or[ \t]+(?:replace|alter)[ \t]+)?(?:definer[ \t]*=[ \t]*\S+[ \t]+)?(?:function|procedure|trigger|package(?:[ \t]+body)?)[ \t]+(?:if[ \t]+not[ \t]+exists[ \t]+)?([\w.`"\[\]]+))"#,
                    .function),
                r(
                    #"(?i:^[ \t]*create[ \t]+(?:or[ \t]+replace[ \t]+)?(?:type|schema|sequence|database|domain)[ \t]+(?:if[ \t]+not[ \t]+exists[ \t]+)?([\w.`"\[\]]+))"#,
                    .type),
            ], scoping: .flat, cleanNames: true)
        t[.mysql] = sql
        t[.plsql] = sql
        t[.plpgsql] = sql
        t[.tsql] = sql
        t[.hiveql] = sql

        // MARK: Classic languages
        t[.ada] = Table(
            rules: [
                r(#"(?i:^[ \t]*package[ \t]+(?:body[ \t]+)?([\w.]+))"#, .module),
                r(#"(?i:^[ \t]*(?:task|protected)[ \t]+(?:type[ \t]+|body[ \t]+)?(\w+))"#, .type),
                r(
                    #"(?i:^[ \t]*type[ \t]+(\w+)[ \t]+is[ \t]+(?:record|(?:abstract[ \t]+)?(?:tagged[ \t]+)?(?:limited[ \t]+)?(?:record|new)|\())"#,
                    .type),
                r(#"(?i:^[ \t]*(?:overriding[ \t]+)?(?:procedure|function)[ \t]+([\w."]+))"#, .function),
            ], scoping: .indentation)
        t[.pascal] = Table(
            rules: [
                r(#"(?i:^[ \t]*(?:program|unit|library)[ \t]+([\w.]+))"#, .module),
                r(#"(?i:^[ \t]*(\w+)[ \t]*=[ \t]*(?:packed[ \t]+)?(?:class|record|object|interface)\b)"#, .type),
                r(#"(?i:^[ \t]*(?:class[ \t]+)?(?:procedure|function|constructor|destructor)[ \t]+([\w.]+))"#, .function),
            ], scoping: .indentation)
        t[.fortran] = Table(
            rules: [
                r(#"(?i:^[ \t]*(?:program|module(?![ \t]+procedure)|submodule[ \t]*\([^)\n]*\))[ \t]+(\w+))"#, .module),
                r(#"(?i:^[ \t]*type(?:[ \t]*,[ \t]*[\w()]+)*[ \t]*(?:::)?[ \t]+(\w+)[ \t]*$)"#, .structure),
                r(
                    #"(?i:^[ \t]*(?:(?:pure|elemental|recursive|impure|module|integer|real|logical|character|complex|double[ \t]+precision|type[ \t]*\([^)\n]*\))(?:[ \t]*\([^)\n]*\))?[ \t]+)*(?:subroutine|function)[ \t]+(\w+))"#,
                    .function),
            ], scoping: .indentation)
        t[.cobol] = Table(
            rules: [
                r(#"(?i:^[ \t\d]*([\w-]+[ \t]+DIVISION)[ \t]*\.)"#, .module, 1),
                r(#"(?i:^[ \t\d]*([\w-]+[ \t]+SECTION)[ \t]*\.)"#, .function, 2),
            ], scoping: .levels)
        let vb = Table(
            rules: [
                r(
                    #"(?i:^[ \t]*(?:(?:public|private|protected|friend|shared|notinheritable|mustinherit|partial|static|shadows)[ \t]+)*(?:class|module|structure|interface|namespace)[ \t]+(\w+))"#,
                    .type),
                r(#"(?i:^[ \t]*(?:(?:public|private|protected|friend)[ \t]+)*enum[ \t]+(\w+))"#, .enumeration),
                r(
                    #"(?i:^[ \t]*(?:(?:public|private|protected|friend|shared|overridable|overrides|mustoverride|static|async|iterator|default|readonly|overloads)[ \t]+)*(?:function|sub|property)[ \t]+(\w+))"#,
                    .function),
            ], scoping: .indentation)
        t[.vbnet] = vb
        t[.vbscript] = vb
        t[.abap] = Table(
            rules: [
                r(#"(?i:^[ \t]*class[ \t]+([\w/]+)[ \t]+(?:definition|implementation))"#, .type),
                r(#"(?i:^[ \t]*(?:method|form|function|module)[ \t]+([\w/~-]+))"#, .function),
            ], scoping: .flat)
        t[.applescript] = Table(rules: [r(#"^[ \t]*(?:on|to)[ \t]+(?!error\b)(\w+)"#, .function)], scoping: .flat)
        t[.assembly] = Table(rules: [r(#"^([A-Za-z_.$][\w.$@]*):"#, .function)], scoping: .flat)
        t[.llvm] = Table(
            rules: [
                r(#"^define[^@\n]*@([\w.$"-]+)\("#, .function),
                r(#"^%([\w.$-]+)[ \t]*=[ \t]*type\b"#, .type),
                r(#"^@([\w.$-]+)[ \t]*="#, .variable),
            ], scoping: .flat, cleanNames: true)
        t[.wat] = Table(rules: [r(#"^[ \t]*\(func[ \t]+\$([\w.$-]+)"#, .function)], scoping: .flat)
        t[.jq] = Table(rules: [r(#"^[ \t]*def[ \t]+(\w+)"#, .function)], scoping: .flat)
        t[.stata] = Table(rules: [r(#"^[ \t]*program[ \t]+(?:define[ \t]+)?(?!drop\b|list\b|dir\b)(\w+)"#, .function)], scoping: .flat)
        t[.sas] = Table(
            rules: [
                r(#"(?i:^[ \t]*%macro[ \t]+(\w+))"#, .function),
                r(#"(?i:^[ \t]*data[ \t]+([\w.]+))"#, .structure),
            ], scoping: .flat)
        t[.wolfram] = Table(rules: [r(#"^([A-Za-z$][\w$]*)\[[^\]\n]*\][ \t]*:?="#, .function)], scoping: .flat)
        t[.yacc] = Table(rules: [r(#"^([a-zA-Z_][\w.]*)[ \t]*(?:\n[ \t]*)?:(?!:)"#, .function)], scoping: .flat)
        t[.xquery] = Table(rules: [r(#"^[ \t]*declare[ \t]+(?:%\w+[ \t]+)*function[ \t]+([\w:.-]+)"#, .function)], scoping: .flat)
        t[.xslt] = Table(
            rules: [r(#"^[ \t]*<xsl:template[^>\n]*?\b(?:name|match)="([^"\n]+)""#, .function)], scoping: .flat)

        // MARK: Hardware description
        let verilog = Table(
            rules: [
                r(
                    #"^[ \t]*(?:(?:virtual|static|automatic)[ \t]+)*(?:module|macromodule|interface|program|package|class|primitive|checker)[ \t]+(?:(?:automatic|static)[ \t]+)?(\w+)"#,
                    .type, 1),
                r(
                    #"^[ \t]*(?:(?:virtual|pure|extern|static|protected|local)[ \t]+)*(?:function|task)[ \t]+(?:(?:automatic|static)[ \t]+)?(?:[\w:\[\]]+[ \t]+)*?(\w+)[ \t]*[(;]"#,
                    .function, 2),
            ], scoping: .levels)
        t[.verilog] = verilog
        t[.systemverilog] = verilog
        t[.vhdl] = Table(
            rules: [
                r(#"(?i:^[ \t]*(?:entity|configuration)[ \t]+(\w+)[ \t]+is)"#, .type, 1),
                r(#"(?i:^[ \t]*package[ \t]+(?:body[ \t]+)?(\w+)[ \t]+is)"#, .module, 1),
                r(#"(?i:^[ \t]*architecture[ \t]+(\w+)[ \t]+of)"#, .type, 1),
                r(#"(?i:^[ \t]*component[ \t]+(\w+))"#, .structure, 2),
                r(#"(?i:^[ \t]*(\w+)[ \t]*:[ \t]*process\b)"#, .function, 2),
                r(#"(?i:^[ \t]*(?:pure[ \t]+|impure[ \t]+)?(?:function|procedure)[ \t]+(\w+))"#, .function, 2),
            ], scoping: .levels)

        // MARK: Editors and engines
        t[.vimscript] = Table(
            rules: [
                r(#"^[ \t]*fu(?:n|nc|nction)?!?[ \t]+([\w:#.<>]+)"#, .function),
                r(#"^[ \t]*(?:export[ \t]+)?def!?[ \t]+([\w:#.]+)"#, .function),
            ], scoping: .flat)
        t[.shaderlab] = Table(
            rules: [
                r(#"^[ \t]*Shader[ \t]+"([^"\n]+)""#, .module),
                r(#"^[ \t]*(SubShader|Pass|CGPROGRAM|HLSLPROGRAM)\b"#, .type),
            ], scoping: .braces, lineComment: "//")
        t[.cfml] = Table(
            rules: [
                r(#"(?i:^[ \t]*<cffunction[^>\n]*?\bname=["']([^"'\n]+))"#, .function),
                r(#"(?i:^[ \t]*(?:(?:public|private|remote|package)[ \t]+)?(?:[\w.]+[ \t]+)?function[ \t]+(\w+))"#, .function),
                r(#"(?i:^[ \t]*component\b[^{\n]*?\bdisplayname=["']([^"'\n]+))"#, .type),
            ], scoping: .flat)
        // Indented stylesheets: top-level selectors, mixins and functions.
        let indentedStyles = Table(
            rules: [
                r(#"^(?:@mixin|@function|=)[ \t]*([\w-]+)"#, .function),
                r(#"^([.#&*\[:a-zA-Z][^\n=]*?)[ \t]*$"#, .selector),
            ], scoping: .indentation)
        t[.sass] = indentedStyles
        t[.stylus] = indentedStyles

        // MARK: Templates (named blocks only)
        let jinja = Table(rules: [r(#"^.*?\{%-?[ \t]*(?:block|macro)[ \t]+(\w+)"#, .function)], scoping: .flat)
        t[.jinja] = jinja
        t[.twig] = jinja
        t[.nunjucks] = jinja
        t[.liquid] = Table(rules: [r(#"^.*?\{%-?[ \t]*(?:block|capture)[ \t]+(\w+)"#, .function)], scoping: .flat)
        t[.blade] = Table(rules: [r(#"^.*?@(?:section|yield|push|component)\([ \t]*['"]([^'"\n]+)"#, .function)], scoping: .flat)

        // MARK: Documents (headings by level)
        func headings(_ marks: [String], _ suffix: String = "") -> [Rule] {
            marks.enumerated().map { level, mark in r("^" + mark + suffix, .heading, level + 1) }
        }
        t[.latex] = Table(
            rules: ["part", "chapter", "section", "subsection", "subsubsection", "paragraph"].enumerated().map { level, command in
                r(#"^[ \t]*\\"# + command + #"\*?(?:\[[^\]\n]*\])?\{([^}\n]*)\}"#, .heading, level + 1)
            }, scoping: .levels)
        t[.texinfo] = Table(
            rules: [
                r(#"^@(?:chapter|unnumbered|appendix|majorheading|chapheading)[ \t]+(.+)$"#, .heading, 1),
                r(#"^@(?:section|unnumberedsec|appendixsec|heading)[ \t]+(.+)$"#, .heading, 2),
                r(#"^@(?:subsection|unnumberedsubsec|appendixsubsec|subheading)[ \t]+(.+)$"#, .heading, 3),
                r(#"^@(?:subsubsection|unnumberedsubsubsec|appendixsubsubsec|subsubheading)[ \t]+(.+)$"#, .heading, 4),
            ], scoping: .levels)
        // Longest marker first is unnecessary: each pattern demands a space right after its marks.
        t[.asciidoc] = Table(
            rules: headings(["=", "==", "===", "====", "=====", "======"], #"[ \t]+(.+?)[ \t]*$"#), scoping: .levels)
        t[.org] = Table(
            rules: headings([#"\*"#, #"\*\*"#, #"\*\*\*"#, #"\*{4}"#, #"\*{5}"#, #"\*{6}"#], #"[ \t]+(.+?)[ \t]*$"#), scoping: .levels)
        t[.textile] = Table(
            rules: (1...6).map { r(#"^h\#($0)(?:\([^)]*\))?\.[ \t]+(.+?)[ \t]*$"#, .heading, $0) }, scoping: .levels)
        t[.mediawiki] = Table(
            rules: (1...6).map { level in
                let marks = String(repeating: "=", count: level)
                return r("^" + marks + #"[ \t]*([^=\n].*?)[ \t]*"# + marks + #"[ \t]*$"#, .heading, level)
            }, scoping: .levels)
        t[.http] = Table(rules: [r(#"^###[ \t]*(\S.*?)[ \t]*$"#, .function)], scoping: .flat)
        // A static host's files: each `_headers` block by its URL pattern, each `_redirects` rule by its source.
        t[.staticheaders] = Table(rules: [r(#"^([^ \t\n#][^\n]*?)[ \t]*$"#, .module)], scoping: .flat)
        t[.staticredirects] = Table(rules: [r(#"^[ \t]*([^ \t\n#]\S*)"#, .constant)], scoping: .flat)
        t[.bibtex] = Table(
            rules: [r(#"(?i:^[ \t]*@(?!comment\b|preamble\b|string\b)\w+[ \t]*\{[ \t]*([^,\s]+))"#, .constant)], scoping: .flat)
        t[.diff] = Table(
            rules: [
                r(#"^\+\+\+ (?:[ab]/)?([^\t\n]+)"#, .module, 1),
                r(#"^(@@ [^@\n]*@@.*)$"#, .function, 2),
            ], scoping: .levels)
        return t
    }()
}
