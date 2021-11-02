module jlpkg

# --compile=min segfaults Julia 1.0 and the fix can't trivially be backported.
# --color should be removed for the new LTS due to better defaults in Julia >1.5
@static if VERSION < v"1.1"
    const default_julia_flags = ["--color=yes", "--startup-file=no", "-q", "-O0"]
else
    const default_julia_flags = ["--color=yes", "--startup-file=no", "-q", "--compile=min", "-O0"]
end

"""
    jlpkg.install(; kwargs...)

Install the command line interface.

*Keyword arguments:*
 - `command`: name of the executable command, defaults to `jlpkg`.
 - `julia`: path to julia executable, defaults to the path of the
   current running julia.
 - `destdir`: writable directory (available in PATH) for the executable,
   defaults to `~/.julia/bin`.
 - `julia_flags`: vector with command line flags for the julia executable,
   defaults to `["--color=yes", "--startup-file=no", "-q", "--compile=min", "-O0"]`.
 - `force`: boolean used to overwrite any existing commands.
"""
function install(; julia::String=joinpath(Sys.BINDIR, Base.julia_exename()),
                   command::String="jlpkg",
                   destdir::String=joinpath(DEPOT_PATH[1], "bin"),
                   julia_flags::Vector{String}=default_julia_flags,
                   force::Bool=false)
    Sys.iswindows() && (command *= ".cmd")
    destdir = abspath(expanduser(destdir))
    exec = joinpath(destdir, command)
    if ispath(exec) && !force
        error("file `$(exec)` already exists; use `jlpkg.install(force=true)` to overwrite.")
    end
    mkpath(destdir)
    open(exec, "w") do f
        if Sys.iswindows()
            # cmd header required dos line endings
            print(f, replace("""
                @show #= 2>nul
                @call "$(julia)" $(join(julia_flags, ' ')) "%~dp0%~n0.cmd" %*
                @exit /b %errorlevel%
                =#
                """, "\n"=>"\r\n"))
        else # unix
            print(f, """
                #!/usr/bin/env bash
                #=
                exec $(julia) $(join(julia_flags, ' ')) "\${BASH_SOURCE[0]}" "\$@"
                =#
                """)
        end
        open(abspath(@__DIR__, "cli.jl"), "r") do cli
            write(f, cli)
        end
    end
    chmod(exec, 0o0100775) # equivalent to -rwxrwxr-x (chmod +x exec)
    @info "Installed jlpkg to `$(Base.contractuser(exec))`."
    if Sys.which(command) === nothing
        @warn """
              `Sys.which(\"$(command)\")` returns `nothing`, meaning that `command`
              can not be found in PATH. Either make sure that `$(destdir)` is in PATH,
              or manually add a symlink from a directory in PATH to the installed
              program file.
              Path to installed program:
                  $(exec)
              """
    elseif realpath(Sys.which(command)) !== realpath(exec)
        @warn """
              `Sys.which(\"$(command)\")` points to a different program than the one
              just installed. Please check your PATH.
              `Sys.which(\"$(command)\")`:
                  $(Sys.which(command))
              Path to installed program:
                  $(exec)
              """
    end
    return
end

"""
    jlpkg.install_completion(; kwargs...)

Install shell completion for jlpkg. Currently only bash completion is supported.

*Keyword arguments:*
 - `command`: name of the executable command to be completed, defaults to `jlpkg`.
 - `destdir`: writable directory to place the completion file in,
   defaults to `~/.bash_completion.d`.
 - `rcfile`: shell startup file to source the completion file in,
   defaults to `~/.bashrc`. If you want to handle sourcing yourself, use `rcfile=nothing`.
 - `force`: boolean used to overwrite an existing completion file.
"""
function install_completion(; command::String="jlpkg",
                              destdir::String=joinpath(homedir(), ".bash_completion.d"),
                              rcfile::Union{String,Nothing}=joinpath(homedir(), ".bashrc"),
                              shell::String="bash",
                              force::Bool=false)
    if shell != "bash"
        throw(ArgumentError("only bash completion is currently supported"))
    end

    # Install script into destdir
    fname = "jlpkg-completion.bash"
    mkpath(destdir)
    dst = joinpath(destdir, fname)
    dstc = Base.contractuser(dst)
    src = joinpath(@__DIR__, fname)
    if isfile(dst) && !force
        throw(ArgumentError("destination file `$(dstc)` already exist; use force=true to overwrite."))
    end
    src_str = read(src, String)
    src_str = replace(src_str, r"^complete -F _jlpkg jlpkg$"m => "complete -F _jlpkg $(command)")
    open(iod -> write(iod, src_str), dst, "w")
    @info "Installed jlpkg bash completion to `$(dstc)`."

    # Source the file in the rc file
    if rcfile !== nothing
        rc = isfile(rcfile) ? read(rcfile, String) : ""
        rcc = Base.contractuser(rcfile)
        header = """

        # Bash completion for jlpkg
        # See https://github.com/fredrikekre/jlpkg for details."""
        if occursin(header, rc)
            @info "`$(rcc)` already appears to source `$(dstc)`, skipping modification."
        else
            open(rcfile, "a") do io
                print(io, """
                $(header)
                if [[ -f $(dstc) ]]; then
                    . $(dstc)
                fi
                """)
            end
            @info "Modified `$(rcc)` to source `$(dstc)`."
        end
    end
    return dst
end

end # module
