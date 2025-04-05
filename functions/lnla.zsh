#!/usr/bin/env zsh
# lnla.zsh

# Create symlinks from source directory to target directory
function lnla() {
    local USAGE="Usage: lnla [options] <source_dir> <target_dir> [filter_pattern]

Create symbolic links in target_dir for files in source_dir matching filter_pattern.

Arguments:
  <source_dir>     Source directory containing original files
  <target_dir>     Target directory where symlinks will be created
  [filter_pattern] Optional glob pattern to filter files (default: *)

Options:
  -h, --help       Display this help message and exit

  Additional options are passed directly to ln (e.g., -f, -s, -v).
  By default, -s (symbolic) is always used."
    # check for help option
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "$USAGE"
        return 0
    fi

    local ln_opts=(-s)  # default is symbolic link
    local args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -*)
                # skip help options
                if [[ "$1" != "-h" && "$1" != "--help" ]]; then
                    ln_opts+=("$1")
                fi
                ;;
            *)
                args+=("$1")
                ;;
        esac
        shift
    done
    # don't act without appropriate arguments
    if [[ ${#args[@]} -lt 2 ]]; then
        echo "Error: Missing required arguments."
        echo "$USAGE"
        return 1
    fi

    local src="${args[1]}"
    local target="${args[2]}"
    local filter="${args[3]:-$src/*}"  # default all files in src dir

    if [[ ! -d "$src" ]]; then
        echo "Error: Source directory '$src' does not exist."
        return 1
    fi

    if [[ ! -d "$target" ]]; then
        echo "Creating target directory: $target"
        mkdir -p "$target"
    fi

    local file_count=0
    for file in $filter; do
        if [[ -f "$file" ]]; then
            ((file_count++))
        fi
    done

    if [[ $file_count -eq 0 ]]; then
        echo "No files found matching pattern: $filter"
        return 0
    fi
    # echo "Found $file_count files to link"
    # echo "Using ln options: ${ln_opts[*]}"
    # actually link
    for file in $filter; do
        if [[ -f "$file" ]]; then
            local basename=$(basename "$file")
            echo "Linking: $basename"
            ln "${ln_opts[@]}" "$file" "$target/$basename"
        fi
    done
    echo "Created $file_count links in $target"
}

# compdef lnla.zsh
_lnla() {
    local curcontext="$curcontext" state line ret=1
    local -a args opts
    args=(
        '(-h --help)'{-h,--help}'[Display help information]'
    )
    local ln_context="ln::::"
    local -a ln_args
    # leverage ln completion
    _call_function ln_context _ln
    # include ln options
    ln_args=("${(M)words[@]:#-*}")
    args+=(${ln_args[@]})
    args+=(
        '1:source directory:_directories'
        '2:target directory:_directories'
        '3:filter pattern:_files'
    )
    _arguments -C "${args[@]}" && ret=0
    # complete source directory
    if [[ $CURRENT -ge 4 ]]; then
        local i src
        for ((i=1; i<CURRENT; i++)); do
            if [[ ${words[i]} != -* ]]; then
                # find the first non-option arg
                src=${words[i]}
                break
            fi
        done
        
        if [[ -n "$src" && -d "$src" ]]; then
            _files -W "$src" && ret=0
        fi
    fi
    
    return ret
}

# Register the completion function
compdef _lnla lnla