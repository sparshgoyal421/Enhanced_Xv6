# Testing Guide

## Running Tests

### User Programs Test Suite
```sh
# Run all user program tests
make qemu-test

# Run specific test
make qemu QEMUEXTRA="-initcode usertests"
```

### System Call Tests

Test individual system calls:
```sh
$ usertests
Running all tests...
✓ fork test
✓ exec test
✓ pipe test
✓ file operations
✓ memory allocation
```

### Manual Testing

#### Process Management
```sh
$ forktest     # Test fork() implementation
$ stressfs     # Test file system under load
$ usertests    # Comprehensive test suite
```

#### File System
```sh
$ ls           # List directory contents
$ cat README   # Read file contents
$ echo hello > test.txt   # Write to file
$ cat test.txt # Verify write
```

#### Shell Features
```sh
$ ls | grep user          # Test pipes
$ cat README &            # Background execution
$ echo "test" > out.txt   # Output redirection
```

## Performance Testing

### Memory Stress Test
```sh
$ alloctest    # Test memory allocation limits
```

### Concurrency Test
```sh
$ forktest     # Spawn multiple processes
```

## Debugging Failed Tests

### Enable Verbose Output
Modify `Makefile` to add debug flags:
```makefile
CFLAGS += -DDEBUG -g
```

### Check Kernel Logs
Look for panic messages or warnings in QEMU output.

### Use GDB
```sh
# Terminal 1
make qemu-gdb

# Terminal 2
riscv64-unknown-elf-gdb kernel/kernel
(gdb) target remote :26000
(gdb) b syscall
(gdb) c
```

## Writing New Tests

Create new test files in `user/` directory:
```c
#include "kernel/types.h"
#include "user/user.h"

int main(void) {
    // Your test code here
    printf("Test passed\n");
    exit(0);
}
```

Add to `Makefile`:
```makefile
UPROGS=\
    ...
    $U/_yourtest\
```
