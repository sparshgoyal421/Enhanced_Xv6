# Setup Guide

## Prerequisites

### Required Tools
- GCC RISC-V toolchain
- QEMU emulator (RISC-V support)
- Make build system
- Git version control

### Platform-Specific Installation

#### macOS
```sh
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install riscv-tools qemu make git
```

#### Ubuntu/Debian
```sh
sudo apt-get update
sudo apt-get install -y \
    git \
    build-essential \
    gdb-multiarch \
    qemu-system-misc \
    gcc-riscv64-linux-gnu \
    binutils-riscv64-linux-gnu
```

#### Arch Linux
```sh
sudo pacman -S riscv64-linux-gnu-gcc qemu-arch-extra make git
```

## Building Enhanced Xv6

### Clone Repository
```sh
git clone https://github.com/sparshgoyal421/Enhanced_Xv6.git
cd Enhanced_Xv6
```

### Compile Kernel
```sh
make clean
make
```

### Run in QEMU
```sh
# With VGA display
make qemu

# Text mode only
make qemu-nox

# With GDB debugging
make qemu-gdb
```

## Verification

After building, you should see:
```
$ make qemu
qemu-system-riscv64 -machine virt -bios none -kernel kernel/kernel ...
xv6 kernel is booting

init: starting sh
$
```

Type `ls` to see available commands.
