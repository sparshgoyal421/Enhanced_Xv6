# Glossary

A comprehensive glossary of terms used in Enhanced Xv6.

## A

**Address Space**
The range of memory addresses that a process can access. Each process has its own virtual address space.

**Atomic Operation**
An operation that completes in its entirety without interruption, appearing indivisible to other threads or processes.

## B

**Block Device**
A device that transfers data in fixed-size blocks (e.g., disk drives).

**Boot Loader**
Software that loads the operating system kernel into memory and transfers control to it.

**Buffer Cache**
A cache of disk blocks in memory to reduce the number of disk accesses.

## C

**Character Device**
A device that transfers data one character at a time (e.g., keyboard, serial port).

**Context Switch**
The process of saving the state of a running process and loading the state of another process to run.

**Copy-on-Write (COW)**
An optimization where pages are shared between processes until one attempts to write, at which point a copy is made.

**Critical Section**
A section of code that accesses shared resources and must not be executed by multiple threads simultaneously.

## D

**Deadlock**
A situation where two or more processes are unable to proceed because each is waiting for the other to release a resource.

**Demand Paging**
A memory management technique where pages are loaded into memory only when they are accessed.

**Direct Block**
A disk block number stored directly in an inode.

**DMA (Direct Memory Access)**
A feature allowing hardware devices to access memory directly without CPU involvement.

## E

**ecall**
The RISC-V instruction used to make system calls, causing a trap to supervisor mode.

**Exception**
A synchronous event triggered by program execution (e.g., page fault, illegal instruction).

**exec**
System call that replaces the current process's memory with a new program.

## F

**File Descriptor**
An integer that identifies an open file in a process. Standard descriptors: 0 (stdin), 1 (stdout), 2 (stderr).

**Fork**
System call that creates a new process by duplicating the calling process.

**Free List**
A linked list of free memory pages or disk blocks available for allocation.

## G

**GDB (GNU Debugger)**
A debugger that can be used to debug xv6 kernel code.

## I

**Indirect Block**
A disk block that contains pointers to other blocks rather than data directly.

**Inode**
A data structure that stores metadata about a file (type, size, location of data blocks).

**Interrupt**
An asynchronous event signaled by hardware (e.g., timer, disk completion).

**Interrupt Handler**
Kernel code that responds to interrupts.

## K

**Kernel**
The core of the operating system that manages hardware and system resources.

**Kernel Mode**
Privileged execution mode with full access to hardware (called supervisor mode in RISC-V).

**Kernel Stack**
A per-process stack used when executing in kernel mode.

## L

**Lock**
A synchronization primitive that ensures mutual exclusion in accessing shared resources.

**LRU (Least Recently Used)**
A cache replacement policy that evicts the least recently used item.

## M

**MMU (Memory Management Unit)**
Hardware that translates virtual addresses to physical addresses using page tables.

**Mutex (Mutual Exclusion)**
A lock that allows only one thread to access a resource at a time.

## N

**NBUF**
The number of buffers in the buffer cache (default: 30).

**NPROC**
The maximum number of processes (default: 64).

## P

**Page**
A fixed-size unit of memory (4KB in xv6).

**Page Fault**
An exception that occurs when a process accesses a virtual address not currently mapped in physical memory.

**Page Table**
A data structure used by the MMU to map virtual addresses to physical addresses.

**PID (Process ID)**
A unique identifier for each process.

**Pipe**
A unidirectional communication channel between processes.

**PTE (Page Table Entry)**
An entry in a page table that maps a virtual page to a physical page.

**Preemption**
Forcibly interrupting a running process to schedule another process.

## Q

**QEMU**
An emulator that simulates RISC-V hardware for running xv6.

**Quantum**
The time slice allocated to a process before it can be preempted.

## R

**Race Condition**
A bug where the behavior depends on the relative timing of events (e.g., two threads accessing shared data).

**Reference Count**
A count of how many references exist to a resource (used for COW pages).

**RISC-V**
The instruction set architecture used by Enhanced Xv6.

**Round-Robin**
A scheduling algorithm that allocates CPU time equally to all processes in a circular order.

## S

**Scheduler**
Kernel code that selects which process to run next.

**Semaphore**
A synchronization primitive that can allow multiple threads to access a resource (generalization of a lock).

**Sleep Lock**
A lock that puts the waiting process to sleep instead of spinning (used for long critical sections).

**Spinlock**
A lock where the waiting process continuously checks (spins) until the lock is available.

**Superblock**
The first block of a file system containing metadata about the file system structure.

**Supervisor Mode**
Privileged execution mode in RISC-V (kernel mode).

**SV39**
The 39-bit virtual addressing mode used by xv6 on RISC-V.

**Swapping**
Moving pages between memory and disk to free up physical memory.

**System Call**
An interface for user programs to request services from the kernel.

## T

**TLB (Translation Lookaside Buffer)**
A hardware cache of recent virtual-to-physical address translations.

**TOCTOU (Time-of-Check-Time-of-Use)**
A race condition where a resource changes between checking and using it.

**Trap**
A transfer of control to the kernel, caused by exceptions or interrupts.

**Trapframe**
A structure that saves user register state when entering the kernel.

**Trampoline**
Code that switches between user and kernel page tables during traps.

## U

**User Mode**
Unprivileged execution mode where user programs run.

**User Space**
The portion of virtual address space accessible to user programs.

## V

**Virtual Address**
An address used by programs that is translated to a physical address by the MMU.

**Virtual Memory**
A memory management technique that gives each process its own address space, potentially larger than physical memory.

**Virtio**
A standardized interface for virtual devices used by QEMU.

## W

**Wait**
System call where a parent process waits for a child process to terminate.

**Wakeup**
Operation that makes sleeping processes runnable.

## Z

**Zombie**
A process that has exited but whose exit status has not yet been collected by its parent.

---

## Common Acronyms

- **COW** - Copy-on-Write
- **CPU** - Central Processing Unit
- **DMA** - Direct Memory Access
- **FS** - File System
- **GDB** - GNU Debugger
- **I/O** - Input/Output
- **IPC** - Inter-Process Communication
- **ISA** - Instruction Set Architecture
- **LRU** - Least Recently Used
- **MMU** - Memory Management Unit
- **OS** - Operating System
- **PC** - Program Counter
- **PID** - Process ID
- **PTE** - Page Table Entry
- **RISC** - Reduced Instruction Set Computer
- **SMP** - Symmetric Multi-Processing
- **TLB** - Translation Lookaside Buffer
- **UART** - Universal Asynchronous Receiver/Transmitter
- **VFS** - Virtual File System

---

## See Also

- [API Reference](api-reference.md) - System call documentation
- [Architecture](architecture.md) - System overview
- [FAQ](faq.md) - Frequently asked questions
