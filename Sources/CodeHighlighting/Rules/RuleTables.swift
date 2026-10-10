//
//  RuleTables.swift
//  CodeHighlighting
//
//  The regex (pattern, kind) tables behind `SyntaxHighlighter` for languages that have no tree-
//  sitter grammar.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation
import CodeLanguage

/// The regex (pattern, kind) tables behind `SyntaxHighlighter` for languages that have no
/// tree-sitter grammar. One file per language under `Rules/Languages`, one per family under
/// `Rules/Families`; the shared builders live in `RuleTables+Builders.swift`.
enum RuleTables {

    /// The table for `lang` — its own, or its family's when it has none — with the language's own
    /// comment syntax added, so a family table cannot leave a language's comments unrecognised, and a
    /// programming language's plain names painted as identifiers (``withNames(_:for:)``).
    static func table(for lang: Language) -> [(String, TokenKind)] {
        withOwnComments(withNames(baseTable(for: lang), for: lang), for: lang)
    }

    /// The table written for `lang`; languages without one fall through to their family's.
    static func baseTable(for lang: Language) -> [(String, TokenKind)] {
        switch lang {
        case .swift: return swift
        case .python: return python
        case .javascript, .typescript: return javascript
        case .astro: return astro
        case .html: return html
        case .css: return css
        case .scss, .less: return scss
        case .sass: return sass
        case .postcss: return postcss
        case .stylus: return stylus
        case .json: return json
        case .rust: return rust
        case .go: return go
        case .kotlin: return kotlin
        case .php: return php
        case .csharp: return csharp
        case .dart: return dart
        case .markdown: return markdown
        case .bash, .sh, .zsh: return bash
        case .batch: return batch
        case .bicep: return bicep
        case .crystal: return crystal
        case .just: return just
        case .nginx: return nginx
        case .nushell: return nushell
        case .prql: return prql
        case .carbon: return carbon
        case .d: return d
        case .solidity: return solidity
        case .vhdl: return vhdl
        case .fish: return fish
        case .fsharp: return fsharp
        case .haskell: return haskell
        case .gitcommit: return gitcommit
        case .ini: return ini
        case .http: return http
        case .dockerfile: return dockerfile
        case .yaml: return yaml
        case .xml: return xml
        case .sql: return sql
        case .c, .cpp: return c
        case .java: return java
        case .ruby: return ruby
        case .gettext: return gettext
        case .gitignore: return gitignore
        case .vue: return vue
        case .svelte: return svelte
        case .terraform, .hcl: return terraform
        case .graphql: return graphql
        case .prisma: return prisma
        case .protobuf: return protobuf
        case .toml: return toml
        case .diff: return diff
        case .pascal: return pascal
        case .sparql: return sparql
        case .turtle: return turtle
        case .twig: return twig
        case .nunjucks: return nunjucks
        case .liquid: return liquid
        case .handlebars: return handlebars
        case .smarty: return smarty
        case .velocity: return velocity
        case .erb: return erb
        case .jsp: return jsp
        case .cfml: return cfml
        case .razor: return razor
        case .marko: return marko
        case .blade: return blade
        case .raku: return raku
        // Languages whose family table paints them flat or nearly flat.
        case .erlang: return erlang
        case .prolog: return prolog
        case .fortran: return fortran
        case .cobol: return cobol
        case .assembly: return assembly
        case .llvm: return llvm
        case .smalltalk: return smalltalk
        case .vbscript: return vbscript
        case .xquery: return xquery
        case .abap: return abap
        case .mermaid: return mermaid
        case .julia: return julia
        case .kdl: return kdl
        case .lean: return lean
        case .makefile: return makefile
        case .plantuml: return plantuml
        case .log: return log
        case .asciidoc: return asciidoc
        case .restructuredtext: return restructuredtext
        case .textile: return textile
        case .gitattributes: return gitattributes
        case .json5, .hjson: return json5
        case .nix: return nix
        case .pug, .haml: return indentedMarkup
        case .slim: return slim
        case .ron: return ron
        case .verilog, .systemverilog: return verilog
        case .vimscript: return vimscript
        case .jinja: return jinja
        case .bibtex: return bibtex
        case .dot: return dot
        case .edgeql: return edgeql
        case .gomod: return gomod
        case .manifest: return manifest
        case .meson: return meson
        case .quarto, .rmarkdown: return quarto
        case .strings: return strings
        case .texinfo: return texinfo
        case .nim: return nim
        case .ninja: return ninja
        case .objectivecpp: return objectiveCpp
        case .powershell: return powershell
        case .purescript: return purescript
        case .coffeescript: return coffeescript
        case .org: return org
        case .elixir: return elixir
        case .stata: return stata
        case .sas: return sas
        case .hack: return hack
        case .properties: return properties
        case .jsonnet: return jsonnet
        case .cypher: return cypher
        case .move: return move
        case .capnp: return capnp
        case .vbnet: return vbnet
        case .r: return r
        case .ocaml: return ocaml
        case .sml: return sml
        case .gleam: return gleam
        case .gdscript: return gdscript
        case .thrift: return thrift
        case .wolfram: return wolfram
        case .latex: return latex
        case .mdx: return mdx
        case .applescript: return applescript
        case .actionscript: return actionscript
        case .ada: return ada
        case .agda: return agda
        case .awk: return awk
        case .haxe: return haxe
        case .idris: return idris
        case .perl: return perl
        case .gitconfig: return gitconfig
        case .glsl: return glsl
        case .hlsl: return hlsl
        case .cuda: return cuda
        case .metal: return metal
        case .opencl: return opencl
        case .wgsl: return wgsl
        case .objectivec: return objectiveC
        case .vala: return vala
        case .shaderlab: return shaderlab
        case .commonlisp: return commonLisp
        case .elisp: return emacsLisp
        case .scheme: return scheme
        case .racket: return racket
        case .fennel: return fennel
        case .clojure: return clojure
        case .elm: return elm
        case .wat: return wat
        case .starlark: return starlark
        case .rego: return rego
        case .groovy, .gradle: return groovy
        case .tcl: return tcl
        case .vyper: return vyper
        case .v: return v
        case .zig: return zig
        case .reason: return reason
        case .cue: return cue
        case .dotenv: return dotenv
        case .staticheaders: return staticheaders
        case .staticredirects: return staticredirects
        case .caddyfile: return caddyfile
        case .mediawiki: return mediawiki
        case .hiveql: return hiveql
        case .plsql: return plsql
        case .plpgsql: return plpgsql
        case .apacheconf: return apacheconf
        case .cmake: return cmake
        case .odin: return odin
        case .cairo: return cairo
        default: return table(for: lang.family)
        }
    }

    /// The table shared by every language of `family` that has none of its own.
    static func table(for family: HighlightFamily) -> [(String, TokenKind)] {
        switch family {
        case .cLike: return cLikeFamily
        case .rubyLike: return rubyLikeFamily
        case .lispLike: return lispLikeFamily
        case .mlLike: return mlLikeFamily
        case .shellLike: return shellLikeFamily
        case .markup: return markupFamily
        case .config: return configFamily
        case .sql: return sqlFamily
        case .tex: return texFamily
        case .data: return dataFamily
        case .plain: return plainFamily
        }
    }
}
