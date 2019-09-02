# Determine the index of the first Pkg REPL command
const first_cmd_idx = something(findfirst(x -> !startswith(x, "--"), ARGS), length(ARGS)+1)
const JLPKG_ARGS = ARGS[1:first_cmd_idx-1]
const PKG_REPL_ARGS = ARGS[first_cmd_idx:end]

# Parse --julia option (not supported on Windows)
if !Sys.iswindows()
    r = r"^--julia=(.+)$"
    idx = findlast(x -> match(r, x) !== nothing, JLPKG_ARGS)
    if idx !== nothing
        julia = match(r, JLPKG_ARGS[idx]).captures[1]
        deleteat!(ARGS, findall(x -> match(r, x) !== nothing, JLPKG_ARGS))
        f = @__FILE__ # JuliaLang/julia #28188
        cmd = Base.julia_cmd()
        cmd.exec[1] = julia # swap out the executable
        filter!(x -> !startswith(x, "-J"), cmd.exec) # filter out incompatible sysimg
        push!(cmd.exec, "--color=$(Base.have_color ? "yes" : "no")")
        pipe = pipeline(`$(cmd) $(f) $(ARGS)`; stdout=stdout, stderr=stderr)
        exit(!success(pipe))
    end
end

# Parse --version option
if "--version" in JLPKG_ARGS
    println(stdout, "jlpkg version 1.1.0, julia version $(VERSION)")
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
    io = stdout
    if !("--help" in JLPKG_ARGS)
        io = stderr
        if isempty(ARGS)
            println(io, "No input arguments, showing help:\n")
            exit_code = 1
        elseif (idx = findfirst(!isvalid, JLPKG_ARGS); idx !== nothing)
            println(io, "Invalid argument `$(JLPKG_ARGS[idx])`, showing help:\n")
            exit_code = 1
        elseif isempty(PKG_REPL_ARGS)
            println(io, "No Pkg REPL arguments, showing help:\n")
            exit_code = 1
        end
    end
    # Print help
    printstyled(io, "NAME\n"; bold=true)
    println(io, """
           jlpkg - command line interface (CLI) to Pkg, Julia's package manager
    """)
    printstyled(io, "SYNOPSIS\n"; bold=true)
    println(io, """
           jlpkg [--options] <pkg-cmds>...
    """)
    printstyled(io, "OPTIONS\n"; bold=true)
    println(io, """
           <pkg-cmds>...
               Commands to the Pkg REPL mode. Execute the `help` command
               (e.g. `jlpkg help`) to list all available commands, and execute
               `jlpkg ?cmd` (or `jlpkg help cmd`) to show detailed help for a
               specific command. See https://julialang.github.io/Pkg.jl/v1/repl/
               for documentation of the syntax and the available commands.

           --project[=<path>]
               Set the home project/environment.
               Equivalent to Julia's `--project` switch.

           --julia=<path>
               Specify path to, or command for, the Julia executable.
               Overrides the executable set when installing the CLI.

           --update
               Allow the subsequent commands to update package registries.

           --version
               Show jlpkg and julia version numbers.

           --help
               Show this message.
    """)
    printstyled(io, "EXAMPLES\n"; bold=true)
    print(io, """
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
    printstyled(stderr, "Error: "; bold=true, color=:red)
    printstyled(stderr, "could not load Pkg.\n"; color=:red)
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
        println(stdout)
    end
    exit(0)
catch err
    if err isa Pkg.Types.PkgError
        printstyled(stderr, "PkgError: "; bold=true, color=:red)
    elseif err isa Pkg.Types.ResolverError
        printstyled(stderr, "ResolverError: "; bold=true, color=:red)
    else
        rethrow()
    end
    io = IOBuffer()
    showerror(io, err)
    printstyled(stderr, String(take!(io)), '\n'; color=:red)
    exit(1)
end
