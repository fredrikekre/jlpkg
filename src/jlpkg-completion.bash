#!/bin/bash

# Bash completion for jlpkg version 1.4.0.
# See https://github.com/fredrikekre/jlpkg for details.

# Notes to self:
# Uses
#   while IFS='' read -r line; do arr+=("$line"); done < <(cmd)
# instead of
#   mapfile -t arr < <(cmd)
# for compatibility with Bash 3.

# Guesstimate of what `bash_completion/_init_completion -s`
# does. Provided for compatibility where bash_completion
# is not installed.
# TODO: Need to handle the case where the cursor are before
# or in the middle of the current word so for now the script
# uses `bash_completion/_init_completion -s` if available.
__init_completion(){
    words=()
    prev=""
    cur=""
    cword="${COMP_CWORD}"
    split=false
    for (( i = 0; i < ${#COMP_WORDS[@]}; i++ )); do
        [[ ! $i > "${COMP_CWORD}" ]] && cur="${COMP_WORDS[$i]}"
        [[ i -gt 0 && ! $i > "${COMP_CWORD}" ]] && prev="${COMP_WORDS[$i-1]}"
        if [[ "${COMP_WORDS[$i]}" == = ]]; then
            words[-1]="${words[-1]}${COMP_WORDS[$i]}"
            if [[ ! $i > "${COMP_CWORD}" ]]; then
                ((cword --))
                if [[ ${words[-1]} == -* ]]; then
                    split=true
                    cur=""
                else
                    prev="${words[-2]}"
                    cur="${words[-1]}"
                fi
            fi
            # peek next
            if [[ $((i+1 < ${#COMP_WORDS[@]})) && -n "${COMP_WORDS[$i+1]}" ]]; then
                ((i++))
                words[-1]="${words[-1]}${COMP_WORDS[$i]}"
                if [[ ! $i > "${COMP_CWORD}" ]]; then
                    ((cword --))
                    if [[ ${words[-1]} == -* ]]; then
                        cur="${COMP_WORDS[$i]}"
                    else
                        cur="${words[-1]}"
                    fi
                fi
            fi
        else
            [[ $split == "true" ]] && prev="${words[-1]}"
            split=false
            words+=("$cur")
        fi
    done
}

_jlpkg() {

    local cur prev words cword split
    if command -v _init_completion &> /dev/null ; then
        _init_completion -s
    else
        __init_completion
    fi

    COMPREPLY=()

    # Figure out first pkg> command
    local cmd
    for (( i = 1; i < cword; i++ )); do
        if ! [[ "${words[$i]}" == -* ]]; then
            cmd="${words[$i]}"; break
        fi
    done

    # jlpkg options and pkg root commands
    local opts="--help --version --update --offline --project --project= --julia="
    local pkg_cmds="add build develop free gc generate help instantiate pin precompile remove resolve status test update registry"

    if [[ -z "${cmd}" ]]; then
        if [[ "$prev" == "--project" && "${split}" == "true" ]]; then
            while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -f -X '!*Project.toml' -- "${cur}"; compgen -d -- "${cur}")
            compopt -o filenames
        elif [[ "${prev}" == "--julia" && "${split}" == "true" ]]; then
            while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -c -- "${cur}")
        elif [[ "${cur}" =~ "-" ]]; then
            while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${opts}" -- "${cur}")
            [[ "${COMPREPLY[0]}" == "--julia=" ]] && compopt -o nospace
        else
            while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${pkg_cmds}" -- "${cur}")
        fi
        return 0
    fi

    case "${cmd}" in
        # activate)    _jlpkg_activate ;; # Doesn't make sense in a non-interactive Julia session
        add)         _jlpkg_add ;;
        build)       _jlpkg_build ;;
        dev|develop) _jlpkg_develop ;;
        free)        _jlpkg_free ;;
        gc)          _jlpkg_gc ;;
        generate)    _jlpkg_generate ;;
        ?|help)      _jlpkg_help ;;
        instantiate) _jlpkg_instantiate ;;
        pin)         _jlpkg_pin ;;
        precompile)  _jlpkg_precompile ;;
        # redo)        _jlpkg_redo ;; # Doesn't make sense in a non-interactive Julia session
        rm|remove)   _jlpkg_remove ;;
        resolve)     _jlpkg_resolve  ;;
        st|status)   _jlpkg_status ;;
        test)        _jlpkg_test  ;;
        # undo)        _jlpkg_undo ;; # Doesn't make sense in a non-interactive Julia session
        up|update)   _jlpkg_update  ;;
        registry) _jlpkg_registry ;;
        *)          ;;
    esac
}

_jlpkg_julia_toml_file() {
    local file="$1"
    local julia="julia"
    local julia_flags=(--startup-file=no --compile=min --optimize=0)
    for item in "${words[@]}"; do
        [[ "$item" == --julia=* ]] && { julia=${item#--julia=}; break; }
    done
    if [[ "$file" == "project" || "$file" == "manifest" ]]; then
        ${julia} "${julia_flags[@]}" -e '
            project = Base.active_project()
            project === nothing && exit(1)
            println(project)
            if (m = joinpath(dirname(project), "JuliaManifest.toml"); isfile(m))
                println(m)
            else
                println(joinpath(dirname(project), "Manifest.toml"))
            end
        '
        return $?
    else # [[ "$file" == "registry" ]]
        ${julia} "${julia_flags[@]}" -e '
            isempty(DEPOT_PATH) && exit(1)
            regs = String[]
            regdir = joinpath(DEPOT_PATH[1], "registries")
            for reg in readdir(regdir)
                f = joinpath(regdir, reg, "Registry.toml")
                isfile(f) && push!(regs, f)
                f = joinpath(regdir, reg)
                if isfile(f) && endswith(f, ".toml") &&
                   (m = match(r"path\s*=\s*\"(.*)\"", read(f, String)); m !== nothing)
                    f = joinpath(regdir, m[1])
                    isfile(f) && push!(regs, f)
                end
            end
            foreach(r->println(r), regs)
        '
        return $?
    fi
}

_jlpkg_complete_in_toml(){
    local file="$1" # project or registry
    local include_uuids=false
    local toml_files=()
    local output=()
    local out_pat
    local uuid_re="[a-zA-Z0-9]\{8\}-[a-zA-Z0-9]\{4\}-[a-zA-Z0-9]\{4\}-[a-zA-Z0-9]\{4\}-[a-zA-Z0-9]\{12\}"

    if [[ "${file}" == "project" ]]; then
        for item in "${words[@]}"; do
            [[ "$item" == "-m" || "$item" == "--manifest" ]] && { file="manifest"; break; }
        done
    fi
    while IFS='' read -r l; do toml_files+=("$l"); done < <(_jlpkg_julia_toml_file "${file}")
    [[ "${#toml_files[@]}" == "0" ]] && return 0

    [[ "${cur}" == *=* ]] && include_uuids=true

    if [[ "${file}" == "project" ]]; then
        local project="${toml_files[0]}"
        [[ -f "$project" ]] || return 0
        [[ "${include_uuids}" == "true" ]] && out_pat="\1=\2" || out_pat="\1"
        # Search from sed adress [deps] until next TOML section starting with [
        while IFS='' read -r l; do output+=("$l"); done < <(sed -n '/\[deps\]/,/^\[/p' < "${project}" | sed -n -e 's/^\(\S*\)\s*=\s*\"\('"${uuid_re}"'\)\"$/'${out_pat}'/p')
    elif [[ "${file}" == "manifest" ]]; then
        local manifest="${toml_files[1]}"
        [[ -f "$manifest" ]] || return 0
        # Extract package names inside [[*]]
        while IFS='' read -r l; do output+=("$l"); done < <(sed -n 's/^\[\[\(\S*\)\]\]$/\1/p' < "${manifest}")
        if [[ "${include_uuids}" == "true" ]]; then
            local uuids
            while IFS='' read -r l; do uuids+=("$l"); done < <(sed -n 's/^uuid\s*=\s*\"\('"${uuid_re}"'\)\"$/\1/p' < "${manifest}")
            [[ "${#output[@]}" == "${#uuids[@]}" ]] || return 1
            for (( i = 0; i < "${#output[@]}"; i++ )); do
                output[$i]="${output[$i]}=${uuids[$i]}"
            done
        fi
    else # [[ "${file}" == "registry" ]]
        [[ "${include_uuids}" == "true" ]] && out_pat="\2=\1" || out_pat="\2"
        for registry in "${toml_files[@]}"; do
            if [[ "${registry}" =~ .toml$ ]]; then
                cmd=(cat "${registry}")
            else
                cmd=(tar -xOf "${registry}" Registry.toml)
            fi
            while IFS='' read -r l; do output+=("$l"); done < <(
                sed -n -e 's/^\('"${uuid_re}"'\).*name\s*=\s*\"\(.*\)\",.*$/'${out_pat}'/p' <("${cmd[@]}")
            )
        done
    fi

    while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${output[*]}" -- "${cur}")
    [[ "${include_uuids}" == "true" ]] && COMPREPLY=("${COMPREPLY[@]#*=}")
}

_jlpkg_add() {
    local opts="--preserve="
    if [[ "${prev}" == "--preserve" && "${split}" == "true" ]]; then
        while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "all direct semver none tiered" -- "$cur" )
    elif [[ "$cur" == -* ]]; then
        while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${opts}" -- "$cur")
        [[ "${COMPREPLY[0]}" == "--preserve=" ]] && compopt -o nospace
    else
        _jlpkg_complete_in_toml registry
    fi
}

_jlpkg_build() {
    local opts="-v --verbose"
    if [[ "${cur}" == -* ]]; then
        while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${opts}" -- "${cur}")
    else
        _jlpkg_complete_in_toml project
    fi
}

_jlpkg_develop() {
    local opts="--shared --local"
    if [[ "${cur}" == -* ]]; then
        while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${opts}" -- "${cur}")
    elif [[ "${cur}" == /* || "${cur}" == .* ]]; then
        while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -d -- "${cur}")
        compopt -o filenames
    else
        _jlpkg_complete_in_toml registry
    fi
}

_jlpkg_free() {
    _jlpkg_complete_in_toml project
}

_jlpkg_gc() {
    local opts="--all"
    if [[ "${cur}" == -* ]]; then
        while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${opts}" -- "${cur}")
    fi
}

_jlpkg_generate() {
    :
}

_jlpkg_help() {
    case "${prev}" in
        ?|help)
            local reg_cmds="activate add build develop free gc generate instantiate pin precompile redo remove resolve status test undo update registry"
            while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${reg_cmds}" -- "${cur}")  ;;
        registry)
            local reg_cmds="add remove update"
            while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${reg_cmds}" -- "${cur}")  ;;
        *)  ;;
    esac
}

_jlpkg_instantiate() {
    local opts="-v --verbose -m --manifest -p --project"
    if [[ "${cur}" == -* ]]; then
        while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${opts}" -- "${cur}")
    fi
}

_jlpkg_pin() {
    _jlpkg_complete_in_toml project
}

_jlpkg_precompile() {
    :
}


_jlpkg_remove() {
    local opts="-p --project -m --manifest"
    if [[ "${cur}" == -* ]]; then
        while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${opts}" -- "${cur}")
    else
        _jlpkg_complete_in_toml project
    fi
}

_jlpkg_resolve() {
    :
}

_jlpkg_status() {
    local opts="-d --diff -p --project -m --manifest"
    if [[ "${cur}" == -* ]]; then
        while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${opts}" -- "${cur}")
    else
        _jlpkg_complete_in_toml project
    fi
}

_jlpkg_test() {
    local opts="--coverage"
    if [[ "${cur}" == -* ]]; then
        while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${opts}" -- "${cur}")
    else
        _jlpkg_complete_in_toml project
    fi
}

_jlpkg_update() {
    local opts="-p --project -m --manifest --major --minor --patch --fixed"
    if [[ "${cur}" == -* ]]; then
        while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "${opts}" -- "${cur}")
    else
        _jlpkg_complete_in_toml project
    fi
}

_jlpkg_registry() {
    while IFS='' read -r l; do COMPREPLY+=("$l"); done < <(compgen -W "add remove status" -- "${cur}")
}

complete -F _jlpkg jlpkg
