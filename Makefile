release:
ifeq ($(TAG),)
	$(error TAG not set.)
endif
	sed -i "s/version = .*/version = \"$(shell echo $(TAG) | cut -c 2-)\"/" Project.toml && \
	sed -i "s/jlpkg version [[:digit:]].[[:digit:]].[[:digit:]]/jlpkg version $(shell echo $(TAG) | cut -c 2-)/" src/cli.jl && \
	julia --project -e 'using Pkg; Pkg.test()' && \
	git commit -am "Set version to $(TAG)."

tarball:
	rm -rf build/ && mkdir build && \
	julia --project -e 'using jlpkg; jlpkg.install(julia="julia", destdir="build")' && \
	tar -C build -czf build/jlpkg-$(TAG).tar.gz jlpkg && \
	rm build/jlpkg && \
	ghr $(TAG) build/ && \
	rm -rf build
