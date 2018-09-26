user = gitconfig["github.user"]
t = Template(; user=me)
temp_dir = mktempdir()
pkg_dir = joinpath(temp_dir, test_pkg)

@testset "GitLabCI" begin
    @testset "Plugin creation" begin
        p = GitLabCI()
        @test p.gitignore == ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"]
        @test p.src == joinpath(PkgTemplates.DEFAULTS_DIR, "gitlab-ci.yml")
        @test p.dest == ".gitlab-ci.yml"
        @test p.badges == [
			Badge(
				"Build Status",
				"https://gitlab.com/{{USER}}/{{PKGNAME}}.jl/badges/master/build.svg",
				"https://gitlab.com/{{USER}}/{{PKGNAME}}.jl/pipelines",
			),
			Badge(
				"Coverage",
				"https://gitlab.com/{{USER}}/{{PKGNAME}}.jl/badges/master/coverage.svg",
				"https://gitlab.com/{{USER}}/{{PKGNAME}}.jl/commits/master",
			),
        ]
        @test p.view == Dict("GITLABCOVERAGE" => true)
        p = GitLabCI(; config_file=nothing)
        @test p.src === nothing
        p = GitLabCI(; config_file=test_file)
        @test p.src == test_file
        @test_throws ArgumentError GitLabCI(; config_file=fake_path)
		p = GitLabCI(; coverage=false)
		@test p.badges == [
			Badge(
				"Build Status",
				"https://gitlab.com/{{USER}}/{{PKGNAME}}.jl/badges/master/build.svg",
				"https://gitlab.com/{{USER}}/{{PKGNAME}}.jl/pipelines",
			),
		]
		@test p.view == Dict("GITLABCOVERAGE" => false)
    end

    @testset "Badge generation" begin
        p = GitLabCI()
        @test badges(p, user, test_pkg) == [
	    	"[![Build Status](https://gitlab.com/$user/$test_pkg.jl/badges/master/build.svg)](https://gitlab.com/$user/$test_pkg.jl/pipelines)",
			"[![Coverage](https://gitlab.com/$user/$test_pkg.jl/badges/master/coverage.svg)](https://gitlab.com/$user/$test_pkg.jl/commits/master)",
		]
    end

    @testset "File generation" begin
        p = GitLabCI()
        @test gen_plugin(p, t, temp_dir, test_pkg) == [".gitlab-ci.yml"]
        @test isfile(joinpath(pkg_dir, ".gitlab-ci.yml"))
        gitlab = read(joinpath(pkg_dir, ".gitlab-ci.yml"), String)
        @test occursin("test_template", gitlab)
        # The default plugin should enable the coverage step.
        @test occursin("using Coverage", gitlab)
        rm(joinpath(pkg_dir, ".gitlab-ci.yml"))

        p = GitLabCI(; coverage=false)
        gen_plugin(p, t, temp_dir, test_pkg)
        gitlab = read(joinpath(pkg_dir, ".gitlab-ci.yml"), String)
        # If coverage is false, there should be no coverage step.
        @test !occursin("using Coverage", gitlab)
        rm(joinpath(pkg_dir, ".gitlab-ci.yml"))
        p = GitLabCI(; config_file=nothing)

        @test isempty(gen_plugin(p, t, temp_dir, test_pkg))
        @test !isfile(joinpath(pkg_dir, ".gitlab-ci.yml"))
    end
end

rm(temp_dir; recursive=true)
