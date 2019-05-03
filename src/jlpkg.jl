module jlpkg

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
   defaults to `["--color=yes", "--startup-file=no", "-q"]`.
 - `force`: boolean used to remove any existing commands.
"""
function install(; julia::String=joinpath(Sys.BINDIR, Base.julia_exename()),
                   command::String="jlpkg",
                   destdir::String=joinpath(DEPOT_PATH[1], "bin"),
                   julia_flags::Vector{String}=["--color=yes", "--startup-file=no", "-q"],
                   force::Bool=false)
    exec = joinpath(destdir, command)
    if ispath(exec) && !force
        error("file `$(exec)` already exists; use `jlpkg.install(force=true)` to overwrite.")
    end
    mkpath(destdir)
    open(exec, "w") do f
        print(f, """
            #!/usr/bin/env bash
            #=
            exec $(julia) $(join(julia_flags, ' ')) "\${BASH_SOURCE[0]}" "\$@"
            =#
            """)
        open(abspath(@__DIR__, "cli.jl"), "r") do cli
            write(f, cli)
        end
    end
    chmod(exec, 0o0100775) # equivalent to -rwxrwxr-x (chmod +x exec)
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

end # module
