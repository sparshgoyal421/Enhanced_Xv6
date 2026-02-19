# Troubleshooting Guide

## Build Issues

### Missing Dependencies

**Problem**: Build fails with missing header files

**Solution**:
```sh
# macOS
brew install qemu gcc-riscv64-unknown-elf

# Linux
sudo apt-get install qemu-system-misc gcc-riscv64-linux-gnu
```

### Compilation Errors

**Problem**: `make` fails with undefined references

**Solution**:
- Ensure you're using the correct toolchain
- Run `make clean` before rebuilding
- Check that all source files are properly included in the Makefile

## Runtime Issues

### QEMU Won't Start

**Problem**: QEMU exits immediately or shows errors

**Solution**:
- Verify QEMU version: `qemu-system-riscv64 --version`
- Check if port 26000 is already in use
- Try `make qemu-nox` for non-graphical mode

### Kernel Panic

**Problem**: System crashes with panic message

**Solution**:
- Check kernel logs for error details
- Verify memory layout in `kernel.ld`
- Enable debugging with `make qemu-gdb`

## Debugging Tips

### Using GDB
```sh
# Terminal 1
make qemu-gdb

# Terminal 2
gdb-multiarch kernel/kernel
(gdb) target remote localhost:26000
(gdb) break main
(gdb) continue
```

### Common Breakpoints
- `main()` - Kernel entry point
- `userinit()` - First user process
- `trap()` - Exception handler
