using jlpkg, Test, Pkg, Pkg.TOML

const root = joinpath(dirname(dirname(pathof(jlpkg))))
const cli_script = joinpath(root, "src", "cli.jl")
const test_cmd = ```$(Base.julia_cmd()) --color=yes --startup-file=no -q
    --code-coverage=$(["none", "user", "all"][Base.JLOptions().code_coverage+1])
    $(cli_script)```

const jlpkg_version = match(r"^version = \"(\d.\d.\d)\"$"m,
        read(joinpath(root, "Project.toml"), String)).captures[1]

mktempdir(@__DIR__) do tmpdir
    withenv("PATH" => tmpdir * ':' * get(ENV, "PATH", "")) do
        # Installation
        jlpkg.install(destdir=tmpdir)
        @test_throws ErrorException jlpkg.install(destdir=tmpdir)
        jlpkg.install(destdir=tmpdir, force = true)
        jlpkg.install(command="pkg", destdir=tmpdir)
        @test realpath(Sys.which("jlpkg")) == realpath(joinpath(tmpdir, "jlpkg"))
        @test realpath(Sys.which("pkg")) ==  realpath(joinpath(tmpdir, "pkg"))
        @test_logs((:warn, r"can not be found in PATH"),
            jlpkg.install(command="cmd-not-in-path", destdir=joinpath(tmpdir, "dir-not-in-path")))
        mktempdir(tmpdir) do tmpdir2; withenv("PATH" => get(ENV, "PATH", "") * ':' * tmpdir2) do
            @test_logs (:warn, r"points to a different program") jlpkg.install(destdir=tmpdir2)
        end end
        # Usage
        @test success(`jlpkg st`)
        @test success(`pkg st`)
        @test success(`$(test_cmd) --update --project=$tmpdir add Example=7876af07-990d-54b4-ab0e-23690620f79a`)
        project = TOML.parsefile(joinpath(tmpdir, "Project.toml"))
        @test project["deps"]["Example"] == "7876af07-990d-54b4-ab0e-23690620f79a"
        cd(tmpdir) do
            @test success(`$(test_cmd) --project add JSON=682c06a0-de6a-54ab-a142-c8b1cf79cde6`)
        end
        project = TOML.parsefile(joinpath(tmpdir, "Project.toml"))
        @test project["deps"]["JSON"] == "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
        # Output
        stdout, stderr = joinpath.(tmpdir, ("stdout.txt", "stderr.txt"))
        @test success(pipeline(`$(test_cmd) --help`, stdout=stdout, stderr=stderr))
        @test occursin("jlpkg - A command line interface", read(stdout, String))
        @test isempty(read(stderr, String))
        @test success(pipeline(`$(test_cmd) --version`, stdout=stdout, stderr=stderr))
        @test occursin("jlpkg version $(jlpkg_version), julia version $(VERSION)", read(stdout, String))
        @test isempty(read(stderr, String))
        @test success(pipeline(`$(test_cmd)`, stdout=stdout, stderr=stderr))
        @test occursin("No input arguments, showing help", read(stdout, String))
        @test occursin("jlpkg - A command line interface", read(stdout, String))
        @test isempty(read(stderr, String))
        # Error paths
        @test !success(pipeline(`$(test_cmd)  --project=$tmpdir rm`, stdout=stdout, stderr=stderr))
        @test occursin("PkgError:", read(stdout, String))
        @test isempty(read(stderr, String))
    end
end
