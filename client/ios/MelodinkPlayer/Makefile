all: build install

install:
	mkdir -p ./Frameworks
	cp -r ../../melodink_player/zig-out/ios/* ./Frameworks/

build:
	cd ../../melodink_player && zig build -Dtarget=aarch64-ios -Doptimize=ReleaseFast

.PHONY: clean
clean:
	rm -rf ./Frameworks
