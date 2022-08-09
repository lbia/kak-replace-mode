## replace-mode-c.kak

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
    nop %sh{
        replace_mode_bin="$kak_opt_replace_mode_path/replace-mode"
        if [ ! -f "$replace_mode_bin" ]; then
            make -C "$kak_opt_replace_mode_path"
        fi
    }
    hook -group replace-hook window InsertKey .* %{
        update-replace-hook-curr-line
        evaluate-commands %sh{
            "$kak_opt_replace_mode_path/replace-mode" -1 \
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
            "$kak_opt_replace_mode_path/replace-mode" -2 \
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
            "$kak_opt_replace_mode_path/replace-mode" -3 \
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
