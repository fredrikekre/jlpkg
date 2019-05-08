# jlpkg

| **Build Status**                                                                                |
|:----------------------------------------------------------------------------------------------- |
| [![][travis-img]][travis-url] [![][appveyor-img]][appveyor-url] [![][codecov-img]][codecov-url] |

A command line interface (CLI) to [Pkg][pkg-url], Julia's package manager.

## Usage

Output of `jlpkg --help`:
```
$ jlpkg --help
NAME
       jlpkg - command line interface (CLI) to Pkg, Julia's package manager

SYNOPSIS
       jlpkg [--options] <pkg-cmds>...

OPTIONS
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

EXAMPLES
       · Add the Example package to the package environment located at `path`:
           $ jlpkg --project=path add Example

       · Update package registries and add the JSON package:
           $ jlpkg --update add JSON

       · Show the help for the `add` Pkg REPL command:
           $ jlpkg ?add
```

## Installation

First install `jlpkg` from the Pkg REPL:
```
pkg> add jlpkg
```
then install the command line interface with
```julia
julia> import jlpkg; jlpkg.install()
```
For available configuration, see the documentation for `jlpkg.install`,
e.g. from the Julia REPL:
```
help?> jlpkg.install

    jlpkg.install(; kwargs...)

Install the command line interface.

Keyword arguments:

 · command: name of the executable command, defaults to jlpkg.

 · julia: path to julia executable, defaults to the path of the current running julia.

 · destdir: writable directory (available in PATH) for the executable,
   defaults to ~/.julia/bin.

 · julia_flags: vector with command line flags for the julia executable,
   defaults to ["--color=yes", "--startup-file=no", "-q", "--compile=min", "-O0"]

 · force: boolean used to remove any existing commands.
```

[pkg-url]: https://github.com/JuliaLang/Pkg.jl

[travis-img]: https://travis-ci.com/fredrikekre/jlpkg.svg?branch=master
[travis-url]: https://travis-ci.com/fredrikekre/jlpkg

[appveyor-img]: https://ci.appveyor.com/api/projects/status/o1j0uq1j1lk7qnlu/branch/master?svg=true
[appveyor-url]: https://ci.appveyor.com/project/fredrikekre/jlpkg/branch/master

[codecov-img]: https://codecov.io/gh/fredrikekre/jlpkg/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/fredrikekre/jlpkg
