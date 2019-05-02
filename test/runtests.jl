using jlpkg, Test, Pkg, Pkg.TOML

const flags = ["--color=yes", "--startup-file=no", "-q",
    "--code-coverage=$(["none", "user", "all"][Base.JLOptions().code_coverage+1])"]

mktempdir(pwd()) do tmpdir
    withenv("PATH" => tmpdir * ':' * get(ENV, "PATH", "")) do
        # Installation
        jlpkg.install(dir=tmpdir)
        @test_throws ErrorException jlpkg.install(dir=tmpdir)
        jlpkg.install(dir=tmpdir, julia_flags=flags; force = true)
        jlpkg.install(command="pkg", dir=tmpdir, julia_flags=flags)
        @test realpath(Sys.which("jlpkg")) ==
              realpath(Sys.which("pkg")) ==
              realpath(joinpath(tmpdir, "jlpkg"))
        # Usage
        @test success(`jlpkg --update --project=$tmpdir add Example=7876af07-990d-54b4-ab0e-23690620f79a`)
        project = TOML.parsefile(joinpath(tmpdir, "Project.toml"))
        @test project["deps"]["Example"] == "7876af07-990d-54b4-ab0e-23690620f79a"
        cd(tmpdir) do
            @test success(`pkg --project add JSON=682c06a0-de6a-54ab-a142-c8b1cf79cde6`)
        end
        project = TOML.parsefile(joinpath(tmpdir, "Project.toml"))
        @test project["deps"]["JSON"] == "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
        # Output
        stdout, stderr = joinpath.(tmpdir, ("stdout.txt", "stderr.txt"))
        @test success(pipeline(`jlpkg --help`, stdout=stdout, stderr=stderr))
        @test occursin("jlpkg - Command line interface", read(stdout, String))
        @test isempty(read(stderr, String))
        @test success(pipeline(`jlpkg`, stdout=stdout, stderr=stderr))
        @test occursin("No input arguments, showing help", read(stdout, String))
        @test occursin("jlpkg - Command line interface", read(stdout, String))
        @test isempty(read(stderr, String))
        # Error paths
        @test !success(pipeline(`jlpkg  --project=$tmpdir rm`, stdout=stdout, stderr=stderr))
        @test occursin("PkgError:", read(stdout, String))
        @test isempty(read(stderr, String))
    end
end
