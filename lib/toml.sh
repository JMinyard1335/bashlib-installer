#!/usr/bin/env bash
# Used to read values from a toml file.
# 
# Values are echoed to stdout, to access them
# you must read them in from stdout.
#
# Usage:
#	toml_r <file> <table> <value>
#	toml_w <file> <table> <value>
#
# Examples:
#	name=$(toml_r config.toml project name)
#	echo "$name"

source "${SCRIPT_DIR}/installer-color.sh"
## Logging functions --------------------------------------------------------
_toml_log() {
    printf "${CYAN}[Toml]:${RESET} %s\n" "$*" >&2
}

_toml_success() {
    printf "${GREEN}[Toml]:${RESET} %s\n" "$*" >&2
}

_toml_error() {
    printf "${RED}[Toml]:${RESET} %s\n" "$*" >&2
}

_toml_warn() {
    printf "${YELLOW}[Toml]:${RESET} %s\n" "$*" >&2
}
## -------------------------------------------------------------------------

## Status Checks -----------------------------------------------------------
# _toml_valid_file <file>
# Two seperate checks just for cleaner error output.
_toml_valid_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        _toml_error "$file not found."
        return 1
    fi

    if [[ ! -s "$file" ]]; then
        _toml_error "$file is empty"
        return 1
    fi

    return 0
}

# _toml_has_table <file> <table>
# faster search then using awk, used for
# early returns and errors
_toml_has_table() {
    local file="$1"
    local table="$2"
    if ! grep -qEx "[[:space:]]*\[${table}\][[:space:]]*" "$file"; then
        _toml_error "[${table}] not found in $file"
        return 1
    fi
}
## -------------------------------------------------------------------------


## API ---------------------------------------------------------------------
# toml_r <file> <table> <value>
# Looks for the given value in the file,
# echos it to stdout if found.
toml_r() {
    local file="$1"
    local table="$2"
    local value="$3"

    # Validate args
    if [[ -z "$file" || -z "$table" || -z "$value" ]]; then
        _toml_error "Usage: read_toml <file> <table> <value>"
        return 1
    fi

    # Check file errors
    if ! _toml_valid_file "$file"; then
	return 1
    fi

    # check if table exists
    if ! _toml_has_table "$file" "$table"; then
	return 1
    fi

    # Get the value from the requested table if it exists.
    awk -v table="$table" -v key="$value" '
        BEGIN {
            in_table = 0
            found = 0
        }

        # Detect table headers
        /^[[:space:]]*\[/ {
            in_table = 0
        }

        $0 ~ "^[[:space:]]*\\[" table "\\][[:space:]]*$" {
            in_table = 1
            next
        }

        # While inside the target table, find key = value
        in_table && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
            line = $0

            # remove "key ="
            sub(/^[[:space:]]*[^=]+=[[:space:]]*/, "", line)

            # trim trailing comment
            sub(/[[:space:]]+#.*$/, "", line)

            # trim surrounding whitespace
            sub(/^[[:space:]]+/, "", line)
            sub(/[[:space:]]+$/, "", line)

            # strip surrounding double quotes if present
            if (line ~ /^".*"$/) {
                sub(/^"/, "", line)
                sub(/"$/, "", line)
            }

            print line
            found = 1
            exit
        }

        END {
            if (!found) exit 1
        }
    ' "$file"

    if [[ $? -ne 0 ]]; then
        _toml_error "\"$value\" not found under [${table}] in $file"
        return 1
    fi

    return 0
}

# toml_w <file> <table> <value>
toml_w() {
    local file=""
    local table=""
    local value=""
    
}

# toml_get_table <file> <table>
# Returns key|value pairs for all entries in the table.
toml_get_table() {
    local file="$1"
    local table="$2"

    if [[ -z "$file" || -z "$table" ]]; then
        return 1
    fi

    if ! _toml_valid_file "$file"; then
        return 1
    fi

    if ! _toml_has_table "$file" "$table"; then
        return 0 # return success but empty
    fi

    awk -v table="$table" '
        BEGIN { in_table = 0 }
        /^[[:space:]]*\[/ { in_table = 0 }
        $0 ~ "^[[:space:]]*\\[" table "\\][[:space:]]*$" { in_table = 1; next }
        in_table && $0 ~ "^[[:space:]]*[^[#=]+=" {
            match($0, /=[[:space:]]*/)
            key = substr($0, 1, RSTART-1)
            val = substr($0, RSTART+RLENGTH)
            
            # trim key
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
            
            # trim value and comments
            sub(/[[:space:]]+#.*$/, "", val)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
            
            # strip quotes
            if (val ~ /^".*"$/) {
                sub(/^"/, "", val)
                sub(/"$/, "", val)
            } else if (val ~ /^'\''.*'\''$/) {
                sub(/^'\''/, "", val)
                sub(/'\''$/, "", val)
            }
            print key "|" val
        }
    ' "$file"
}

## -------------------------------------------------------------------------
