## replace-mode.kak

# inspiration from https://github.com/tomKPZ/replace-mode.kak

# replace mode, similar to fisical insert key in other programs
# all done inside insert mode so there are all key bindings and completions
# sometimes a bit slow, should rewrite in c
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

declare-option -hidden str replace_mode_bin_path
evaluate-commands %sh{
    replace_mode_bin_path="${kak_config:-$HOME/.config/kak}/plugins/replace-mode.kak/replace-mode"
    printf "%s" "
        set-option global replace_mode_bin_path ${replace_mode_bin_path}
    "
}

# this options do not behave perfectly with multiple selection
# since every selection update the same setting
declare-option -hidden str replace_hook_char
define-command -hidden update-replace-hook-char %{
    evaluate-commands -draft -itersel %{
        execute-keys <esc>
        set-option window replace_hook_char %reg{dot}
    }
}
declare-option -hidden str replace_hook_prev_line
define-command -hidden update-replace-hook-prev-line %{
    evaluate-commands -draft -itersel %{
        execute-keys <esc><a-x>
        set-option window replace_hook_prev_line %reg{dot}
    }
}
declare-option -hidden str replace_hook_curr_line
define-command -hidden update-replace-hook-curr-line %{
    evaluate-commands -draft -itersel %{
        execute-keys <esc><a-x>
        set-option window replace_hook_curr_line %reg{dot}
    }
}

declare-option -hidden int replace_hook_difference
define-command add-replace-hook -docstring "add replace hook" %{
    change-colors-change-mode-false
    set-replace-colors
    update-replace-hook-prev-line
    hook -group replace-hook window InsertKey .* %{
        update-replace-hook-curr-line
        evaluate-commands %sh{
            $replace_mode_bin_path -1 \
                --tabstop "$kak_opt_tabstop" \
                --cursor-char-column "$kak_cursor_char_column" \
                --difference "$kak_opt_replace_hook_difference" \
                --hook-param "$kak_hook_param" \
                --char-selection "$kak_opt_replace_hook_char" \
                --current-line "$kak_opt_replace_hook_curr_line" \
                --previous-line "$kak_opt_replace_hook_prev_line"
        }
        update-replace-hook-char
        evaluate-commands %sh{
            $replace_mode_bin_path -2 \
                --tabstop "$kak_opt_tabstop" \
                --cursor-char-column "$kak_cursor_char_column" \
                --difference "$kak_opt_replace_hook_difference" \
                --hook-param "$kak_hook_param" \
                --char-selection "$kak_opt_replace_hook_char" \
                --current-line "$kak_opt_replace_hook_curr_line" \
                --previous-line "$kak_opt_replace_hook_prev_line"
        }
        update-replace-hook-curr-line
        evaluate-commands %sh{
            $replace_mode_bin_path -3 \
                --tabstop "$kak_opt_tabstop" \
                --cursor-char-column "$kak_cursor_char_column" \
                --difference "$kak_opt_replace_hook_difference" \
                --hook-param "$kak_hook_param" \
                --char-selection "$kak_opt_replace_hook_char" \
                --current-line "$kak_opt_replace_hook_curr_line" \
                --previous-line "$kak_opt_replace_hook_prev_line"
        }
        update-replace-hook-prev-line
    }
}
