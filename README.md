# kak-replace-mode

[kakoune](https://github.com/mawww/kakoune)
plugin that adds a vim-style replace mode

inspired from
[tomKPZ/replace-mode.kak](https://github.com/tomKPZ/replace-mode.kak)

implemented both in posix sh and ansi c

similar to fisical insert key in other programs and vim replace-mode

all done inside insert mode so there are all the key bindings and
completions

sometimes a bit slow (if a key is held down), even the implementation in c

(the slow part is on the kakoune side, in the sense that obviously
executing kakoune commands is slower than a native implementation)

when in single selection should function "perfectly" in the sense that the
line should always remain the same lenght even with tabs, tabs in strange
places, moving through completion menu etc (if not there is some bug)

obviously not when the cursor reaches the start of the line
so it is put at the end of the previous line or when it reaches the end
of the current line so the next line is appent to it

in this two cases there are checks that remove spaces/tabs in order
to prevent wrapping

when in multiple selection without tabs should also function "perfectly"

when in multiple selection with tabs all the lines may not remain
always the same lenght

### installation

clone this repository into a folder (possibly inside kakoune config folder)
```
git clone https://git.lbia.xyz/kak-replace-mode.git
```
by default `$kak_config/plugin/kak-replace-mode`

you need a c89(ansi)-compatible c compiler

the plugin will build the program automatically if it is not already
built when needed

if you want to build it manually instead run `make`

if you choose another directory you have to specify it in your kakrc:
```
declare-option -hidden str replace_mode_path
set-option global replace_mode_path "directory"
```
then source one between `replace-mode-c.kak` and `replace-mode-sh.kak`:
```
evaluate-commands %sh{
    printf "%s" "
        try %{
            source %{$replace_mode_path/rc/replace-mode-c.kak}
            # or
            source %{$replace_mode_path/rc/replace-mode-sh.kak}
        } catch %{
            echo -debug %val{error}
        }
    "
}
```
or simply link `replace-mode-c.kak` or `replace-mode-sh.kak` to
`~/.config/kak/autoload`

otherwise if using [plug.kak](https://github.com/andreyorst/plug.kak):
```
plug "https://git.lbia.xyz/kak-replace-mode.git"
```
