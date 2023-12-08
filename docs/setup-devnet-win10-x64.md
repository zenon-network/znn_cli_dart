# Setup Zenon devnet node on Windows 10+

The instructions below are for setting up a Zenon **devnet** node on Windows 10+.

## Required software

### Chocolatey

We will use **Chocolatey** for installing the necessary dependencies. **Chocolatey** is a Packet Manager for Windows. Check out their website at https://chocolatey.org/ for more information.

Make sure **Chocolatey** is installed on your system by following the instructions at https://chocolatey.org/install#individual

After installing **Chocolatey**, ensure that you are using an [PowerShell administrative shell](https://www.howtogeek.com/742916/how-to-open-windows-powershell-as-an-admin-in-windows-10/).

### Git

We will need git to interact wth the GitHub repositories. Execute the following command in PowerShell.

``` powershell
choco install git -y
```

### Golang

We will need Golang to to compile the go-zenon code. Execute the following command in PowerShell.

``` powershell
choco install go -y
```

### GCC compiler

We will need a GCC compiler to compile the go-zenon code. Execute the following command in PowerShell.

``` powershell
choco install winlibs-llvm-free
```

## Configuration

After installing all the above tools make sure you close and open a new [PowerShell administrative shell](https://www.howtogeek.com/742916/how-to-open-windows-powershell-as-an-admin-in-windows-10/).

To use **git** we need to configure an user. Use you GitHub account if you have one; otherwise you can use anything you like.

``` powershell
git config --global user.email [your e-mail]
git config --global user.name [your name]
```

## Compilation

We will make a **repos** directory under the current userprofile to store all our work. Replace the path if you want it stored on a different location.

``` powershell 
cd $ENV:USERPROFILE
mkdir repos
cd repos
```

### Zenon node

Create a clone of the **devnet** branch of the [zenon-network/go-zenon repository](https://github.com/zenon-network/go-zenon.git).

``` powershell
git clone https://github.com/zenon-network/go-zenon.git
```

Change directory to the **go-zenon** directory.

``` powershell
cd go-zenon
```

Compile the **go-zenon** code.

``` powershell
go build -o build/libznn.dll -buildmode=c-shared -tags libznn cmd/libznn/main_libznn.go
go build -o build/znnd.exe cmd/znnd/main.go
```

Change directory to the parent directory.

``` powershell
cd ..
```

### NoM community controller

Create a clone of the **master** branch of the [hypercore-one/nomctl repository](https://github.com/hypercore-one/nomctl.git).

``` powershell
git clone https://github.com/hypercore-one/nomctl.git
```

Change directory to the **nomctl** directory.

``` powershell
cd nomctl
```

Compile the **nomctl** code.

``` powershell
go build -o build/nomctl.exe
```

Change directory to the parent directory.

``` powershell
cd ..
```

## Running

Generate configuration and run a **devnet** node.

``` powershell
./nomctl/build/nomctl --data ./devnet generate-devnet --genesis-block=z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7/40000/400000
./go-zenon/build/znnd --data ./devnet
```

> Replace the genesis-block address if you want to use another address for you devnet.

While keeping the shell open it is now possible to connect the **Zenon Explorer** to the node.

Open a web browser and go to https://explorer.zenon.network and connect the **Zenon Explorer** to http://127.0.0.1:35997

Search for the address **z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7**

> Try the Firefox or Brave browser if the Zenon Explorer does not want to connect. Google Chrome can throw a mixed content error when connecting to an insecure destination.

## Clean up

Execute the following commands in order to undo all the installation files of this tutorial.

``` powershell
rm $ENV:USERPROFILE/repos -r -force
choco uninstall mingw -y
choco uninstall go -y
choco uninstall git -y
```