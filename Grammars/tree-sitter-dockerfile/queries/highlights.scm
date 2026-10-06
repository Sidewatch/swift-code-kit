[
	"FROM"
	"AS"
	"RUN"
	"CMD"
	"LABEL"
	"EXPOSE"
	"ENV"
	"ADD"
	"COPY"
	"ENTRYPOINT"
	"VOLUME"
	"USER"
	"WORKDIR"
	"ARG"
	"ONBUILD"
	"STOPSIGNAL"
	"HEALTHCHECK"
	"SHELL"
	"MAINTAINER"
	"CROSS_BUILD"
	(heredoc_marker)
	(heredoc_end)
] @keyword

[
	":"
	"@"
] @operator

(comment) @comment


(image_spec
	(image_tag
		":" @punctuation.special)
	(image_digest
		"@" @punctuation.special))

[
	(double_quoted_string)
	(single_quoted_string)
	(json_string)
	(heredoc_line)
] @string

(expansion
  [
	"$"
	"{"
	"}"
  ] @punctuation.special
) @none

((variable) @constant
 (#match? @constant "^[A-Z][A-Z_0-9]*$"))



; Sidewatch: a heredoc's lines are plain text (VS Code paints them plain, not as a string); a whole-line comment in
; one (`#!/bin/sh` opening a `RUN <<EOT` script) is a comment.
(heredoc_line) @plain
((heredoc_line) @comment
  (#match? @comment "^[ \t]*#"))
; A backslash escape in an unquoted value (`two\ words`, `\$NOT_EXPANDED`) is quoted text.
(unquoted_string
  (escape_sequence) @string)
