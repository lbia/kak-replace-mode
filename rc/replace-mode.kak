## replace-mode.kak

# inspiration from https://github.com/tomKPZ/replace-mode.kak

# replace mode implemented both in posix sh and ansi c
# similar to fisical insert key in other programs and vim replace-mode
# all done inside insert mode so there are all the key bindings and
# completions
# sometimes a bit slow (if a key is held down), even the implementation in c
# (the slow part is on the kakoune side, in the sense that obviously
# executing kakoune commands is slower than a native implementation)
# when in single selection should function "perfectly" in the sense that the
# line should always remain the same lenght even with tabs, tabs in strange
# places, moving through completion menu etc (if not there is some bug)
# obviously not when the cursor reaches the start of the line
# so it is put at the end of the previous line or when it reaches the end
# of the current line so the next line is appent to it
# in this two cases there are checks that remove spaces/tabs in order
# to prevent wrapping
# when in multiple selection without tabs should also function "perfectly"
# when in multiple selection with tabs all the lines may not remain
# always the same lenght

define-command set-normal-colors -docstring "set normal colors" %{
    unset-face window PrimarySelection
    unset-face window SecondarySelection
    unset-face window PrimaryCursor
    unset-face window SecondaryCursor
    unset-face window PrimaryCursorEol
    unset-face window SecondaryCursorEol
}

define-command set-insert-colors -docstring "set insert colors" %{
    set-face window PrimarySelection        white,green+g
    set-face window SecondarySelection      black,green+g
    set-face window PrimaryCursor           black,yellow+fg
    set-face window SecondaryCursor         black,green+fg
    set-face window PrimaryCursorEol        black,yellow
    set-face window SecondaryCursorEol      black,green
}

define-command set-replace-colors -docstring "set replace colors" %{
    set-face window PrimarySelection        white,bright-green+g
    set-face window SecondarySelection      black,bright-green+g
    set-face window PrimaryCursor           black,bright-red+fg
    set-face window SecondaryCursor         black,bright-green+fg
    set-face window PrimaryCursorEol        black,bright-red
    set-face window SecondaryCursorEol      black,bright-green
}

define-command change-colors-change-mode-true -docstring "change colors when changing mode" %{
    # set insert color when entering insert mode
    hook -group change-colors global ModeChange (push|pop):.*:insert %{
        set-insert-colors
    }

    # undo colour changes when leaving insert mode
    hook -group change-colors global ModeChange (push|pop):insert:.* %{
        set-normal-colors
    }
}
define-command change-colors-change-mode-false -docstring "do not change colors when changing mode" %{
    remove-hooks global change-colors
}

# this options do not behave perfectly with multiple selection
# since every selection update the same setting
declare-option -hidden str replace_hook_char
define-command -hidden update-replace-hook-char %{
    evaluate-commands -draft -itersel %{
        set-option window replace_hook_char %reg{dot}
    }
}
declare-option -hidden str replace_hook_prev_line
define-command -hidden update-replace-hook-prev-line %{
    evaluate-commands -draft -itersel %{
        execute-keys <a-x>
        set-option window replace_hook_prev_line %reg{dot}
    }
}
declare-option -hidden str replace_hook_curr_line
define-command -hidden update-replace-hook-curr-line %{
    evaluate-commands -draft -itersel %{
        execute-keys <a-x>
        set-option window replace_hook_curr_line %reg{dot}
    }
}
declare-option -hidden int replace_hook_difference
