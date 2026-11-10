# Sourced by the scripts in this directory, through the links setup puts on PATH:
#   source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib.sh"

# Usage: nvim_servers
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
