# Frequently Asked Questions

## General Questions

### What is Enhanced Xv6?

Enhanced Xv6 is an extended version of the xv6 operating system, which is a simple Unix-like teaching OS developed at MIT. Our version adds modern features like copy-on-write fork, demand paging, and improved system calls while maintaining educational clarity.

### Why use xv6 for learning?

Xv6 is small enough to understand completely (around 10,000 lines of code) but sophisticated enough to demonstrate core OS concepts like processes, virtual memory, file systems, and system calls. It's an excellent platform for learning OS internals.

### What architecture does it run on?

Enhanced Xv6 runs on RISC-V, a modern open-source instruction set architecture. This makes it more relevant than older x86-based versions while still being simple to understand.

## Building and Running

### What do I need to build Enhanced Xv6?

You need:
- RISC-V GCC toolchain
- QEMU emulator with RISC-V support
- Make build system
- A Unix-like environment (Linux, macOS, or WSL on Windows)

See [setup.md](setup.md) for detailed installation instructions.

### Why does the build fail with missing headers?

This usually means you haven't installed the RISC-V toolchain correctly. Make sure you have:
- `riscv64-unknown-elf-gcc` or `riscv64-linux-gnu-gcc` in your PATH
- All required development libraries

Run `which riscv64-unknown-elf-gcc` to verify installation.

### Can I run this on Windows?

Yes, but you'll need WSL (Windows Subsystem for Linux). Install Ubuntu on WSL, then follow the Linux setup instructions.

## Development

### How do I add a new system call?

1. Define the system call number in `kernel/syscall.h`
2. Add the function prototype in `kernel/syscall.c`
3. Implement the function in the appropriate kernel file
4. Add the user-space wrapper in `user/usys.pl`
5. Declare it in `user/user.h`

See existing system calls like `fork()` or `exec()` as examples.

### How do I add a new user program?

1. Create a new `.c` file in the `user/` directory
2. Add your program to `UPROGS` in the Makefile
3. Run `make` to compile
4. Run `make qemu` and your program will be available

### How do I debug kernel code?

Use GDB with QEMU:
```sh
# Terminal 1
make qemu-gdb

# Terminal 2
gdb-multiarch kernel/kernel
(gdb) target remote localhost:26000
(gdb) b main
(gdb) c
```

See [troubleshooting.md](troubleshooting.md) for more debugging tips.

## Common Issues

### QEMU crashes or exits immediately

Check:
- QEMU version supports RISC-V: `qemu-system-riscv64 --version`
- Port 26000 isn't in use by another process
- Try `make qemu-nox` for text-only mode

### Kernel panic on boot

This usually indicates:
- Memory layout issue in `kernel.ld`
- Stack overflow in kernel code
- Corrupted file system image

Enable GDB debugging to see exactly where it panics.

### File system is full

The xv6 file system is intentionally small. To add more space, modify `FSSIZE` in `kernel/param.h` and rebuild.

## Performance

### Why is xv6 so slow?

Xv6 is designed for clarity, not performance. It:
- Runs in an emulator (QEMU), not real hardware
- Uses simple algorithms instead of optimized ones
- Has minimal caching and buffering

For learning purposes, this simplicity is a feature, not a bug.

### What performance improvements does Enhanced Xv6 add?

Enhanced Xv6 includes:
- Copy-on-write fork (reduces memory copies)
- Demand paging with swapping
- Buffer cache optimization
- Priority-based scheduler

See [features.md](features.md) for details.

## Contributing

### How can I contribute?

See [contributing.md](contributing.md) for:
- Development workflow
- Coding standards
- Pull request process
- Testing requirements

### I found a bug, what should I do?

1. Check if it's already reported in GitHub issues
2. Try to reproduce it reliably
3. Create a new issue with:
   - Steps to reproduce
   - Expected vs actual behavior
   - System information
   - Relevant logs or error messages

## Learning Resources

### Where can I learn more about operating systems?

Recommended resources:
- "Operating Systems: Three Easy Pieces" by Remzi and Andrea Arpaci-Dusseau
- MIT 6.S081 course materials
- The original xv6 book (available free online)

### What topics does xv6 cover?

- Process management and scheduling
- Virtual memory and paging
- File systems and I/O
- System calls and traps
- Concurrency and locking
- Device drivers

### How is this different from other teaching OSes?

Compared to alternatives like Minix or Nachos, xv6:
- Is much smaller and simpler
- Uses modern RISC-V architecture
- Has cleaner, more readable code
- Is actively maintained
