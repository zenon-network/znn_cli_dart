default: all

all:
	mkdir -p build
	dart compile exe cli_handler.dart -o build/znn-cli
	cp ./Resources/* ./build
