; Sidewatch: a shell-form command (`RUN apt-get …`, `CMD echo …`) and the lines of a heredoc (`RUN <<EOT`) are bash.
; The host parses each match as its own document (`separateInjections`), so one command never runs into the next.
; A heredoc is captured by its first and last lines; the document spans them. A command that only opens heredocs
; (`RUN <<EOT bash -ex`, `RUN python3 <<PY`) stays the instruction's own: bash would read its `<<EOT` as a heredoc
; whose body is missing.
((shell_command) @injection.content
  (#not-match? @injection.content "<<")
  (#set! injection.language "bash"))

((run_instruction
  (shell_command) @_command
  (heredoc_block . (heredoc_line) @injection.content (heredoc_line)? @injection.content . (heredoc_end)))
  (#not-match? @_command "^\\s*python")
  (#set! injection.language "bash"))

; `RUN python3 <<PY` feeds the heredoc to Python.
((run_instruction
  (shell_command) @_command
  (heredoc_block . (heredoc_line) @injection.content (heredoc_line)? @injection.content . (heredoc_end)))
  (#match? @_command "^\\s*python")
  (#set! injection.language "python"))
