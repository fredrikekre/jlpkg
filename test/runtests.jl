# SPDX-License-Identifier: MIT

using jlpkg, Test, Pkg, Pkg.TOML

const root = joinpath(dirname(dirname(pathof(jlpkg))))
# --compile=yes required due to JuliaLang/julia#37059
# --code_coverage=@ replaced with "user"

function coverage_arg_string()
    cc = Base.JLOptions().code_coverage
    if cc < 3
        ("none", "user", "all")[cc]
    elseif cc == 3
        # path-specific coverage
        "@$(unsafe_string(Base.JLOptions().tracked_path))"
    end
end
        
const test_cmd = ```$(Base.julia_cmd()) $(jlpkg.default_julia_flags)
    --code-coverage=$(coverage_arg_string())
    --compile=yes
    --color=no
    $(joinpath(root, "src", "cli.jl"))```
const jlpkg_version = match(r"^version = \"(\d+.\d+.\d+)\"$"m,
        read(joinpath(root, "Project.toml"), String)).captures[1]

function download_release(v::VersionNumber)
    x, y, z = v.major, v.minor, v.patch
    julia_exec = cd(mktempdir()) do
        julia = "julia-$(x).$(y).$(z)-linux-x86_64"
        tarball = "$(julia).tar.gz"
        sha256 = "julia-$(x).$(y).$(z).sha256"
        run(`curl -o $(tarball) -L https://julialang-s3.julialang.org/bin/linux/x64/$(x).$(y)/$(tarball)`)
        run(`curl -o $(sha256) -L https://julialang-s3.julialang.org/bin/checksums/$(sha256)`)
        run(pipeline(`grep $(tarball) $(sha256)`, `sha256sum -c`))
        mkpath(julia)
        run(`tar -xzf $(tarball) -C $(julia) --strip-components 1`)
        return abspath(julia, "bin", "julia")
    end
    return julia_exec
end

mktempdir() do tmpdir; mktempdir() do depot
    withenv("PATH" => tmpdir * (Sys.iswindows() ? ';' : ':') * get(ENV, "PATH", ""),
            "JULIA_DEPOT_PATH" => depot, "JULIA_PKG_DEVDIR" => nothing) do
        # Installation
        @test_logs (:info, r"Installed") jlpkg.install(destdir=tmpdir)
        @test_throws ErrorException jlpkg.install(destdir=tmpdir)
        @test_logs (:info, r"Installed") jlpkg.install(destdir=tmpdir, force = true)
        @test_logs (:info, r"Installed") jlpkg.install(command="pkg", destdir=tmpdir)
        @test realpath(Sys.which("jlpkg" * (Sys.iswindows() ? ".cmd" : ""))) ==
              realpath(joinpath(tmpdir, "jlpkg" * (Sys.iswindows() ? ".cmd" : "")))
        @test realpath(Sys.which("pkg" * (Sys.iswindows() ? ".cmd" : ""))) ==  realpath(joinpath(tmpdir, "pkg" * (Sys.iswindows() ? ".cmd" : "")))
        @test_logs((:info, r"Installed"), (:warn, r"can not be found in PATH"),
            jlpkg.install(command="cmd-not-in-path", destdir=joinpath(tmpdir, "dir-not-in-path")))
        mktempdir(tmpdir) do tmpdir2; withenv("PATH" => get(ENV, "PATH", "") * (Sys.iswindows() ? ';' : ':') * tmpdir2) do
            @test_logs (:info, r"Installed") (:warn, r"points to a different program") jlpkg.install(destdir=tmpdir2)
        end end
        # Basic usage
        @test Sys.iswindows() ? success(`cmd /c jlpkg --update st`) : success(`jlpkg --update st`)
        @test Sys.iswindows() ? success(`cmd /c jlpkg --help`) : success(`jlpkg --help`)
        @test Sys.iswindows() ? success(`cmd /c pkg --update st`) : success(`pkg --update st`)
        @test Sys.iswindows() ? success(`cmd /c pkg --help`) : success(`pkg --help`)
        @test success(`$(test_cmd) --update --project=$tmpdir add Example=7876af07-990d-54b4-ab0e-23690620f79a`)
        withenv("JULIA_PROJECT" => tmpdir) do
            @test success(`$(test_cmd) add JSON=682c06a0-de6a-54ab-a142-c8b1cf79cde6`)
        end
        project = TOML.parsefile(joinpath(tmpdir, "Project.toml"))
        @test project["deps"]["Example"] == "7876af07-990d-54b4-ab0e-23690620f79a"
        @test project["deps"]["JSON"] == "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
        @test success(`$(test_cmd) --project=$tmpdir rm Example JSON`)
        project = TOML.parsefile(joinpath(tmpdir, "Project.toml"))
        @test isempty(get(project, "deps", []))
        cd(tmpdir) do
            @test success(`$(test_cmd) --project add Example=7876af07-990d-54b4-ab0e-23690620f79a`)
            withenv("JULIA_PROJECT" => "@.") do
                @test success(`$(test_cmd) add JSON=682c06a0-de6a-54ab-a142-c8b1cf79cde6`)
            end
            project = TOML.parsefile(joinpath(tmpdir, "Project.toml"))
            @test project["deps"]["Example"] == "7876af07-990d-54b4-ab0e-23690620f79a"
            @test project["deps"]["JSON"] == "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
            @test success(`$(test_cmd) --project rm Example JSON`)
            project = TOML.parsefile(joinpath(tmpdir, "Project.toml"))
            @test isempty(get(project, "deps", []))
        end
        @test success(`$(test_cmd) --update --project=$tmpdir add https://github.com/JuliaLang/Example.jl`)
        project = TOML.parsefile(joinpath(tmpdir, "Project.toml"))
        @test project["deps"]["Example"] == "7876af07-990d-54b4-ab0e-23690620f79a"
        withenv("JULIA_LOAD_PATH" => tmpdir) do # Should work even though Pkg is not in LOAD_PATH
            @test success(`$(test_cmd) --update st -m`)
        end
        @test success(`$(test_cmd) --offline --project=$tmpdir rm Example`)
        @test success(`$(test_cmd) --offline --project=$tmpdir add Example=7876af07-990d-54b4-ab0e-23690620f79a`)
        # Test --julia flag
        if !Sys.iswindows()
            stdout, stderr = joinpath.(tmpdir, ("stdout.txt", "stderr.txt"))
            this_julia = joinpath(Sys.BINDIR::String, Base.julia_exename())
            @test success(pipeline(`$(test_cmd) --julia=$(this_julia) --version`, stdout=stdout, stderr=stderr))
            @test occursin(string(VERSION), read(stdout, String))
            @test isempty(read(stderr, String))
            @test !success(pipeline(`$(test_cmd) --julia=juliafoobar --version`, stdout=stdout, stderr=stderr))
            @test isempty(read(stdout, String))
            @test occursin("Error: IOError: could not spawn `juliafoobar", read(stderr, String))
            if Sys.islinux() && get(ENV, "CI", nothing) == "true"
                julia11 = download_release(v"1.1.1")
                @test success(pipeline(`$(test_cmd) --julia=$(julia11) --version`, stdout=stdout, stderr=stderr))
                @test occursin(", julia version 1.1.1", read(stdout, String))
                @test isempty(read(stderr, String))
                @test success(pipeline(`$(test_cmd) --julia=$(this_julia) --julia=$(julia11) --version`, stdout=stdout, stderr=stderr))
                @test occursin(", julia version 1.1.1", read(stdout, String))
                @test isempty(read(stderr, String))
                @test success(pipeline(`$(test_cmd) --color=auto --julia=$(julia11) --version`, stdout=stdout, stderr=stderr))
                @test occursin(", julia version 1.1.1", read(stdout, String))
                @test isempty(read(stderr, String))
            end
        end
        # Smoke test all Pkg commands in interpreted mode
        @test success(`$(test_cmd) activate foo`)
        @test success(`$(test_cmd) add SpecialFunctions=276daf66-3868-5448-9aa4-cd146d93841b`)
        @test success(`$(test_cmd) build SpecialFunctions`)
        @test success(`$(test_cmd) develop Example`)
        @test success(`$(test_cmd) free Example`)
        @test success(`$(test_cmd) remove SpecialFunctions`)
        @test success(`$(test_cmd) gc`)
        @test success(`$(test_cmd) pin Example`)
        @test success(`$(test_cmd) resolve`)
        @test success(`$(test_cmd) instantiate`)
        @test success(`$(test_cmd) precompile`)
        @test success(`$(test_cmd) test Example`)
        @test success(`$(test_cmd) rm Example`)
        @test success(`$(test_cmd) update`)
        @test success(`$(test_cmd) status`)
        @test success(`$(test_cmd) help`)
        cd(tmpdir) do
            @test success(`$(test_cmd) generate HelloWorld`)
        end
        if VERSION > v"1.1"
            @test success(`$(test_cmd) registry add https://github.com/fredrikekre/Staging`)
            @test success(`$(test_cmd) registry status`)
            @test success(`$(test_cmd) registry update`)
            @test success(`$(test_cmd) registry remove Staging`)
        end
        # Output
        stdout, stderr = joinpath.(tmpdir, ("stdout.txt", "stderr.txt"))
        @test success(pipeline(`$(test_cmd) --help`, stdout=stdout, stderr=stderr))
        @test !occursin("No input arguments, showing help:", read(stdout, String))
        @test occursin("jlpkg - command line interface", read(stdout, String))
        @test isempty(read(stderr, String))
        @test !success(pipeline(`$(test_cmd)`, stdout=stdout, stderr=stderr))
        @test isempty(read(stdout, String))
        @test occursin("No input arguments, showing help:", read(stderr, String))
        @test occursin("jlpkg - command line interface", read(stderr, String))
        @test success(pipeline(`$(test_cmd) --version`, stdout=stdout, stderr=stderr))
        @test occursin("jlpkg version $(jlpkg_version), julia version $(VERSION)", read(stdout, String))
        @test isempty(read(stderr, String))
        # Error paths
        @test !success(pipeline(`$(test_cmd) --project=$tmpdir rm`, stdout=stdout, stderr=stderr))
        @test isempty(read(stdout, String))
        @test occursin("PkgError:", read(stderr, String))
        @test !success(pipeline(`$(test_cmd) --project=$tmpdir st --help`, stdout=stdout, stderr=stderr))
        @test isempty(read(stdout, String))
        @test occursin("PkgError:", read(stderr, String))
        @test !success(pipeline(`$(test_cmd)`, stdout=stdout, stderr=stderr))
        @test isempty(read(stdout, String))
        @test occursin("No input arguments, showing help:", read(stderr, String))
        @test !success(pipeline(`$(test_cmd) --foobar`, stdout=stdout, stderr=stderr))
        @test isempty(read(stdout, String))
        @test occursin("Invalid argument `--foobar`, showing help:", read(stderr, String))
        @test !success(pipeline(`$(test_cmd) --foobar st`, stdout=stdout, stderr=stderr))
        @test isempty(read(stdout, String))
        @test occursin("Invalid argument `--foobar`, showing help:", read(stderr, String))
        @test !success(pipeline(`$(test_cmd) --update`, stdout=stdout, stderr=stderr))
        @test isempty(read(stdout, String))
        @test occursin("No Pkg REPL arguments, showing help:", read(stderr, String))
        # Test that --compile and --optimize options are default, see issue #1
        # by running jlpkg test suite with jlpkg --project test on CI
        @test Base.JLOptions().opt_level === Int8(2)
        @test Base.JLOptions().compile_enabled === Int8(1)
    end
end end

# Completion installation
if !Sys.iswindows(); mktempdir() do tmpdir; withenv("HOME" => tmpdir) do
    # Standard install
    @test_logs (:info, r"Installed") (:info, r"Modified") jlpkg.install_completion()
    @test occursin("complete -F _jlpkg jlpkg", read(joinpath(homedir(), ".bash_completion.d", "jlpkg-completion.bash"), String))
    @test occursin("# Bash completion for jlpkg", read(joinpath(homedir(), ".bashrc"), String))
    # File exists
    @test_throws ArgumentError jlpkg.install_completion()
    @test_logs (:info, r"Installed") (:info, r"appears") jlpkg.install_completion(; force=true)
    # Non-supported shell
    @test_throws ArgumentError jlpkg.install_completion(; shell="zsh")
    # Different paths
    @test_logs (:info, r"Installed") (:info, r"Modified") jlpkg.install_completion(; destdir=tmpdir, rcfile=joinpath(tmpdir, ".bash_profile"))
    @test occursin("complete -F _jlpkg jlpkg", read(joinpath(homedir(), "jlpkg-completion.bash"), String))
    @test occursin("# Bash completion for jlpkg", read(joinpath(homedir(), ".bash_profile"), String))
    # Different command
    @test_logs (:info, r"Installed") (:info, r"appears") jlpkg.install_completion(; command="pkg", force=true)
    @test occursin("complete -F _jlpkg pkg", read(joinpath(homedir(), ".bash_completion.d", "jlpkg-completion.bash"), String))
end end end
