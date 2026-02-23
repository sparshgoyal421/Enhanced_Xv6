# Performance Guide

This guide covers performance characteristics, profiling, and optimization techniques for Enhanced Xv6.

## Understanding Performance

### Design Philosophy

Enhanced Xv6 prioritizes **clarity over performance**. It's designed as a teaching operating system, not a production system. However, understanding performance characteristics is valuable for learning.

### Performance Goals

1. **Predictable**: Behavior should be easy to reason about
2. **Reasonable**: Good enough for interactive use in QEMU
3. **Educational**: Performance features should teach concepts

## Performance Characteristics

### Memory Operations

#### Copy-on-Write Fork
```
Standard fork: O(n) where n = number of pages
COW fork:      O(1) initially, O(1) per page fault
```

**Benefit**: Dramatically faster fork for large processes

**Trade-off**: Page faults on first write to shared pages

#### Demand Paging
```
Eager allocation: O(n) allocation time, no page faults
Demand paging:    O(1) allocation, O(1) per page fault
```

**Benefit**: Faster process startup, better memory utilization

**Trade-off**: Page faults on first access

### Process Scheduling

#### Round-Robin Scheduler
```
Time complexity:  O(n) where n = number of processes
Context switch:   ~100 QEMU cycles
Quantum:          1 timer tick
```

**Characteristics**:
- Fair time distribution
- No process starvation
- Predictable behavior
- Simple implementation

**Limitations**:
- No priority support
- Can waste CPU on I/O-bound processes
- Cache unfriendly with many processes

### File System

#### Buffer Cache
```
Cache size:       30 buffers (configurable)
Lookup:           O(n) linear search
Write policy:     Write-through
Replacement:      LRU-like
```

**Performance Tips**:
- Sequential reads are cached
- Repeated access to same file is fast
- Small files benefit most from caching

#### Directory Lookup
```
Time complexity:  O(n) where n = directory entries
```

**Optimization**: Keep directories small for better performance

### System Calls

#### Typical Overhead
```
Trap entry/exit:  ~50 QEMU cycles
Simple syscall:   ~100-200 cycles total
fork():           Variable (depends on COW)
exec():           Variable (depends on binary size)
```

## Profiling and Measurement

### Timing System Calls

```c
#include "kernel/types.h"
#include "user/user.h"

uint64
get_cycles(void)
{
    uint64 cycles;
    asm volatile("rdcycle %0" : "=r" (cycles));
    return cycles;
}

int
main(void)
{
    uint64 start, end;

    start = get_cycles();

    // Operation to measure
    int fd = open("README", 0);
    close(fd);

    end = get_cycles();

    printf("Operation took %d cycles\n", end - start);
    exit(0);
}
```

### Memory Usage

```c
int
main(void)
{
    char *start = sbrk(0);  // Current heap pointer

    // Allocate memory
    sbrk(4096);

    char *end = sbrk(0);
    printf("Heap grew by %d bytes\n", end - start);

    exit(0);
}
```

### Process Timing

```sh
$ time usertests
Test completed in X ticks
```

## Optimization Techniques

### Reducing System Calls

**Bad**: Multiple small reads
```c
for (int i = 0; i < 100; i++) {
    read(fd, &buf[i], 1);  // 100 system calls
}
```

**Good**: Single large read
```c
read(fd, buf, 100);  // 1 system call
```

### Efficient File Access

**Bad**: Repeated opens
```c
for (int i = 0; i < 10; i++) {
    int fd = open("data.txt", O_RDONLY);
    read(fd, buf, 100);
    close(fd);
}
```

**Good**: Open once
```c
int fd = open("data.txt", O_RDONLY);
for (int i = 0; i < 10; i++) {
    read(fd, buf, 100);
}
close(fd);
```

### Memory Allocation

**Bad**: Many small allocations
```c
for (int i = 0; i < 100; i++) {
    sbrk(10);  // Frequent syscalls
}
```

**Good**: Single large allocation
```c
char *mem = sbrk(1000);
// Divide as needed in user space
```

### Process Creation

**Efficient fork + exec**:
```c
int pid = fork();
if (pid == 0) {
    exec(program, args);  // Exec immediately
    exit(1);
}
```

**Why**: COW fork is fast, exec replaces memory anyway

### Using Pipes Efficiently

**Bad**: Small pipe writes
```c
for (int i = 0; i < 100; i++) {
    write(pipe_fd, &data[i], 1);
}
```

**Good**: Buffered writes
```c
write(pipe_fd, data, 100);
```

## Kernel-Level Optimizations

### Buffer Cache Tuning

Increase cache size in `kernel/param.h`:
```c
#define NBUF         30   // Default
#define NBUF         60   // Better for file-heavy workloads
```

**Trade-off**: More memory used for cache

### File System Block Size

Current: 1KB blocks (good for small files)

Alternative: 4KB blocks (better for large files)

**To change**: Modify `BSIZE` in `kernel/fs.h` and `mkfs.c`

### Process Table Size

Increase in `kernel/param.h`:
```c
#define NPROC        64   // Default
#define NPROC        128  // Support more processes
```

## Benchmarking

### File System Benchmark

```c
#include "kernel/types.h"
#include "user/user.h"

int
main(void)
{
    int fd = open("test.dat", O_CREATE | O_WRONLY);
    char buf[512];

    uint64 start = get_cycles();

    // Write 1MB
    for (int i = 0; i < 2048; i++) {
        write(fd, buf, 512);
    }

    uint64 end = get_cycles();
    close(fd);
    unlink("test.dat");

    printf("Write throughput: %d KB/s\n",
           (1024 * 1000000) / (end - start));
    exit(0);
}
```

### Fork Benchmark

```c
int
main(void)
{
    uint64 start = get_cycles();

    for (int i = 0; i < 10; i++) {
        int pid = fork();
        if (pid == 0) {
            exit(0);
        }
        wait(0);
    }

    uint64 end = get_cycles();
    printf("Average fork time: %d cycles\n", (end - start) / 10);
    exit(0);
}
```

### Context Switch Overhead

```c
int
main(void)
{
    int fds[2];
    pipe(fds);

    if (fork() == 0) {
        // Child: ping-pong
        char buf;
        for (int i = 0; i < 100; i++) {
            read(fds[0], &buf, 1);
            write(fds[1], &buf, 1);
        }
        exit(0);
    }

    // Parent: measure
    uint64 start = get_cycles();
    char buf = 'x';

    for (int i = 0; i < 100; i++) {
        write(fds[1], &buf, 1);
        read(fds[0], &buf, 1);
    }

    uint64 end = get_cycles();
    wait(0);

    printf("Context switch overhead: %d cycles\n",
           (end - start) / 200);
    exit(0);
}
```

## Performance Anti-Patterns

### Don't: Busy-Wait

**Bad**:
```c
while (condition_not_met) {
    // Wastes CPU
}
```

**Good**:
```c
sleep(1);  // Yield CPU
```

### Don't: Excessive Forking

**Bad**:
```c
for (int i = 0; i < 1000; i++) {
    if (fork() == 0) {
        do_work();
        exit(0);
    }
}
```

**Why**: Fork is fast but not free; too many processes hurt scheduler

### Don't: Small Synchronous I/O

**Bad**: Read one byte at a time
**Good**: Use larger buffers (512+ bytes)

### Don't: Leak File Descriptors

```c
// Bad: opens accumulate
for (int i = 0; i < 100; i++) {
    open("file.txt", O_RDONLY);  // Never closed
}

// Good: close after use
int fd = open("file.txt", O_RDONLY);
// ... use fd ...
close(fd);
```

## Performance Monitoring Tools

### Built-in Tools

**Current limitations**: Minimal profiling support

**Future additions** (see roadmap):
- Kernel profiler
- System call tracer
- Memory usage monitor
- I/O statistics

### Manual Instrumentation

Add timing code:
```c
// In kernel code
uint64 start = r_time();
// ... operation ...
uint64 elapsed = r_time() - start;
printf("Operation took %d ticks\n", elapsed);
```

## Comparative Performance

### vs. Original xv6

Enhanced Xv6 improvements:
- **Fork**: 10-100x faster (COW)
- **Memory**: Better utilization (demand paging)
- **File I/O**: Similar (enhanced cache helps)

### vs. Linux

xv6 is **much slower** than Linux:
- No sophisticated optimizations
- Simpler algorithms
- Running in emulator
- Designed for clarity, not speed

**This is intentional and appropriate for a teaching OS.**

## When Performance Matters

### It Matters
- Learning about optimization techniques
- Understanding trade-offs
- Measuring algorithmic complexity
- Benchmarking improvements

### It Doesn't Matter
- Absolute speed vs. Linux
- Real-world production use
- Complex workloads
- Large-scale deployments

## Further Reading

- "The xv6 Book" - Chapter on performance
- "Operating Systems: Three Easy Pieces" - Persistence and Performance sections
- MIT 6.S081 lecture notes on measurement and optimization

---

Remember: In Enhanced Xv6, **correctness and clarity** come before performance. Optimize only when it teaches something valuable.
