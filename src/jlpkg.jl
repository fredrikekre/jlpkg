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
"""
function install(; julia::String=joinpath(Sys.BINDIR, Base.julia_exename()),
                   command::String="jlpkg",
                   dir::String=joinpath(homedir(), "bin"),
                   julia_flags=["--color=yes", "--startup-file=no", "-q"],
                   force::Bool=false)
    install_dir = normpath(joinpath(@__DIR__, "..", "jlpkg"))
    jlpkg_scriptfile = joinpath(install_dir, "jlpkg.jl")
    exec_scriptfile = joinpath(install_dir, command)
    open(exec_scriptfile, "w") do f
        print(f,"""
            #!/usr/bin/env bash
            exec $(julia) $(join(julia_flags, ' ')) '$(jlpkg_scriptfile)' "\$@"
            """)
    end
    chmod(exec_scriptfile, 0x00000000000081fd) # results in -rwxrwxr-x (chmod +x file)
    mkpath(dir)
    symlink(exec_scriptfile, joinpath(dir, command))
    return
end

end # module
