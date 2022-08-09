## replace-mode-sh.kak

evaluate-commands %sh{
    if [ -z "$kak_opt_replace_mode_path" ]; then
        replace_mode_path="${kak_config:-$HOME/.config/kak}/plugins/kak-replace-mode"
        printf "%s" "
            declare-option -hidden str replace_mode_path
            set-option global replace_mode_path ${replace_mode_path}
        "
    else
        replace_mode_path="$kak_opt_replace_mode_path"
    fi
    printf "%s" "
        try %{
            source %{$replace_mode_path/rc/replace-mode.kak}
        } catch %{
            echo -debug %val{error}
        }
    "
}

define-command add-replace-hook -docstring "add replace hook" %{
    change-colors-change-mode-false
    set-replace-colors
    update-replace-hook-char
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
