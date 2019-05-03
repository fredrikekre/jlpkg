# jlpkg

| **Build Status**                                              |
|:------------------------------------------------------------- |
| [![][travis-img]][travis-url] [![][codecov-img]][codecov-url] |

A command line interface (CLI) for [Pkg][pkg-url], Julia's package manager.

## Usage

Output of `jlpkg --help`:
```
$ jlpkg --help
NAME
       jlpkg - A command line interface (CLI) for Pkg, Julia's package manager.

SYNOPSIS
       jlpkg [--options] <pkg-args>...

OPTIONS
       <pkg-args>...
           Arguments to the Pkg REPL mode.
           See https://julialang.github.io/Pkg.jl/v1/repl/ for documentation
           of the syntax and the available commands.

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
```

## Installation

First install `jlpkg` from the Pkg REPL:
```
pkg> pkg add https://github.com/fredrikekre/jlpkg.git
```
then install the command line interface as
```julia
julia> import jlpkg; jlpkg.install()
```
For available configuration, see the documentation for `jlpkg.install`,
from the Julia REPL:
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
   defaults to ["--color=yes", "--startup-file=no", "-q"].

 · force: boolean used to remove any existing commands.
```

[pkg-url]: https://github.com/JuliaLang/Pkg.jl

[travis-img]: https://travis-ci.com/fredrikekre/jlpkg.svg?branch=master
[travis-url]: https://travis-ci.com/fredrikekre/jlpkg

[codecov-img]: https://codecov.io/gh/fredrikekre/jlpkg/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/fredrikekre/jlpkg
