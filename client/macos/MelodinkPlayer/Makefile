all: download_and_check build install

install:
	mkdir -p ./Frameworks
	cp -r ../../melodink_player/zig-out/macos/* ./Frameworks/

build:
	cd ../../melodink_player && zig build -Dtarget=aarch64-macos -Doptimize=ReleaseFast

download_and_check:
	bash ./download.sh

.PHONY: clean
clean:
	rm -rf ./Frameworks
