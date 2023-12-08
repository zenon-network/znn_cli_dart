# Setup Zenon devnet node on Ubuntu 22.04+

The instructions below are for setting up a Zenon **devnet** node on Ubuntu 22.04+.

## Required software

### Git

We will need git to interact wth the GitHub repositories. Execute the following command in a Terminal.

``` bash
sudo apt install git
```

### Golang

We will need Golang to compile the go-zenon code. Execute the following command in a Terminal.

``` bash
sudo apt install golang-go
```

### Make

We will need Make to execute makefiles. Execute the following command in a Terminal.

``` bash
sudo apt install make
```

### GCC compiler

We need a gcc compiler to compile the go-zenon code. Check to make sure gcc is installed.

``` bash
gcc --version
```

You should see something like the following in Ubuntu 22.04

``` bash
gcc (Ubuntu 11.4.0-1ubuntu1-22.04) 11.4.0
Copyright (C) 2021 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

If gcc is not installed run the following command

``` bash
sudo apt install gcc
```

## Configuration

After installing all the above tools make sure you close and open a new Bash Shell.

To use **git** we need to configure an user. Use you GitHub account if you have one; otherwise you can use anything you like.

``` bash
git config --global user.email [your e-mail]
git config --global user.name [your name]
```

## Compilation

We will make a **repos** directory under the current userprofile to store all our work. Replace the path if you want it stored on a different location.

``` bash 
cd ~/
mkdir repos
cd repos
```

### Zenon node

Create a clone of the **master** branch of the [zenon-network/go-zenon repository](https://github.com/zenon-network/go-zenon.git).

``` bash
git clone https://github.com/zenon-network/go-zenon.git
```

Change directory to the **go-zenon** directory.

``` bash
cd go-zenon
```

Compile the **go-zenon** code.

``` bash
make znnd
```

Configure and run a **devnet** node.

``` bash
./build/znnd --data ./devnet generate-devnet --genesis-block=z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7,40000,400000
./build/znnd --data ./devnet
```

> Replace the genesis-block address if you want to use another address for you devnet.

While keeping the shell open it is now possible to connect the **Zenon Explorer** to the node.

Open a web browser and go to https://explorer.zenon.network and connect the **Zenon Explorer** to http://127.0.0.1:35997

Search for the address **z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7**

> Try the Firefox or Brave browser if the Zenon Explorer does not want to connect. Google Chrome can throw a mixed content error when connecting to an insecure destination.