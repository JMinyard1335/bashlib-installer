#!/usr/bin/env bash
# Used to read the tool.toml file for info.
#
# tool.toml should be located in the project root and will be installed to the
# installpath/lib.

PROJECT_NAME=""
AUTHOR=""
REPO=""
DEPENDENCIES=()

# Parse a value from a toml file given a section and key
# Usage: _toml_get <file> <section> <key>
_toml_get() {
    local file="$1"
    local section="$2"
    local key="$3"

    awk -F '=' -v section="$section" -v key="$key" '
        /^\[/ { in_section = ($0 == "[" section "]") }
        in_section && $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
            val = $2
            gsub(/\r/, "", val)
            gsub(/^[[:space:]"'\''\`]+/, "", val)
            gsub(/[[:space:]"'\''\`]+$/, "", val)
            if (val != "") print val
            exit
        }
    ' "$file"
}

get_name() {
    local file="${1:-tool.toml}"
    PROJECT_NAME="$(_toml_get "$file" "project" "name")"
    echo "$PROJECT_NAME"
}

get_author() {
    local file="${1:-tool.toml}"
    AUTHOR="$(_toml_get "$file" "project" "author")"
    echo "$AUTHOR"
}

get_repo() {
    local file="${1:-tool.toml}"
    REPO="$(_toml_get "$file" "project" "repo")"
    echo "$REPO"
}

get_dependencies() {
    local file="${1:-tool.toml}"
    DEPENDENCIES=()

    local in_deps=0
    local delimiters=$' \t\r\n"\'`'
    while IFS='=' read -r key value; do
        # Detect section headers
        if [[ "$key" =~ ^\[(.+)\]$ ]]; then
            [[ "${BASH_REMATCH[1]}" == "dependencies" ]] && in_deps=1 || in_deps=0
            continue
        fi
        # Collect key=value pairs under [dependencies]
        if (( in_deps )) && [[ -n "$key" ]]; then
            key="${key//[$delimiters]/}"
            value="${value//[$delimiters]/}"
            DEPENDENCIES+=("${key}=${value}")
        fi
    done < "$file"

    printf '%s\n' "${DEPENDENCIES[@]}"
}
