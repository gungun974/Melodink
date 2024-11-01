all: download_and_check install

install:
	rm -rf Src
	cp -r ../../melodink_player Src

download_and_check:
	bash ./download.sh

.PHONY: clean
clean:
	rm -rf ./Frameworks
