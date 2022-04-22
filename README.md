# jlpkg

| **Build Status**                                        |
|:------------------------------------------------------- |
| [![CI][ci-img]][ci-url] [![][codecov-img]][codecov-url] |

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

       --project[=<path>]
           Set the home project/environment.
           Equivalent to Julia's `--project` switch.

       --julia=<path>
           Specify path to, or command for, the Julia executable.
           Overrides the executable set when installing the CLI.

       --update
           Allow the subsequent commands to update package registries.

       --offline
           Enable Pkg's offline mode (requires Julia 1.5 or later).

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

There are number of ways to install `jlpkg`:
 - [Installation from Julia](#Installation-from-Julia)
 - [Installation from tarball](#Installation-from-tarball)
 - [Installation using asdf](#Installation-using-asdf)

### Installation from Julia

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

 · force: boolean used to overwrite any existing commands.
```

#### Install shell completion

`jlpkg` supports Bash shell completion. This can be installed by using `jlpkg.install_completion`:
```julia
julia> jlpkg.install_completion()
```
For available configuration, see the documentation for `jlpkg.install_completion`:
```
help?> jlpkg.install_completion

    jlpkg.install_completion(; kwargs...)

Install shell completion for jlpkg. Currently only bash completion is supported.

Keyword arguments:

 · command: name of the executable command to be completed, defaults to jlpkg.

 · destdir: writable directory to place the completion file in, defaults to ~/.bash_completion.d.

 · rcfile: shell startup file to source the completion file in, defaults to ~/.bashrc.
   If you want to handle sourcing yourself, use rcfile=nothing.

 · force: boolean used to overwrite an existing completion file.
```

### Installation from tarball

It is possible to download and extract a prebuilt script with default settings.
For example, to download the latest release you can run the following
```bash
curl -fsSL https://github.com/fredrikekre/jlpkg/releases/download/v1.5.1/jlpkg-v1.5.1.tar.gz | \
    tar -xzC /usr/local/bin
```
This will extract the executable script `jlpkg` and place it in `/usr/local/bin`.
You can of course replace `/usr/local/bin` with any writable folder in your `PATH`.
When using the prebuilt script it is assumed that `julia` is also in your `PATH`.

The Bash completion file can also be downloaded from the repo. For example:
```bash
curl -fsSL -o ~/.bash_completion.d/jlpkg-completion.bash \
    https://raw.githubusercontent.com/fredrikekre/jlpkg/v1.5.1/src/jlpkg-completion.bash
```
Make sure to source this file in your shell startup file. For example, add the following to `~/.bashrc`:
```bash
# Bash completion for jlpkg
if [[ -f ~/.bash_completion.d/jlpkg-completion.bash ]]; then
    . ~/.bash_completion.d/jlpkg-completion.bash
fi
```

### Installation using `asdf`

It is possible to install `jlpkg` using the [`asdf` version manager](https://asdf-vm.com) using the
[`asdf-jlpkg`](https://github.com/fredrikekre/asdf-jlpkg) plugin. See the plugin
[README](https://github.com/fredrikekre/asdf-jlpkg/blob/master/README.md) for instructions.


[pkg-url]: https://github.com/JuliaLang/Pkg.jl

[ci-url]: https://github.com/fredrikekre/jlpkg/actions/workflows/ci.yml
[ci-img]: https://github.com/fredrikekre/jlpkg/actions/workflows/ci.yml/badge.svg

[codecov-img]: https://codecov.io/gh/fredrikekre/jlpkg/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/fredrikekre/jlpkg
