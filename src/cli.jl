# Determine the index of the first Pkg REPL command
const first_cmd_idx = something(findfirst(x -> !startswith(x, "--"), ARGS), length(ARGS)+1)
const JLPKG_ARGS = ARGS[1:first_cmd_idx-1]
const PKG_REPL_ARGS = ARGS[first_cmd_idx:end]

# Parse --version option
if "--version" in JLPKG_ARGS
    println("jlpkg version 1.0.3, julia version $(VERSION)")
    exit(0)
end

function isvalid(arg)
    return arg == "--update" || arg == "--version" ||
           arg == "--help" || startswith(arg, "--project")
end

# Check input and parse --help option
if isempty(ARGS) || isempty(PKG_REPL_ARGS) || "--help" in JLPKG_ARGS ||
        findfirst(!isvalid, JLPKG_ARGS) !== nothing
    exit_code = 0
    if !("--help" in JLPKG_ARGS)
        if isempty(ARGS)
            println("No input arguments, showing help:\n")
            exit_code = 1
        elseif (idx = findfirst(!isvalid, JLPKG_ARGS); idx !== nothing)
            println("Invalid argument `$(JLPKG_ARGS[idx])`, showing help:\n")
            exit_code = 1
        elseif isempty(PKG_REPL_ARGS)
            println("No Pkg REPL arguments, showing help:\n")
            exit_code = 1
        end
    end
    # Print help
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
               Allow the subsequent commands to update package registries.

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
    exit(exit_code)
end

# Parse --project option
let
    r = r"^--project(=(.+))?$"
    idx = findlast(x->match(r, x) !== nothing, JLPKG_ARGS)
    if idx === nothing # --project not given
        project = get(ENV, "JULIA_PROJECT", nothing)
    else # --project given
        m = match(r, JLPKG_ARGS[idx[end]])
        if m.captures[2] === nothing
            project = "@."
        else # m.captures !== nothing
            project = m.captures[2]
        end
    end
    Base.HOME_PROJECT[] =
        project === nothing ? nothing :
        project == "" ? nothing :
        project == "@." ? Base.current_project() :
        abspath(expanduser(project))
end

# Load Pkg; circumvent user-modified LOAD_PATH
const LOAD_PATH = copy(Base.LOAD_PATH)
try
    push!(empty!(Base.LOAD_PATH), joinpath(Sys.STDLIB, "Pkg"))
    using Pkg
catch
    printstyled("Error: "; bold=true, color=:red)
    printstyled("could not load Pkg.\n"; color=:red)
    rethrow()
finally
    append!(empty!(Base.LOAD_PATH), LOAD_PATH)
end

# Parse --update option
let
    idx = findlast(==("--update"), JLPKG_ARGS)
    if idx === nothing
        Pkg.UPDATED_REGISTRY_THIS_SESSION[] = true
    end
end

# Swap out --compile=min and --optimize=0 if we are running tests
# since we don't want that to propagate to the test-subprocess,
# and packages expect, and should be, tested with default options.
if "test" in PKG_REPL_ARGS
    o = Base.JLOptions()
    o′ = Base.JLOptions((x === :compile_enabled ? Int8(1) :
        x === :opt_level ? Int8(2) :
        getfield(o, x) for x in fieldnames(Base.JLOptions))...)
    unsafe_store!(cglobal(:jl_options, Base.JLOptions), o′)
end

# Run Pkg REPL mode with PKG_REPL_ARGS
try
    Pkg.REPLMode.pkgstr(join(PKG_REPL_ARGS, " "))
    if !isempty(PKG_REPL_ARGS) && (PKG_REPL_ARGS[1] == "help" || startswith(PKG_REPL_ARGS[1], '?'))
        # The help command uses `display` which does not add a trailing \n
        println()
    end
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
