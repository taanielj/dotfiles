# ANSI colors
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
WHITE='\033[1;37m'
RESET='\033[0m'

log() {
    if [[ "$1" == "-n" ]]; then
        shift
        echo -ne "${BLUE}$*${RESET}"
    else
        echo -e "${BLUE}$*${RESET}"
    fi
}
warn() {
    echo -e "${ORANGE}$*${RESET}"
}
error() {
    echo -e "${RED}$*${RESET}"
}
success() {
    echo "${GREEN}$*${RESET}"
}
