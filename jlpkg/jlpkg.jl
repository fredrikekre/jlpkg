# parse --help option
if isempty(ARGS) || "--help" in ARGS
    isempty(ARGS) && println("No input arguments, showing help:\n")
    printstyled("NAME\n"; bold=true)
    println("""
           jlpkg - A command line interface (CLI) for Pkg, Julia's package manager.
    """)
    printstyled("SYNOPSIS\n"; bold=true)
    println("""
           jlpkg [--options] <pkg-args>...
    """)
    printstyled("OPTIONS\n"; bold=true)
    println("""
           <pkg-args>...
               Arguments to the Pkg REPL mode.
               See https://julialang.github.io/Pkg.jl/v1/repl/ for documentation
               of the syntax and the available commands.

           --project[=path]
               Set the home project/environment.
               Equivalent to Julia's `--project` switch.

           --update
               Update package registries.

           --help
               Show this message.
    """)
    printstyled("EXAMPLES\n"; bold=true)
    print("""
           · Add the Example package to the package environment located at `path`:
               \$ jlpkg --project=path add Example

           · Update package registries and add the JSON package:
               \$ jlpkg --update add JSON
    """)
    exit(0)
end

# parse --project option
let
    r = r"^--project(=(.+))?$"
    idx = findall(x->match(r, x) !== nothing, ARGS)
    if isempty(idx)
        Base.HOME_PROJECT[] = nothing
    else
        m = match(r, ARGS[idx[end]])
        if m.captures[2] === nothing
            Base.HOME_PROJECT[] = Base.current_project()
        else # m.captures !== nothing
            Base.HOME_PROJECT[] = m.captures[2]
        end
    end
    deleteat!(ARGS, idx)
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
    idx = findall(==("--update"), ARGS)
    if isempty(idx)
        Pkg.UPDATED_REGISTRY_THIS_SESSION[] = true
    end
    deleteat!(ARGS, idx)
end

# Run Pkg REPL mode with whats left in ARGS
try
    Pkg.REPLMode.pkgstr(join(ARGS, " "))
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
