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
            case "$kak_hook_param" in
                \<esc\>)
                    # removing hook does not remove the current one
                    # find way to exit from hook
                    echo "change-colors-change-mode-true"
                    echo "set-normal-colors"
                    echo "remove-hooks window replace-hook"
                    exit
                ;;
                \<c-*\>|\<a-*\>|\<backspace\>|\<del\>|\<tab\>)
                    prev_len="$(
                        printf "%s" \
                            "$kak_opt_replace_hook_prev_line" |
                        expand -t "$kak_opt_tabstop" |
                        wc -m
                    )"
                    curr_len="$(
                        printf "%s" \
                            "$kak_opt_replace_hook_curr_line" |
                        expand -t "$kak_opt_tabstop" |
                        wc -m
                    )"
                    difference_len="$(( curr_len - prev_len ))"
                ;;
            esac
            if [ -n "$difference_len" ]; then
                echo "set-option window replace_hook_difference $difference_len"
            else
                echo "set-option window replace_hook_difference 1"
            fi
            # we expand to the left and to the right but not all line
            # otherwise kak losees the cursor
            # (it is placed at the start of the next line)
            cat << EOF
execute-keys -draft 'h<a-h>|expand -t ${kak_opt_tabstop}<ret>'
EOF
        }
        update-replace-hook-char
        evaluate-commands %sh{
            if [ "$kak_hook_param" = "<esc>" ]; then
                exit
            fi
            if [ "$kak_opt_replace_hook_char" != "$(printf "\t")" ]; then
                 start="$((
                    kak_opt_tabstop - ((kak_cursor_char_column + kak_opt_tabstop - kak_opt_replace_hook_difference) % kak_opt_tabstop)
                ))"
            else
                start="$kak_opt_tabstop"
            fi
            cat << EOF
try %{
    execute-keys -draft 's\n<ret>'
} catch %{
    execute-keys -draft 'l<a-l>|expand -t ${start},+${kak_opt_tabstop}<ret>'
}
EOF
        }
        update-replace-hook-curr-line
        evaluate-commands %sh{
            if [ "$kak_hook_param" = "<esc>" ]; then
                exit
            fi
            calculate_line_length=false
            if [ "$kak_opt_replace_hook_char" = "$(printf "\t")" ]; then
                calculate_line_length=true
            else
                case "$kak_hook_param" in
                    \<c-*\>|\<a-*\>)
                        calculate_line_length=true
                    ;;
                esac
            fi
            if [ "$calculate_line_length" = true ]; then
                len_with_tab="$(
                    printf "%s" \
                       "$kak_opt_replace_hook_curr_line" |
                    wc -m
                )"
                len_with_space="$(
                    printf "%s" \
                        "$kak_opt_replace_hook_curr_line" |
                    expand -t "$kak_opt_tabstop" |
                    wc -m
                )"
                tab_len="$(( len_with_space - len_with_tab + 1 ))"
            else
                tab_len="-1"
            fi
            remove_previous_blank="try %{ execute-keys -draft 'h<a-h>s\h+\z<ret>d' }"
            check_new_line="try %{ execute-keys -draft '<a-x>s\h+$<ret>d' }"
            check_prev_line="try %{ execute-keys -draft '<a-l>s\A\h+<ret>d' }"
            case "$kak_hook_param" in
                \<c-*\>|\<a-*\>)
                    # rare problem when difference is greater than 0
                    # we are not checking if it is the previous line
                    if [ "$kak_opt_replace_hook_difference" -gt 0 ]; then
                        line_remaining="$(( len_with_tab - kak_cursor_char_column ))"
                        for __ in $(seq 1 "$((
                                kak_opt_replace_hook_difference <
                                line_remaining ?
                                kak_opt_replace_hook_difference :
                                line_remaining
                            ))"); do
                            echo "$check_new_line"
                            cat << EOF
try %{
    execute-keys -draft 's\n<ret>'
} catch %{
    execute-keys -draft 'i<del>'
}
EOF
                        done
                        # extremely rare case: when you are on tab
                        # usually there are no completions
                        # not really tested since i do not really know
                        # how to test it
                        if [ "$tab_len" -gt 1 ]; then
                            for __ in $(seq 1 "$(( tab_len - 1 ))"); do
                                echo "execute-keys -draft 'a<space>'"
                            done
                        fi
                    elif [ "$kak_opt_replace_hook_difference" -lt 0 ]; then
                        echo "$check_new_line"
                        # if the cursor was on a letter different from
                        # <space> before key press then the cursor will
                        # end one key right from the completions (they are
                        # all spaces nevertheless since difference is less
                        # than zero) because if at the end of a draft key
                        # execution the key under the cursor is different
                        # from the previous one kak put the cursor one
                        # place to the right for some reason
                        execute_key="ya"
                        for __ in $(seq 1 "$(( - kak_opt_replace_hook_difference - 1 ))"); do
                            execute_key="${execute_key}<space>"
                        done
                        execute_key="${execute_key}<esc>p"
                        cat << EOF
try %{
    execute-keys -draft 's\n<ret>'
} catch %{
    execute-keys -draft '${execute_key}'
    execute-keys -draft 'r<space>'
}
EOF
                    fi
                ;;
                \<backspace\>)
                    if [ "$kak_opt_replace_hook_difference" -lt 0 ]; then
                        for __ in $(seq 1 "$(( - kak_opt_replace_hook_difference ))"); do
                            echo "execute-keys '<space><left>'"
                        done
                    elif [ "$kak_opt_replace_hook_difference" -gt 0 ]; then
                        echo "$check_prev_line"
                    fi
                ;;
                \<del\>)
                    if [ "$kak_opt_replace_hook_difference" -lt 0 ]; then
                        for __ in $(seq 1 "$(( - kak_opt_replace_hook_difference ))"); do
                            echo "execute-keys '<space>'"
                        done
                    elif [ "$kak_opt_replace_hook_difference" -gt 0 ]; then
                        echo "$remove_previous_blank"
                    fi
                ;;
                \<tab\>)
                    for __ in $(seq 1 "$kak_opt_replace_hook_difference"); do
                        echo "$check_new_line"
                        echo "execute-keys '<del>'"
                    done
                    if [ "$tab_len" -gt 1 ]; then
                        for __ in $(seq 1 "$(( tab_len - 1 ))"); do
                            echo "execute-keys '<space>'"
                        done
                    fi
                ;;
                *)
                    echo "$check_new_line"
                    echo "execute-keys '<del>'"
                    if [ "$tab_len" -ge 1 ] && [ "$tab_len" -lt "$kak_opt_tabstop" ]; then
                        for __ in $(seq 1 "$tab_len"); do
                            echo "execute-keys '<space>'"
                        done
                    fi
                ;;
            esac
        }
        update-replace-hook-prev-line
    }
}
