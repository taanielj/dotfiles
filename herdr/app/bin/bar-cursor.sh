#!/bin/sh
# Runs a program with a bar cursor. Herdr app terminals start with a block cursor,
# and only zsh's prompt (zsh/zshrc.zsh) sets the bar.
# Usage: bar-cursor.sh <program> [args...]
printf '\033[5 q'
exec "$@"
