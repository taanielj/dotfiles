# setup/herdr.sh links the scripts in this directory onto PATH. Each script
# sources this file through its resolved link:
#   source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib.sh"

# Prints each running nvim's server socket, one per line.
nvim_servers() {
    local socket
    for socket in "${TMPDIR:-/tmp}"/nvim."$USER"/*/nvim.*.0; do
        [[ -S "$socket" ]] && printf '%s\n' "$socket"
    done
}

# Usage: nvim_env <socket> <variable>
# Prints the variable as the nvim behind the socket has it.
nvim_env() {
    nvim --clean --headless --server "$1" --remote-expr "\$$2" 2>/dev/null
}
