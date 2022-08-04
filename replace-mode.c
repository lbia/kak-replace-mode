#include <stdio.h>
#include <string.h>

/* EXIT_SUCCESS EXIT_FAILURE strtol strtoll */
#include <stdlib.h>

/* setlocale */
/* #include <locale.h> */

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
free_kakoune_options(struct kakoune_options *kakoune)
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
set_kakoune_string(
    int argc,
    char *argv[],
    unsigned int *i,
    char **option,
    struct kakoune_options *kakoune
)
{
    if (*i >= argc) {
        fprintf(stderr, "error: out of bound\n");
        free_kakoune_options(kakoune);
        exit(EXIT_FAILURE);
    }
    char *param = argv[*i];
    if (*i + 1 < argc) {
        (*i)++;
        int len_param = strlen(param);
        *option = malloc(len_param + 1);
        (*option)[len_param] = '\0';
        strcpy(*option, argv[*i]);
    } else {
        fprintf(stderr, "error: string %s not specified\n", param);
        free_kakoune_options(kakoune);
        exit(EXIT_FAILURE);
    }
}

void
set_kakoune_int(
    int argc,
    char *argv[],
    unsigned int *i,
    int *option,
    struct kakoune_options *kakoune
)
{
    if (*i >= argc) {
        fprintf(stderr, "error: out of bound\n");
        free_kakoune_options(kakoune);
        exit(EXIT_FAILURE);
    }
    if (*i + 1 < argc) {
        (*i)++;
        /* if error strtol return 0 */
        *option = (int) strtol(argv[*i], (char **)NULL, 10);
    } else {
        fprintf(stderr, "error: int %s not specified\n", argv[*i]);
        free_kakoune_options(kakoune);
        exit(EXIT_FAILURE);
    }
}

void
print_kakoune_options(struct kakoune_options *kakoune)
{
    printf("tabstop:            ");
    if (kakoune->tabstop >= 0) {
        printf("%d", kakoune->tabstop);
    }
    printf("\n");
    printf("cursor-char-column: ");
    if (kakoune->cursor_char_column >= 0) {
        printf("%d", kakoune->cursor_char_column);
    }
    printf("\n");
    printf("difference:         ");
    if (kakoune->difference >= 0) {
        printf("%d", kakoune->difference);
    }
    printf("\n");
    printf("hook-param:         ");
    if (kakoune->hook_param) {
        printf("%s", kakoune->hook_param);
    }
    printf("\n");
    printf("char-selection:     ");
    if (kakoune->char_selection) {
        printf("%s", kakoune->char_selection);
    }
    printf("\n");
    printf("current-line:       ");
    if (kakoune->current_line) {
        printf("%s", kakoune->current_line);
    }
    printf("\n");
    printf("previous-line:      ");
    if (kakoune->previous_line) {
        printf("%s", kakoune->previous_line);
    }
    printf("\n");
}

void
first_operation(struct kakoune_options *kakoune)
{
    printf("starting first operation\n");
}

void
second_operation(struct kakoune_options *kakoune)
{
    printf("starting second operation\n");
}

void
third_operation(struct kakoune_options *kakoune)
{
    printf("starting third operation\n");
}

int main (int argc, char *argv[])
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

    operation = 0;
    for (i = 1; i < argc; i++) {
        char *param = argv[i];
        if (strcmp(param, "-1") == 0) {
            operation = 1;
        } else if (strcmp(param, "-2") == 0) {
            operation = 2;
        } else if (strcmp(param, "-3") == 0) {
            operation = 3;
        } else if (strcmp(param, "--tabstop") == 0) {
            set_kakoune_int(argc, argv, &i, &kakoune.tabstop, &kakoune);
        } else if (strcmp(param, "--cursor-char-column") == 0) {
            set_kakoune_int(argc, argv, &i, &kakoune.cursor_char_column, &kakoune);
        } else if (strcmp(param, "--difference") == 0) {
            set_kakoune_int(argc, argv, &i, &kakoune.difference, &kakoune);
        } else if (strcmp(param, "--hook-param") == 0) {
            set_kakoune_string(argc, argv, &i, &kakoune.hook_param, &kakoune);
        } else if (strcmp(param, "--char-selection") == 0) {
            set_kakoune_string(argc, argv, &i, &kakoune.char_selection, &kakoune);
        } else if (strcmp(param, "--current-line") == 0) {
            set_kakoune_string(argc, argv, &i, &kakoune.current_line, &kakoune);
        } else if (strcmp(param, "--previous-line") == 0) {
            set_kakoune_string(argc, argv, &i, &kakoune.previous_line, &kakoune);
        } else {
            fprintf(stderr, "error: %s not recognized\n", param);
            free_kakoune_options(&kakoune);
            return EXIT_FAILURE;
        }
    }
    print_kakoune_options(&kakoune);
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
            free_kakoune_options(&kakoune);
            return EXIT_FAILURE;
    }
    free_kakoune_options(&kakoune);
    return EXIT_SUCCESS;
}
