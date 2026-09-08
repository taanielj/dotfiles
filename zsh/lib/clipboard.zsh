# pbcopy/pbpaste everywhere: native on macOS, win32yank on WSL (installed by
# setup/win32yank.sh), wl-clipboard or xclip on other Linux.
# Aliases and functions can just call pbcopy.
if ! command -v pbcopy >/dev/null 2>&1; then
    if command -v win32yank.exe >/dev/null 2>&1; then
        pbcopy() { win32yank.exe -i --crlf; }
        pbpaste() { win32yank.exe -o --lf; }
    elif command -v wl-copy >/dev/null 2>&1; then
        pbcopy() { wl-copy; }
        pbpaste() { wl-paste --no-newline; }
    elif command -v xclip >/dev/null 2>&1; then
        pbcopy() { xclip -selection clipboard; }
        pbpaste() { xclip -selection clipboard -o; }
    fi
fi
