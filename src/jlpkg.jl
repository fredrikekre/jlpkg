module jlpkg

"""
    install(; kwargs...)

Install the command line interface.

*Keyword arguments:*
 - `julia`: path to julia executable, defaults to the current
   running julia.
 - `command`: name of the command, defaults to `jlpkg`.
 - `dir`: writable directory (available in PATH) for the executable,
   defaults to `~/.julia/bin`.
 - `julia_flags`: vector with command line flags for the julia executable,
   defaults to `["--color=yes", "--startup-file=no", "-q"]`.
 - `force`: boolean used to remove any existing commands.
"""
function install(; julia::String=joinpath(Sys.BINDIR, Base.julia_exename()),
                   command::String="jlpkg",
                   dir::String=joinpath(homedir(), "bin"),
                   julia_flags=["--color=yes", "--startup-file=no", "-q"],
                   force::Bool=false)
    install_dir = normpath(joinpath(@__DIR__, "..", "jlpkg"))
    jlpkg_scriptfile = joinpath(install_dir, "jlpkg.jl")
    jlpkg_script = """
        #!/usr/bin/env bash
        exec $(julia) $(join(julia_flags, ' ')) '$(jlpkg_scriptfile)' "\$@"
        """
    h = hash(jlpkg_script)
    exec_scriptfile = joinpath(install_dir, string("jlpkg", '-', h))
    open(exec_scriptfile, "w") do f
        print(f, jlpkg_script)
    end
    chmod(exec_scriptfile, 0o0100775) # equivalent to -rwxrwxr-x (chmod +x exec_scriptfile)
    link = joinpath(dir, command)
    force && rm(link)
    if ispath(link) || islink(link)
        error("file `$link` already exists; use `jlpkg.install(force=true)` to overwrite.")
    end
    mkpath(dir)
    symlink(exec_scriptfile, link)
    if Sys.which(command) === nothing
        @warn """
              `Sys.which(\"$(command)\")` returns `nothing`, meaning that `command`
              can not be found in PATH. Either make sure that `$(dir)` is in PATH,
              or manually add a symlink from a directory in PATH to the installed
              program file.
              Path to installed program:
                  $(exec_scriptfile)
              """
    elseif realpath(Sys.which(command)) !== realpath(exec_scriptfile)
        @warn """
              `Sys.which(\"$(command)\")` points to a different program than the one
              just installed. Please check your PATH.
              `Sys.which(\"$(command)\")`:
                  $(Sys.which(command))
              Path to installed program:
                  $(exec_scriptfile)
              """
    end
    return
end

end # module
