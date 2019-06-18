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
           Allow the subsequent commands to update package registries.

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

### Installing from within Julia

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

### Installing by downloading tarball

It is possible to download and extract a prebuilt script with default settings.
For example, to download the latest release you can run the following
```bash
$ curl -L https://github.com/fredrikekre/jlpkg/releases/download/v1.0.3/jlpkg-v1.0.3.tar.gz | \
  tar -xzC /usr/local/bin
```
This will extract the executable script `jlpkg` and place it in `/usr/local/bin`.
You can of course replace `/usr/local/bin` with any writable folder in your `PATH`.
When using the prebuilt script it is assumed that `julia` is also in your `PATH`.


[pkg-url]: https://github.com/JuliaLang/Pkg.jl

[travis-img]: https://travis-ci.com/fredrikekre/jlpkg.svg?branch=master
[travis-url]: https://travis-ci.com/fredrikekre/jlpkg

[appveyor-img]: https://ci.appveyor.com/api/projects/status/o1j0uq1j1lk7qnlu/branch/master?svg=true
[appveyor-url]: https://ci.appveyor.com/project/fredrikekre/jlpkg/branch/master

[codecov-img]: https://codecov.io/gh/fredrikekre/jlpkg/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/fredrikekre/jlpkg
