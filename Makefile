release:
ifeq ($(TAG),)
	$(error TAG not set.)
endif
	sed -i "s/version = .*/version = \"$(shell echo $(TAG) | cut -c 2-)\"/" Project.toml && \
	sed -i "s/jlpkg version [[:digit:]].[[:digit:]].[[:digit:]]/jlpkg version $(shell echo $(TAG) | cut -c 2-)/" src/cli.jl && \
	sed -i "s/\/v[[:digit:]].[[:digit:]].[[:digit:]]\/jlpkg-v[[:digit:]].[[:digit:]].[[:digit:]].tar.gz/\/$(TAG)\/jlpkg-$(TAG).tar.gz/" README.md && \
	sed -i "s/\/jlpkg\/v[[:digit:]].[[:digit:]].[[:digit:]]\/src\//\/jlpkg\/$(TAG)\/src\//" README.md && \
	sed -i "s/jlpkg version [[:digit:]].[[:digit:]].[[:digit:]]/jlpkg version $(shell echo $(TAG) | cut -c 2-)/" src/jlpkg-completion.bash
	julia --project -e 'using Pkg; Pkg.test()' && \
	git commit -am "Set version to $(TAG)."

tarball:
	git fetch origin && \
	git checkout $(TAG) && \
	rm -rf build/ && mkdir build && \
	julia --project -e 'using jlpkg; jlpkg.install(julia="julia", destdir="build")' && \
	tar -C build -czf build/jlpkg-$(TAG).tar.gz jlpkg && \
	rm build/jlpkg && \
	ghr $(TAG) build/ && \
	rm -rf build && \
	git checkout master
