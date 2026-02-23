# Kernel Internals

This document provides a deep dive into the internal workings of the Enhanced Xv6 kernel.

## Boot Process

### Boot Sequence

```
1. QEMU loads kernel at 0x80000000
2. _entry (kernel/entry.S) sets up stack
3. start() (kernel/start.c) configures machine mode
4. main() (kernel/main.c) initializes subsystems
5. userinit() creates first user process
6. scheduler() begins running processes
```

### Detailed Boot Steps

#### 1. Entry Point (_entry)

```asm
# kernel/entry.S
# Set up stack for C code
la sp, stack0
li a0, 1024*4
csrr a1, mhartid
addi a1, a1, 1
mul a0, a0, a1
add sp, sp, a0
# Jump to start()
call start
```

#### 2. Machine Mode Setup (start)

```c
// kernel/start.c
void start()
{
    // Delegate interrupts to supervisor mode
    w_medeleg(0xffff);
    w_mideleg(0xffff);

    // Enable interrupts in supervisor mode
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);

    // Configure PMP (physical memory protection)
    w_pmpaddr0(0x3fffffffffffffull);
    w_pmpcfg0(0xf);

    // Timer interrupt setup
    timerinit();

    // Switch to supervisor mode and jump to main
    w_mepc((uint64)main);
    w_satp(0);
    w_mstatus(r_mstatus() & ~MSTATUS_MPP_MASK | MSTATUS_MPP_S);
    w_pmpaddr0(0x3fffffffffffffull);
    asm volatile("mret");
}
```

#### 3. Main Initialization

```c
// kernel/main.c
void main()
{
    if (cpuid() == 0) {
        consoleinit();
        printfinit();
        printf("\n");
        printf("xv6 kernel is booting\n");
        printf("\n");
        kinit();         // Physical page allocator
        kvminit();       // Kernel page table
        kvminithart();   // Install kernel page table
        procinit();      // Process table
        trapinit();      // Trap vectors
        trapinithart();  // Install trap vector
        plicinit();      // Interrupt controller
        plicinithart();  // Enable device interrupts
        binit();         // Buffer cache
        iinit();         // Inode table
        fileinit();      // File table
        virtio_disk_init(); // Disk driver
        userinit();      // First user process
        __sync_synchronize();
        started = 1;
    } else {
        // Other CPUs wait then initialize
        while(started == 0) ;
        __sync_synchronize();
        printf("hart %d starting\n", cpuid());
        kvminithart();
        trapinithart();
        plicinithart();
    }

    scheduler();  // Start running processes
}
```

## Process Management

### Process Structure

```c
// kernel/proc.h
struct proc {
    struct spinlock lock;

    // Process state
    enum procstate state;        // Process state
    void *chan;                  // If sleeping, on what
    int killed;                  // If non-zero, have been killed
    int xstate;                  // Exit status to return to parent
    int pid;                     // Process ID

    // wait_lock must be held when using this:
    struct proc *parent;         // Parent process

    // Protected by lock:
    uint64 kstack;               // Virtual address of kernel stack
    uint64 sz;                   // Size of process memory (bytes)
    pagetable_t pagetable;       // User page table
    struct trapframe *trapframe; // Trap frame for current syscall
    struct context context;      // Switch context
    struct file *ofile[NOFILE];  // Open files
    struct inode *cwd;           // Current directory
    char name[16];               // Process name (debugging)
};
```

### Process States

```
UNUSED  -> USED    : Process allocated
USED    -> RUNNABLE: Ready to run
RUNNABLE-> RUNNING : Scheduled on CPU
RUNNING -> RUNNABLE: Preempted or yielded
RUNNING -> SLEEPING: Waiting for I/O
SLEEPING-> RUNNABLE: Event occurred
RUNNING -> ZOMBIE  : Exited, waiting for parent
ZOMBIE  -> UNUSED  : Parent called wait()
```

### Context Switch

```c
// kernel/swtch.S
// Save current context, restore new context
swtch:
    // Save old registers
    sd ra, 0(a0)
    sd sp, 8(a0)
    sd s0, 16(a0)
    // ... save s1-s11 ...

    // Load new registers
    ld ra, 0(a1)
    ld sp, 8(a1)
    ld s0, 16(a1)
    // ... load s1-s11 ...

    ret
```

### Scheduling

```c
// kernel/proc.c
void scheduler(void)
{
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    for(;;) {
        // Enable interrupts
        intr_on();

        // Loop over process table
        for(p = proc; p < &proc[NPROC]; p++) {
            acquire(&p->lock);

            if(p->state == RUNNABLE) {
                // Switch to process
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);

                // Process yielded back
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
```

## Memory Management

### Virtual Memory Layout

```
User Space (per process):
0x0000000000000000  Text and data
                    ...
0x0000003FFFFFFFFF  (256GB) - End of user space

Kernel Space (shared):
0xFFFFFFC000000000  Kernel text and data
0xFFFFFFD000000000  Kernel heap
0xFFFFFFD080000000  Trampoline
0xFFFFFFD080001000  Trapframe
```

### Page Table Structure

```
3-level page table (SV39):
Level 2: 512 entries (39-30 bits)
Level 1: 512 entries (29-21 bits)
Level 0: 512 entries (20-12 bits)
Offset:  12 bits (4KB pages)
```

### Virtual Address Translation

```c
// kernel/vm.c
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    if(va >= MAXVA)
        panic("walk");

    for(int level = 2; level > 0; level--) {
        pte_t *pte = &pagetable[PX(level, va)];
        if(*pte & PTE_V) {
            pagetable = (pagetable_t)PTE2PA(*pte);
        } else {
            if(!alloc || (pagetable = kalloc()) == 0)
                return 0;
            memset(pagetable, 0, PGSIZE);
            *pte = PA2PTE(pagetable) | PTE_V;
        }
    }
    return &pagetable[PX(0, va)];
}
```

### Copy-on-Write Implementation

```c
// When forking:
// 1. Mark pages read-only in both parent and child
uvmcopy() {
    for (each page) {
        // Increment reference count
        krefpage(pa);

        // Map as read-only COW in child
        pte = walk(new, va);
        *pte = PA2PTE(pa) | PTE_V | PTE_U | PTE_COW;
    }

    // Also mark parent pages read-only
    for (each page in parent) {
        pte = walk(old, va);
        *pte &= ~PTE_W;  // Remove write permission
        *pte |= PTE_COW; // Mark as COW
    }
}

// On page fault:
usertrap() {
    if (r_scause() == 15) {  // Store page fault
        uint64 va = r_stval();
        pte_t *pte = walk(pagetable, va);

        if (*pte & PTE_COW) {
            // Copy-on-write page
            char *mem = kalloc();
            memmove(mem, (char*)PTE2PA(*pte), PGSIZE);
            *pte = PA2PTE(mem) | PTE_W | PTE_U | PTE_V;

            // Decrement reference count on old page
            kfree((void*)PTE2PA(old_pte));
        }
    }
}
```

## File System

### On-Disk Structure

```
Block 0: Boot sector (unused)
Block 1: Superblock
Blocks 2-(inode_blocks): Inodes
Next blocks: Bitmap (free block tracking)
Remaining: Data blocks
```

### Superblock

```c
// kernel/fs.h
struct superblock {
    uint magic;        // Must be FSMAGIC
    uint size;         // Size of file system (blocks)
    uint nblocks;      // Number of data blocks
    uint ninodes;      // Number of inodes
    uint nlog;         // Number of log blocks
    uint logstart;     // Block number of first log block
    uint inodestart;   // Block number of first inode block
    uint bmapstart;    // Block number of first free map block
};
```

### Inode Structure

```c
// On-disk inode
struct dinode {
    short type;              // File type
    short major;             // Major device number
    short minor;             // Minor device number
    short nlink;             // Number of links
    uint size;               // Size of file (bytes)
    uint addrs[NDIRECT+1];   // Data block addresses
};

// In-memory inode
struct inode {
    uint dev;           // Device number
    uint inum;          // Inode number
    int ref;            // Reference count
    struct sleeplock lock;
    int valid;          // Has inode been read from disk?

    // Copy of disk inode
    short type;
    short major;
    short minor;
    short nlink;
    uint size;
    uint addrs[NDIRECT+1];
};
```

### Buffer Cache

```c
// kernel/bio.c
struct {
    struct spinlock lock;
    struct buf buf[NBUF];
    struct buf head;  // LRU list
} bcache;

struct buf {
    int valid;   // Has data been read from disk?
    int disk;    // Does disk own buf?
    uint dev;
    uint blockno;
    struct sleeplock lock;
    uint refcnt;
    struct buf *prev;
    struct buf *next;
    uchar data[BSIZE];
};
```

### File Operations

```c
// Reading from a file
readi(struct inode *ip, int user_dst, uint64 dst,
      uint off, uint n)
{
    // For each block to read:
    for (tot = 0; tot < n; tot += m, off += m, dst += m) {
        // Get block number from inode
        uint addr = bmap(ip, off / BSIZE);

        // Read block into buffer cache
        struct buf *bp = bread(ip->dev, addr);

        // Copy data to destination
        m = min(n - tot, BSIZE - off % BSIZE);
        if (copyout(dst, bp->data + (off % BSIZE), m) < 0)
            break;

        brelse(bp);
    }
    return tot;
}
```

## Trap Handling

### Trap Types

```
Exceptions (synchronous):
- System calls (ecall instruction)
- Page faults (load/store/instruction)
- Illegal instructions
- Breakpoints

Interrupts (asynchronous):
- Timer interrupts
- Device interrupts (UART, disk)
- Software interrupts
```

### Trap Flow

```
User space -> Trampoline (uservec)
           -> Kernel trap handler (usertrap)
           -> Handle trap
           -> Return to user (userret)
           -> Trampoline (userret)
           -> User space
```

### System Call Mechanism

```c
// User space
// user/usys.S
ecall              // Trap to kernel
ret

// Kernel space
// kernel/trap.c
usertrap()
{
    if (r_scause() == 8) {  // System call
        p->trapframe->epc += 4;  // Advance PC

        intr_on();  // Enable interrupts

        syscall();  // Handle syscall
    }
    usertrapret();
}

// kernel/syscall.c
syscall()
{
    int num = p->trapframe->a7;  // Syscall number

    if (num > 0 && num < NELEM(syscalls)
        && syscalls[num]) {
        p->trapframe->a0 = syscalls[num]();  // Call handler
    } else {
        p->trapframe->a0 = -1;  // Invalid syscall
    }
}
```

## Synchronization

### Spinlocks

```c
// kernel/spinlock.c
void
acquire(struct spinlock *lk)
{
    push_off();  // Disable interrupts

    // Try to acquire lock
    while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
        ;

    __sync_synchronize();
    lk->cpu = mycpu();
}

void
release(struct spinlock *lk)
{
    lk->cpu = 0;
    __sync_synchronize();
    __sync_lock_release(&lk->locked);

    pop_off();  // Re-enable interrupts
}
```

### Sleep Locks

```c
// kernel/sleeplock.c
void
acquiresleep(struct sleeplock *lk)
{
    acquire(&lk->lk);
    while (lk->locked) {
        sleep(lk, &lk->lk);
    }
    lk->locked = 1;
    lk->pid = myproc()->pid;
    release(&lk->lk);
}

void
releasesleep(struct sleeplock *lk)
{
    acquire(&lk->lk);
    lk->locked = 0;
    lk->pid = 0;
    wakeup(lk);
    release(&lk->lk);
}
```

### Sleep/Wakeup

```c
// kernel/proc.c
void
sleep(void *chan, struct spinlock *lk)
{
    struct proc *p = myproc();

    acquire(&p->lock);
    release(lk);

    p->chan = chan;
    p->state = SLEEPING;

    sched();  // Give up CPU

    p->chan = 0;
    release(&p->lock);
    acquire(lk);
}

void
wakeup(void *chan)
{
    struct proc *p;

    for(p = proc; p < &proc[NPROC]; p++) {
        if(p != myproc()) {
            acquire(&p->lock);
            if(p->state == SLEEPING && p->chan == chan) {
                p->state = RUNNABLE;
            }
            release(&p->lock);
        }
    }
}
```

## Device Drivers

### UART Driver

```c
// kernel/uart.c
void
uartinit(void)
{
    // Disable interrupts
    WriteReg(IER, 0x00);

    // Enable FIFO
    WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);

    // 8-bit chars, no parity, one stop bit
    WriteReg(LCR, LCR_EIGHT_BITS);

    // Enable receive interrupts
    WriteReg(IER, IER_RX_ENABLE);
}

void
uartputc(int c)
{
    acquire(&uart_tx_lock);

    while(1) {
        if(ReadReg(LSR) & LSR_TX_IDLE) {
            WriteReg(THR, c);
            break;
        }
    }

    release(&uart_tx_lock);
}
```

### Virtio Disk Driver

```c
// kernel/virtio_disk.c
void
virtio_disk_rw(struct buf *b, int write)
{
    acquire(&disk.vdisk_lock);

    // Allocate descriptor chain
    int idx[3];
    idx[0] = alloc_desc();
    idx[1] = alloc_desc();
    idx[2] = alloc_desc();

    // Format descriptor chain
    disk.desc[idx[0]].addr = (uint64)&disk.ops[idx[0]];
    disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    disk.desc[idx[0]].next = idx[1];

    disk.desc[idx[1]].addr = (uint64)b->data;
    disk.desc[idx[1]].len = BSIZE;
    disk.desc[idx[1]].flags = write ? 0 : VRING_DESC_F_WRITE;
    disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    disk.desc[idx[1]].next = idx[2];

    disk.info[idx[0]].b = b;
    disk.info[idx[0]].status = 0xff;

    disk.desc[idx[2]].addr = (uint64)&disk.info[idx[0]].status;
    disk.desc[idx[2]].len = 1;
    disk.desc[idx[2]].flags = VRING_DESC_F_WRITE;
    disk.desc[idx[2]].next = 0;

    // Add to available ring
    disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    __sync_synchronize();
    disk.avail->idx += 1;
    __sync_synchronize();

    // Notify device
    *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;

    // Wait for completion
    while(b->disk == 1) {
        sleep(b, &disk.vdisk_lock);
    }

    release(&disk.vdisk_lock);
}
```

## Debugging Kernel Code

### Using GDB

```sh
# Terminal 1
make qemu-gdb

# Terminal 2
gdb-multiarch kernel/kernel
(gdb) target remote :26000
(gdb) b main
(gdb) c
(gdb) p *myproc()
```

### Common Breakpoints

```
main         - Kernel entry
userinit     - First process creation
fork         - Process creation
exec         - Program loading
usertrap     - Trap handler
syscall      - System call dispatcher
```

### Kernel Debugging Macros

```c
// Add to kernel code
#define DEBUG 1

#if DEBUG
#define DPRINTF(fmt, ...) printf(fmt, ##__VA_ARGS__)
#else
#define DPRINTF(fmt, ...)
#endif

// Usage
DPRINTF("fork: new pid = %d\n", np->pid);
```

---

This document provides deep technical details for developers working on the kernel. For higher-level concepts, see [architecture.md](architecture.md).
