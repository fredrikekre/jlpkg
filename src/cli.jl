# Determine the index of the first Pkg REPL command
const commands = ["package", "test", "help", "instantiate", "remove", "rm", "add",
    "develop", "dev", "free", "pin", "build", "resolve", "activate", "update", "up",
    "generate", "precompile", "status", "st", "gc", "preview", "registry"]
const first_cmd_idx = something(findfirst(x -> x in commands || startswith(x, '?'), ARGS), length(ARGS)+1)
const JLPKG_ARGS = ARGS[1:first_cmd_idx-1]
const PKG_REPL_ARGS = ARGS[first_cmd_idx:end]

# parse --help option
if isempty(ARGS) || "--help" in JLPKG_ARGS
    isempty(ARGS) && println("No input arguments, showing help:\n")
    printstyled("NAME\n"; bold=true)
    println("""
           jlpkg - command line interface (CLI) to Pkg, Julia's package manager
    """)
    printstyled("SYNOPSIS\n"; bold=true)
    println("""
           jlpkg [--options] <pkg-cmds>...
    """)
    printstyled("OPTIONS\n"; bold=true)
    println("""
           <pkg-cmds>...
               Commands to the Pkg REPL mode. Execute the `help` command
               (e.g. `jlpkg help`) to list all available commands, and execute
               `jlpkg ?cmd` (or `jlpkg help cmd`) to show detailed help for a
               specific command. See https://julialang.github.io/Pkg.jl/v1/repl/
               for documentation of the syntax and the available commands.

           --project[=path]
               Set the home project/environment.
               Equivalent to Julia's `--project` switch.

           --update
               Update package registries.

           --version
               Show jlpkg and julia version numbers.

           --help
               Show this message.
    """)
    printstyled("EXAMPLES\n"; bold=true)
    print("""
           · Add the Example package to the package environment located at `path`:
               \$ jlpkg --project=path add Example

           · Update package registries and add the JSON package:
               \$ jlpkg --update add JSON

           · Show the help for the `add` Pkg REPL command:
               \$ jlpkg ?add
    """)
    exit(0)
end

# parse --version option
if "--version" in JLPKG_ARGS
    println("jlpkg version 1.0.0, julia version $(VERSION)")
    exit(0)
end

# parse --project option
let
    r = r"^--project(=(.+))?$"
    idx = findlast(x->match(r, x) !== nothing, JLPKG_ARGS)
    if idx === nothing
        Base.HOME_PROJECT[] = nothing
    else
        m = match(r, JLPKG_ARGS[idx[end]])
        if m.captures[2] === nothing
            Base.HOME_PROJECT[] = Base.current_project()
        else # m.captures !== nothing
            Base.HOME_PROJECT[] = m.captures[2]
        end
    end
end

# Load Pkg; circumvent user-modified LOAD_PATH
const LOAD_PATH = copy(Base.LOAD_PATH)
try
    push!(empty!(Base.LOAD_PATH), joinpath(Sys.STDLIB, "Pkg"))
    using Pkg
finally
    append!(empty!(Base.LOAD_PATH), LOAD_PATH)
end

# parse --update option
let
    idx = findlast(==("--update"), JLPKG_ARGS)
    if idx === nothing
        Pkg.UPDATED_REGISTRY_THIS_SESSION[] = true
    end
end

# Run Pkg REPL mode with PKG_REPL_ARGS
try
    Pkg.REPLMode.pkgstr(join(PKG_REPL_ARGS, " "))
    exit(0)
catch err
    if err isa Pkg.Types.PkgError
        printstyled("PkgError: "; bold=true, color=:red)
    elseif err isa Pkg.Types.ResolverError
        printstyled("ResolverError: "; bold=true, color=:red)
    else
        rethrow()
    end
    io = IOBuffer()
    showerror(io, err)
    printstyled(String(take!(io)), '\n'; color=:red)
    exit(1)
end
