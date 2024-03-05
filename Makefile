default: all

all:
	echo Use 'make windows' or 'make linux' to build the znn-cli binary

windows:
	-mkdir build
	dart pub get
	dart compile exe znn-cli.dart -o build\znn-cli.exe
	copy .\Resources\* .\build\
	
linux: 
	mkdir -p build
	dart pub get
	dart compile exe znn-cli.dart -o build/znn-cli
	cp ./Resources/* ./build
	
