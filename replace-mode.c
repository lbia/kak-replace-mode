#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <regex.h>

/* FILE *file; */

/*
>0 found
=0 not found
<0 error
*/
int
regex_string(const char *const target, const char *const string)
{
    regex_t regex;
    int return_value = -1;
    int reti = regcomp(&regex, target, REG_EXTENDED);
    /* int reti = regcomp(&regex, target, 0); */
    if (reti) {
        fprintf(stderr, "error: could not compile regex\n");
        return_value = -2;
    } else {
        reti = regexec(&regex, string, 0, NULL, 0);
        if (!reti) {
            return_value = 1;
        }
        else if (reti == REG_NOMATCH) {
            return_value = 0;
        }
        else {
            fprintf(stderr, "error: regex match failed\n");
            return_value = -3;
        }
    }
    regfree(&regex);
    return return_value;
}

void
increment_realloc(char **const string, int *const size, int *const index)
{
    (*index)++;
    if (*index >= *size) {
        const int scale_factor = 2;
        *size *= scale_factor;
        *string = (char *)realloc(*string, *size);
    }
}

/*
column_init == 0 expand -t {tabsize}
column_init != 0 expand -t {column_init},+{tabsize}
*/
char *
expand_tab(
    const char *const original,
    const int tabsize,
    const int column_init
) {
    int original_len = strlen(original);
    int expand_len = 2 * original_len;
    char *expand = (char *)malloc(expand_len);
    int o;
    int e;
    for (
        o = 0, e = 0;
        o < original_len;
        o++, increment_realloc(&expand, &expand_len, &e)
    ) {
        if (original[o] != '\t') {
            expand[e] = original[o];
        } else {
            const int current_tab =
                tabsize - (e + tabsize - column_init) % tabsize;
            int space;
            for (space = 0; space < current_tab - 1; space++) {
                expand[e] = ' ';
                increment_realloc(&expand, &expand_len, &e);
            }
            expand[e] = ' ';
        }
    }
    expand[e] = '\0';
    return expand;
}

struct kakoune_options {
    int tabstop;
    int cursor_char_column;
    int difference;

    char *hook_param;
    char *char_selection;
    char *current_line;
    char *previous_line;
};

void
free_kakoune_options(struct kakoune_options *const kakoune)
{
    if (kakoune->hook_param) {
        free(kakoune->hook_param);
    }
    if (kakoune->char_selection) {
        free(kakoune->char_selection);
    }
    if (kakoune->current_line) {
        free(kakoune->current_line);
    }
    if (kakoune->previous_line) {
        free(kakoune->previous_line);
    }
}

void
free_kakoune_exit(
    struct kakoune_options *const kakoune,
    const int exit_status
) {
    free_kakoune_options(kakoune);
    exit(exit_status);
}

void
check_kakoune_not_null(struct kakoune_options *const kakoune)
{
    if (
        kakoune->hook_param == NULL ||
        kakoune->char_selection == NULL ||
        kakoune->current_line == NULL ||
        kakoune->previous_line == NULL
    ) {
        free_kakoune_exit(kakoune, EXIT_FAILURE);
    }
}

void
set_kakoune_string(
    int argc,
    char **argv,
    unsigned int *const i,
    char **const option,
    struct kakoune_options *const kakoune
)
{
    if (*i >= argc) {
        fprintf(stderr, "error: out of bound\n");
        free_kakoune_exit(kakoune, EXIT_FAILURE);
    }
    if (*i + 1 < argc) {
        (*i)++;
        if (*option != NULL) {
            free(*option);
        }
        const char *const param = argv[*i];
        const int len_param = strlen(param);
        if (len_param > 0) {
            *option = malloc(len_param + 1);
            (*option)[len_param] = '\0';
            strcpy(*option, argv[*i]);
        } else {
            *option = NULL;
        }
    } else {
        fprintf(stderr, "error: string %s not specified\n", argv[*i]);
        free_kakoune_exit(kakoune, EXIT_FAILURE);
    }
}

void
set_kakoune_int(
    int argc,
    char **argv,
    unsigned int *const i,
    int *const option,
    struct kakoune_options *const kakoune
)
{
    if (*i >= argc) {
        fprintf(stderr, "error: out of bound\n");
        free_kakoune_exit(kakoune, EXIT_FAILURE);
    }
    if (*i + 1 < argc) {
        (*i)++;
        /* if error strtol return 0 */
        *option = (int)strtol(argv[*i], (char **)NULL, 10);
    } else {
        fprintf(stderr, "error: int %s not specified\n", argv[*i]);
        free_kakoune_exit(kakoune, EXIT_FAILURE);
    }
}

void
print_kakoune_options(FILE *stream, struct kakoune_options *const kakoune)
{
    fprintf(stream, "tabstop:            ");
    if (kakoune->tabstop >= 0) {
        fprintf(stream, "%d", kakoune->tabstop);
    }
    fprintf(stream, "\n");
    fprintf(stream, "cursor-char-column: ");
    if (kakoune->cursor_char_column >= 0) {
        fprintf(stream, "%d", kakoune->cursor_char_column);
    }
    fprintf(stream, "\n");
    fprintf(stream, "difference:         ");
    if (kakoune->difference >= 0) {
        fprintf(stream, "%d", kakoune->difference);
    }
    fprintf(stream, "\n");
    fprintf(stream, "hook-param:         ");
    if (kakoune->hook_param) {
        fprintf(stream, "%s", kakoune->hook_param);
    }
    fprintf(stream, "\n");
    fprintf(stream, "char-selection:     ");
    if (kakoune->char_selection) {
        fprintf(stream, "%s", kakoune->char_selection);
    }
    fprintf(stream, "\n");
    fprintf(stream, "current-line:       ");
    if (kakoune->current_line) {
        fprintf(stream, "%s", kakoune->current_line);
    }
    fprintf(stream, "\n");
    fprintf(stream, "previous-line:      ");
    if (kakoune->previous_line) {
        fprintf(stream, "%s", kakoune->previous_line);
    }
    fprintf(stream, "\n");
}

void
first_operation(struct kakoune_options *const kakoune)
{
    int difference_len = 1;
    if (strcmp(kakoune->hook_param, "<esc>") == 0) {
        printf("\
change-colors-change-mode-true   \n\
set-normal-colors                \n\
remove-hooks window replace-hook \n\
"
    );
        return;
    } else if (regex_string(
        "^<(((a|c)-.)|(backspace)|(del)|(tab))>$",
        kakoune->hook_param
    ) > 0) {
        char *previous_expand = expand_tab(
            kakoune->previous_line,
            kakoune->tabstop,
            0
        );
        const int previous_len = strlen(previous_expand);
        free(previous_expand);
        char *current_expand = expand_tab(
            kakoune->current_line,
            kakoune->tabstop,
            0
        );
        const int current_len = strlen(current_expand);
        free(current_expand);
        difference_len = current_len - previous_len;
    }
    printf("\
set-option window replace_hook_difference %d   \n\
execute-keys -draft 'h<a-h>|expand -t %d<ret>' \n\
",
        difference_len,
        kakoune->tabstop
    );
}

void
second_operation(struct kakoune_options *const kakoune)
{
    if (strcmp(kakoune->hook_param, "<esc>") == 0) {
        return;
    }
    int start;
    if (strcmp(kakoune->char_selection, "\t") == 0) {
        start = kakoune->tabstop - (
            (
                kakoune->cursor_char_column +
                kakoune->tabstop -
                kakoune->difference
            )
            %
            kakoune->tabstop
        );
    } else {
        start = kakoune->tabstop;
    }
    printf("\
try %%{                                                \n\
    execute-keys -draft 's\\n<ret>'                    \n\
} catch %%{                                            \n\
    execute-keys -draft 'l<a-l>|expand -t %d,+%d<ret>' \n\
}                                                      \n\
",
        start,
        kakoune->tabstop
    );
}

void
third_operation(struct kakoune_options *const kakoune)
{
    if (strcmp(kakoune->hook_param, "<esc>") == 0) {
        return;
    }
    int i;
    int tab_len = -1;
    int len_with_tab = 0;
    int len_with_space = 0;
    if (
        strcmp(kakoune->char_selection, "\t") == 0 ||
        regex_string(
            "^<(a|c)-.>$",
            kakoune->hook_param
        ) > 0
    ) {
        len_with_tab = strlen(kakoune->current_line);
        char *current_expand = expand_tab(
            kakoune->current_line,
            kakoune->tabstop,
            0
        );
        len_with_space = strlen(current_expand);
        free(current_expand);
        tab_len = len_with_space - len_with_tab + 1;
    }
    const char *const remove_previous_blank =
        "try %{ execute-keys -draft 'h<a-h>s\\h+\\z<ret>d' }";
    const char *const check_new_line =
        "try %{ execute-keys -draft '<a-x>s\\h+$<ret>d' }";
    const char *const check_prev_line =
        "try %{ execute-keys -draft '<a-l>s\\A\\h+<ret>d' }";
    if (
        regex_string(
            "^<(a|c)-.>$",
            kakoune->hook_param
        ) > 0
    ) {
        if (kakoune->difference > 0) {
            const int line_remaining =
                len_with_tab - kakoune->cursor_char_column;
            const int real_remaining =
                kakoune->difference < line_remaining
                ?
                kakoune->difference
                :
                line_remaining
            ;
            for (i = 0; i < real_remaining; i++) {
                printf("\
%s                                  \n\
try %%{                             \n\
    execute-keys -draft 's\\n<ret>' \n\
} catch %%{                         \n\
    execute-keys -draft 'i<del>'    \n\
}                                   \n\
",
                    check_new_line
                );
            }
            if (tab_len > 1) {
                for (i = 0; i < tab_len - 1; i++) {
                    printf("execute-keys -draft 'a<space>'\n");
                }
            }
        } else if (kakoune->difference < 0) {
            const int number_space = -kakoune->difference - 1;
            const char *const execute_key_start = "ya";
            const char *const execute_key_space = "<space>";
            const char *const execute_key_end = "<esc>pr<space>";
            char *execute_key = (char *)malloc(sizeof(char) * (
                strlen(execute_key_start) +
                number_space * strlen(execute_key_space) +
                strlen(execute_key_end) +
                1
            ));
            execute_key[0] = '\0';
            strcat(execute_key, execute_key_start);
            for (i = 0; i < number_space; i++) {
                strcat(execute_key, execute_key_space);
            }
            strcat(execute_key, execute_key_end);
            printf("\
%s                                       \n\
try %%{                                  \n\
    execute-keys -draft 's\\n<ret>'      \n\
} catch %%{                              \n\
    execute-keys -draft '%s'             \n\
}                                        \n\
",
                check_new_line,
                execute_key
            );
            free(execute_key);
        }
    } else if (strcmp(kakoune->hook_param, "<backspace>") == 0) {
        if (kakoune->difference < 0) {
            for (i = 0; i < -kakoune->difference; i++) {
                printf("execute-keys '<space><left>'\n");
            }
        } else if (kakoune->difference > 0) {
            printf("%s\n", check_prev_line);
        }
    } else if (strcmp(kakoune->hook_param, "<del>") == 0) {
        if (kakoune->difference < 0) {
            for (i = 0; i < -kakoune->difference; i++) {
                printf("execute-keys '<space>'\n");
            }
        } else if (kakoune->difference > 0) {
            printf("%s\n", remove_previous_blank);
        }
    } else if (strcmp(kakoune->hook_param, "<tab>") == 0) {
        for (i = 0; i < kakoune->difference; i++) {
            printf("%s\nexecute-keys '<del>'\n", check_new_line);
        }
        if (tab_len > 1) {
            for (i = 0; i < tab_len - 1; i++) {
                printf("execute-keys '<space>'\n");
            }
        }
    } else {
        printf("%s\nexecute-keys '<del>'\n", check_new_line);
        if (tab_len >= 1 && tab_len < kakoune->tabstop) {
            for (i = 0; i < tab_len; i++) {
                printf("execute-keys '<space>'\n");
            }
        }
    }
}

int
main (int argc, char **argv)
{
    unsigned int i;
    unsigned int operation;

    struct kakoune_options kakoune = {
        -1,
        -1,
        -1,
        NULL,
        NULL,
        NULL,
        NULL,
    };

    /*
    const char *const home_env = getenv("HOME");
    if (!home_env) {
        fprintf(stderr, "HOME not set\n");
        free_kakoune_exit(&kakoune, EXIT_FAILURE);
    }
    const char *relative_file = "/replace-mode-c-out";
    char *file_path = (char *)malloc(sizeof(char) * (
        strlen(home_env) + strlen(relative_file) + 1
    ));
    file_path[0] = '\0';
    strcat(file_path, home_env);
    strcat(file_path, relative_file);
    file = fopen(file_path, "w");
    free(file_path);
    */

    operation = 0;
    for (i = 1; i < argc; i++) {
        const char *const param = argv[i];
        if (strcmp(param, "-1") == 0) {
            operation = 1;
        } else if (strcmp(param, "-2") == 0) {
            operation = 2;
        } else if (strcmp(param, "-3") == 0) {
            operation = 3;
        } else if (strcmp(param, "--tabstop") == 0) {
            set_kakoune_int(
                argc, argv, &i, &kakoune.tabstop, &kakoune
            );
        } else if (strcmp(param, "--cursor-char-column") == 0) {
            set_kakoune_int(
                argc, argv, &i, &kakoune.cursor_char_column, &kakoune
            );
        } else if (strcmp(param, "--difference") == 0) {
            set_kakoune_int(
                argc, argv, &i, &kakoune.difference, &kakoune
            );
        } else if (strcmp(param, "--hook-param") == 0) {
            set_kakoune_string(
                argc, argv, &i, &kakoune.hook_param, &kakoune
            );
        } else if (strcmp(param, "--char-selection") == 0) {
            set_kakoune_string(
                argc, argv, &i, &kakoune.char_selection, &kakoune
            );
        } else if (strcmp(param, "--current-line") == 0) {
            set_kakoune_string(
                argc, argv, &i, &kakoune.current_line, &kakoune
            );
        } else if (strcmp(param, "--previous-line") == 0) {
            set_kakoune_string(
                argc, argv, &i, &kakoune.previous_line, &kakoune
            );
        } else {
            fprintf(stderr, "error: %s not recognized\n", param);
            free_kakoune_exit(&kakoune, EXIT_FAILURE);
        }
    }
    /* print_kakoune_options(file, &kakoune); */
    /* fclose(file); */
    check_kakoune_not_null(&kakoune);
    switch (operation) {
        case 1:
            first_operation(&kakoune);
            break;
        case 2:
            second_operation(&kakoune);
            break;
        case 3:
            third_operation(&kakoune);
            break;
        default:
            fprintf(stderr, "error: no operation specified\n");
            free_kakoune_exit(&kakoune, EXIT_FAILURE);
    }
    free_kakoune_exit(&kakoune, EXIT_SUCCESS);
    /* make compiler happy */
    return EXIT_SUCCESS;
}
