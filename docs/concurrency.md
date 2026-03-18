# Concurrency in Enhanced Xv6

This document covers concurrency primitives, patterns, and pitfalls in Enhanced Xv6.
hello
## Overview

Concurrency in xv6 arises from:
- **Interrupts** — hardware events interrupting kernel execution
- **Multiple CPUs** — parallel execution on SMP hardware
- **Process switching** — context switches between processes

All three require careful synchronization to avoid data corruption.

## Primitives

### Spinlocks

Used for short critical sections in the kernel:

```c
struct spinlock lk;
initlock(&lk, "mylock");

acquire(&lk);
// critical section
release(&lk);
```

**Rules:**
- Always release every acquired lock
- Never sleep while holding a spinlock
- Disable interrupts automatically on acquire

### Sleep Locks

Used for long critical sections (e.g., disk I/O):

```c
struct sleeplock lk;
initsleeplock(&lk, "inode");

acquiresleep(&lk);
// long operation (I/O ok here)
releasesleep(&lk);
```

**Difference from spinlock:** process sleeps instead of spinning — allows other processes to run while waiting.

### Sleep / Wakeup

Used for waiting on events:

```c
// Producer
produce_data();
wakeup(&channel);

// Consumer
acquire(&lk);
while (!data_ready) {
    sleep(&channel, &lk);  // releases lk, sleeps
}
// lk re-acquired on wakeup
release(&lk);
```

**Important:** always check condition in a loop — spurious wakeups are possible.

## Common Patterns

### Lock Ordering

To avoid deadlock, always acquire locks in the same order:

```c
// Consistent ordering — safe
acquire(&lk_a);
acquire(&lk_b);
// ...
release(&lk_b);
release(&lk_a);
```

xv6 enforces lock ordering via `locking` checks in debug builds.

### Per-Object Locks

Each major data structure has its own lock:

```c
struct proc {
    struct spinlock lock;
    // ...
};

struct inode {
    struct sleeplock lock;
    // ...
};
```

### Protecting Shared State

```c
struct {
    struct spinlock lock;
    int count;
} shared;

void increment(void) {
    acquire(&shared.lock);
    shared.count++;
    release(&shared.lock);
}
```

## Deadlock

Deadlock occurs when processes wait for each other in a cycle:

```
Process A holds lock1, waits for lock2
Process B holds lock2, waits for lock1
→ Neither can proceed
```

**Prevention in xv6:**
- Fixed global lock ordering
- Never acquire a lock you already hold
- Keep critical sections short

## Interrupt Safety

Interrupts can fire at any point during kernel execution:

```c
// Bad: interrupt between read and write corrupts state
if (p->state == RUNNABLE) {
    // interrupt fires here, state changes!
    p->state = RUNNING;
}

// Good: hold lock to prevent races with interrupt handler
acquire(&p->lock);
if (p->state == RUNNABLE) {
    p->state = RUNNING;
}
release(&p->lock);
```

Spinlocks disable interrupts on the local CPU while held.

## Memory Ordering

Use `__sync_synchronize()` to prevent compiler/hardware reordering:

```c
// Ensure writes are visible before setting flag
data = value;
__sync_synchronize();
ready = 1;
```

## Common Bugs

### Forgotten Lock

```c
// Bug: missing lock
p->state = RUNNABLE;  // race condition!

// Fix
acquire(&p->lock);
p->state = RUNNABLE;
release(&p->lock);
```

### Lock Held Too Long

```c
// Bad: holds lock during slow I/O
acquire(&lk);
read_from_disk();  // slow!
release(&lk);

// Better: use sleep lock for I/O
acquiresleep(&slk);
read_from_disk();
releasesleep(&slk);
```

### Missing Wakeup Check Loop

```c
// Bad: may miss wakeup or get spurious one
sleep(&chan, &lk);

// Good: always loop
while (!condition) {
    sleep(&chan, &lk);
}
```

## Debugging Concurrency Issues

### Enabling Lock Debugging

xv6 tracks lock acquisition in debug builds. Look for:
- `panic: acquire`: double acquire of same lock
- `panic: release`: releasing unheld lock
- Deadlock: system hangs with no output

### Using GDB

```sh
make qemu-gdb

# Check all process states
(gdb) info threads

# Inspect lock state
(gdb) p bcache.lock
(gdb) p proc[0].lock
```

### Adding Assertions

```c
// Assert lock is held
void
must_hold(struct spinlock *lk)
{
    if (!holding(lk))
        panic("lock not held");
}
```

## Further Reading

- [Design Decisions](design-decisions.md) — rationale for synchronization choices
- [Kernel Internals](kernel-internals.md) — spinlock and sleeplock implementation
- "Operating Systems: Three Easy Pieces" — Concurrency section
