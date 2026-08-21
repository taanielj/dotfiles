# pbcopy/pbpaste everywhere: native on macOS, clip.exe/powershell on WSL,
# wl-clipboard or xclip on other Linux. Aliases and functions can just call pbcopy.
if ! command -v pbcopy >/dev/null 2>&1; then
    if command -v clip.exe >/dev/null 2>&1; then
        pbcopy() { clip.exe; }
        pbpaste() { powershell.exe -NoProfile -Command Get-Clipboard | tr -d '\r'; }
    elif command -v wl-copy >/dev/null 2>&1; then
        pbcopy() { wl-copy; }
        pbpaste() { wl-paste --no-newline; }
    elif command -v xclip >/dev/null 2>&1; then
        pbcopy() { xclip -selection clipboard; }
        pbpaste() { xclip -selection clipboard -o; }
    fi
fi
