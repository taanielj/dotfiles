__check_python_env() {
    # Set preferred Python version/command
    declare -a python_versions=(
        "python3.12"
        "python3.11"
        "python3.10"
        "python3.9"
        "python3.8"
        "python3.7"
        "python3.6"
        "python3"
        "python"
    )

    for version in "${python_versions[@]}"; do
        if command -v "$version" &>/dev/null; then
            PYTHON_EXEC="$version"
            break
        fi
    done

    if [[ -z "$PYTHON_EXEC" ]]; then
        echo "No Python executable found. Please install Python."
        return 1
    else
        export PYTHON_EXEC
    fi

    # Check for pip
    if ! $PYTHON_EXEC -m pip -V &>/dev/null; then
        echo "pip not found. Installing pip..."
        if ! $PYTHON_EXEC -m ensurepip &>/dev/null; then
            echo "Failed to install pip. Please install pip manually."
            return 1
        fi
        $PYTHON_EXEC -m pip install --upgrade pip
    fi

    # Check for venv
    if $PYTHON_EXEC -m venv --help &>/dev/null; then
        export VENV_MODULE="venv"
    elif $PYTHON_EXEC -m virtualenv --help &>/dev/null; then
        export VENV_MODULE="virtualenv"
    else
        echo "Warning: venv or virtualenv not found. Installing virtualenv..."
        if ! $PYTHON_EXEC -m pip install virtualenv &>/dev/null; then
            echo "Failed to install virtualenv. Please install a virtual environment manager manually."
            return 1
        fi
    fi
}

__resolve_venv_path() {
    local venv_dir="${1:-$VIRTUAL_ENV}"

    # If no explicit name or $VIRTUAL_ENV is not set, try to find a common venv directory
    if [[ -z "$venv_dir" ]]; then
        for dir in ".venv" "venv" "env"; do
            if [[ -d "$dir" ]]; then
                venv_dir="$dir"
                break
            fi
        done
    fi

    venv_dir="${venv_dir:-.venv}" # Default to .venv if nothing found

    # If the path is already absolute, return it
    if [[ "$venv_dir" == /* ]]; then
        echo "$venv_dir"
        return
    fi

    # If the directory exists, get its absolute path
    if [[ -d "$venv_dir" ]]; then
        (cd "$venv_dir" && pwd)
    else
        # If the directory doesn't exist, construct the absolute path manually
        echo "$(pwd)/$venv_dir"
    fi
}

__confirm_action() {
    local prompt="$1"
    echo "$prompt (y/n)"
    read -r input
    input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    [[ "$input" == "y" ]]
}

__require_venv() {
    if [[ -z "$VIRTUAL_ENV" ]]; then
        echo "Not in a virtual environment. Run 'venv' to create one or activate an existing one."
        return 1
    fi
}

__require_reqs() {
    if [[ ! -f "requirements.txt" || ! -s "requirements.txt" ]]; then
        echo "No requirements.txt file found or empty."
        return 1
    fi
}

venv() {
    if [[ -n "$VIRTUAL_ENV" && -x "$VIRTUAL_ENV/bin/python" ]]; then
        echo "Virtual environment already activated: $VIRTUAL_ENV"
        echo "Options: rm_venv to remove, reset_venv to recreate, deactivate to close venv."
        return
    fi

    __check_python_env || return 1

    local venv_path
    venv_path=$(__resolve_venv_path "$1")

    # Activate existing virtual environment if found
    if [[ -d "$venv_path" ]]; then
        source "$venv_path/bin/activate"
        echo "Virtual environment activated: $VIRTUAL_ENV"
        return
    fi

    echo "Creating a new virtual environment in $venv_path..."
    $PYTHON_EXEC -m $VENV_MODULE "$venv_path"
    source "$venv_path/bin/activate"
    python -m pip install --upgrade pip
    echo "Virtual environment created and activated: $VIRTUAL_ENV"

    if __require_reqs &>/dev/null; then
        if __confirm_action "Would you like to install the requirements?"; then
            reqs
        fi
    fi
}

rm_venv() {
    local venv_path
    venv_path=$(__resolve_venv_path "$1")

    if [[ -z "$venv_path" || ! -d "$venv_path" ]]; then
        echo "No virtual environment found."
        return
    fi

    if ! __confirm_action "Are you sure you want to remove the virtual environment at '$venv_path'?"; then
        return
    fi

    [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$venv_path" ]] && deactivate
    rm -rf "$venv_path"
    echo "Virtual environment removed: $venv_path"
}

reset_venv() {
    local venv_path
    venv_path=$(__resolve_venv_path "$1")

    if [[ -z "$venv_path" || ! -d "$venv_path" ]]; then
        echo "No virtual environment found to reset."
        return
    fi

    if ! __confirm_action "Are you sure you want to reset the virtual environment at '$venv_path'?"; then
        return
    fi

    [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$venv_path" ]] && deactivate
    rm -rf "$venv_path"
    venv "$venv_path"
}

reqs() {
    __require_reqs || return 1
    __require_venv || return 1
    pip install --upgrade -r requirements.txt
    echo "Requirements installed, run 'update_reqs' to update to latest and freeze versions."
}

update_reqs() {
    __require_reqs || return 1
    __require_venv || return 1
    if ! __confirm_action "This will update all packages to latest and freeze versions. Continue?"; then
        return
    fi

    # Step 1: Strip version numbers from requirements.txt in-place
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' -E 's/(==[^#[:space:]]+)//' requirements.txt  # handles extras better
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sed -i -E 's/(==[^#[:space:]]+)//' requirements.txt
    else
        echo "Unsupported OS type: $OSTYPE"
        return 1
    fi

    # Step 2: Update pip and install the latest versions of packages from requirements.txt
    python -m pip install --upgrade pip
    python -m pip install --upgrade -r requirements.txt

    # Step 3: Get the installed package versions from pip freeze
    frozen_reqs=$(pip freeze)

    # Step 4: Add version numbers back in-place, preserving comments and blank lines
    while IFS= read -r line; do
        if [[ -z "$line" || "$line" =~ ^# ]]; then
            # Preserve empty lines and comments as is
            echo "$line"
        else
            base_req=$(echo "$line" | sed 's/\[.*\]//') # Strip extras to match pip freeze
            # Perform a case-insensitive match against pip freeze
            frozen_line=$(echo "$frozen_reqs" | grep -i -m 1 "^${base_req}==")
            if [[ -n $frozen_line ]]; then
                # Append the version to the existing line
                echo "${line}==${frozen_line##*==}" # Extract and append version
            else
                # If no version is found, keep the line unchanged
                echo "$line"
            fi
        fi
    done <requirements.txt >requirements.tmp

    # Replace the old requirements.txt with the updated file
    mv requirements.tmp requirements.txt
    # if venv then resource
    if [[ -n "$VIRTUAL_ENV" ]]; then
        source "$VIRTUAL_ENV/bin/activate"
    fi
}


pipr() {
    [[ $# -eq 0 ]] && {
        echo "Usage: pipr <package...>"
        return 1
    }

    local reqfile="requirements.txt"
    [[ ! -f "$reqfile" ]] && {
        echo "📝 Creating $reqfile"
        touch "$reqfile"
    }

    for input_pkg in "$@"; do
        echo "📦 Installing $input_pkg..."
        if ! python -m pip install --quiet "$input_pkg"; then
            echo "❌ Failed to install $input_pkg"
            continue
        fi

        # Get installed canonical name + version
        local versioned
        versioned=$(python -m pip show "$input_pkg" 2>/dev/null | awk '
            BEGIN { name=""; version="" }
            /^Name:/    { name=tolower($2) }
            /^Version:/ { version=$2 }
            END {
                if (name && version)
                    print name "==" version
            }' | xargs)

        if [[ -z "$versioned" ]]; then
            echo "⚠️  Could not resolve version for $input_pkg"
            continue
        fi

        # If input_pkg included [extra], preserve it
        if [[ "$input_pkg" == *"["*"]"* ]]; then
            versioned="${input_pkg%%=*}==${versioned#*==}"
        fi

        # Normalize and check if already in file
        local safe_pkg_line
        safe_pkg_line=$(echo "$versioned" | tr '[:upper:]' '[:lower:]' | tr '._-' '-')

        if grep -iEq "^${safe_pkg_line%%==*}(==|\[|\s|$)" <(tr '[:upper:]' '[:lower:]' <"$reqfile" | tr '._-' '-'); then
            echo "✅ ${versioned%%==*} already listed in $reqfile"
        else
            echo "➕ Adding $versioned to $reqfile"
            echo "$versioned" >> "$reqfile"
        fi
    done
}

poetry_refresh() {
  local do_main=false
  local do_dev=false
  local confirm=true
  local pyproject="pyproject.toml"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --main) do_main=true ;;
      --dev)  do_dev=true ;;
      --all)  do_main=true; do_dev=true ;;
      --yes|-y) confirm=false ;;
      *) echo "Usage: poetry_refresh [--main] [--dev] [--all] [--yes]"; return 1 ;;
    esac
    shift
  done

  [[ "$do_main" == false && "$do_dev" == false ]] && do_main=true

  [[ ! -f "$pyproject" ]] && { echo "❌ No $pyproject found."; return 1; }

  for group in main dev; do
    local section flag
    if [[ "$group" == "main" && "$do_main" == true ]]; then
      section="tool.poetry.dependencies"
      flag=""
    elif [[ "$group" == "dev" && "$do_dev" == true ]]; then
      section="tool.poetry.group.dev.dependencies"
      flag="-D"
    else
      continue
    fi

    local packages
    packages=$(awk -v section="\[$section\]" '
      $0 == section { f=1; next }
      /^\[/ { f=0 }
      f && /^[^#]/ { sub(/ =.*/, ""); if ($0 != "python") print }
    ' "$pyproject")

    [[ -z "$packages" ]] && { echo "⚠️  No $group dependencies found."; continue; }

    echo "🔄 Refreshing [$group] dependencies:"
    echo "$packages" | sed 's/^/   • /'

    if $confirm; then
      echo -n "❓ Refresh $group packages to latest and pin? (y/n): "
      read -r input
      input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
      [[ "$input" != "y" ]] && { echo "🚫 Skipped $group."; continue; }
    fi

    poetry remove $(echo $packages)
    poetry add $flag $(echo $packages)
    echo "✅ [$group] dependencies refreshed."
  done
}
