all: build install

install:
	cp -r ../../melodink_player/zig-out/macos ./Frameworks

build:
	cd ../../melodink_player && zig build -Dtarget=aarch64-macos -Doptimize=ReleaseFast

.PHONY: clean
clean:
	rm -rf ./Frameworks
