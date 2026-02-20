# Design Decisions

This document explains the key design decisions made in Enhanced Xv6 and the rationale behind them.

## Architecture Choices

### RISC-V ISA

**Decision**: Use RISC-V instead of x86

**Rationale**:
- Simpler instruction set makes the code easier to understand
- Open-source ISA with growing industry adoption
- Modern architecture without legacy baggage
- Better suited for educational purposes
- Good QEMU support

**Trade-offs**:
- Less familiar to students coming from x86 background
- Fewer real hardware options for testing
- Smaller ecosystem compared to x86

### Monolithic Kernel

**Decision**: Keep a monolithic kernel architecture

**Rationale**:
- Simpler to understand and implement
- Better performance for a teaching OS
- Easier debugging and development
- Consistent with original xv6 philosophy
- Avoids IPC complexity

**Trade-offs**:
- Less modularity than microkernel
- Kernel bugs can crash the entire system
- Harder to isolate security issues

**Future Consideration**: May add experimental microkernel branch for research

## Memory Management

### Copy-on-Write Fork

**Decision**: Implement COW for fork() system call

**Rationale**:
- Dramatically reduces memory copying overhead
- Common optimization in modern OSes
- Good learning example of lazy evaluation
- Improves performance without sacrificing simplicity

**Implementation Details**:
- Mark pages read-only in both parent and child
- Handle page faults to create physical copies
- Reference counting for shared pages
- Clear COW bit when last reference is removed

### Demand Paging

**Decision**: Use demand paging with page fault handling

**Rationale**:
- More realistic behavior compared to eager allocation
- Reduces memory waste
- Demonstrates important OS concept
- Allows programs to use more virtual memory

**Trade-offs**:
- More complex than static allocation
- Page faults add runtime overhead
- Requires careful handling of edge cases

### Page Size

**Decision**: Use 4KB pages

**Rationale**:
- Standard page size in most systems
- Good balance between fragmentation and overhead
- Matches RISC-V MMU capabilities
- Well-supported by QEMU

## Process Management

### Round-Robin Scheduling

**Decision**: Start with simple round-robin scheduler

**Rationale**:
- Easy to understand and implement
- Fair time distribution among processes
- No starvation issues
- Good baseline for comparison

**Planned Evolution**: Will upgrade to MLFQ in future versions

### Process Table Size

**Decision**: Fixed-size process table (64 entries)

**Rationale**:
- Simpler implementation
- Sufficient for educational workloads
- Avoids dynamic memory complexity
- Clear resource limits

**Trade-offs**:
- Hard limit on concurrent processes
- Wastes memory if not fully utilized

## File System

### Simple File System Design

**Decision**: Keep the simple xv6 file system with minor enhancements

**Rationale**:
- Readable in a few hours
- Demonstrates core FS concepts
- Easy to modify and experiment with
- No dependencies on complex data structures

**Enhancements Added**:
- Extended metadata support
- Buffer cache optimization
- Better error handling

### Block Size

**Decision**: 1KB block size

**Rationale**:
- Matches original xv6 design
- Good for small files common in teaching environment
- Simple bitmap management
- Low internal fragmentation for small FS

### No Symbolic Links (Yet)

**Decision**: Defer symbolic link implementation

**Rationale**:
- Adds complexity to path resolution
- Not essential for teaching core concepts
- Can be added later without breaking compatibility

## System Calls

### Conservative API Extensions

**Decision**: Only add system calls that serve clear educational purposes

**Rationale**:
- Avoid bloat and feature creep
- Each syscall should teach something new
- Maintain code simplicity
- Focus on quality over quantity

**Criteria for New Syscalls**:
1. Demonstrates important OS concept
2. Commonly used in real systems
3. Reasonable implementation complexity
4. Good teaching value

### User-Space Error Handling

**Decision**: Return -1 on errors, don't use errno

**Rationale**:
- Simpler than errno mechanism
- Sufficient for educational purposes
- Less code to maintain
- Easier for students to trace

**Trade-off**: Less detailed error information

## Synchronization

### Simple Spinlocks

**Decision**: Use spinlocks for kernel synchronization

**Rationale**:
- Easy to understand and implement
- Good performance in low-contention scenarios
- Demonstrates fundamental locking concept
- Works well with short critical sections

**Careful Considerations**:
- Disable interrupts while holding spinlocks
- Avoid nested locks where possible
- Keep critical sections short

### No Condition Variables (Yet)

**Decision**: Implement sleep/wakeup instead of condition variables

**Rationale**:
- Simpler abstraction
- Sufficient for kernel needs
- Easier to understand for beginners
- Follows original xv6 design

## Device Drivers

### Minimal Driver Set

**Decision**: Only include essential drivers (UART, disk)

**Rationale**:
- Reduces codebase size
- Focus on OS concepts, not hardware details
- QEMU provides simple virtual devices
- Easier to understand driver architecture

**Future Additions**: Network card, USB controller (for learning purposes)

## Shell Design

### Built-in vs External Commands

**Decision**: Most commands are external programs

**Rationale**:
- Cleaner shell implementation
- Demonstrates process creation
- More Unix-like behavior
- Easier to add new commands

**Built-ins**: Only `cd` (requires changing shell's own directory)

### Redirection and Pipes

**Decision**: Support basic I/O redirection and pipes

**Rationale**:
- Essential Unix concept
- Demonstrates file descriptor manipulation
- Teaches process communication
- Common in real systems

## Performance vs Clarity

### Core Principle

**Decision**: Always prefer clarity over performance

**Rationale**:
- Primary goal is education, not production use
- Readable code is more valuable for learning
- Simple algorithms are easier to understand
- Performance can be addressed in specific areas when it teaches something

**Examples**:
- Linear search in process table (simple but O(n))
- Simple buffer cache (not LRU, but easier to understand)
- Synchronous I/O (no async complexity)

### Selected Optimizations

**Decision**: Add optimizations that teach important concepts

**Included**:
- COW fork (teaches lazy evaluation)
- Buffer cache (teaches caching concepts)
- Demand paging (teaches virtual memory)

**Excluded**:
- Lock-free algorithms (too complex)
- Advanced scheduling (deferred to roadmap)
- Sophisticated FS indexing (unnecessary)

## Testing Philosophy

### Automated Test Suite

**Decision**: Maintain comprehensive test suite

**Rationale**:
- Catch regressions early
- Document expected behavior
- Enable confident refactoring
- Teach testing practices

### Manual Testing

**Decision**: Also support manual testing and exploration

**Rationale**:
- Interactive learning valuable for students
- Not everything can be automated
- Encourages experimentation
- More engaging than just running tests

## Documentation Strategy

### Code Comments

**Decision**: Comment intent and invariants, not obvious code

**Rationale**:
- Explain "why", not "what"
- Trust readers can understand C
- Keep comments synchronized with code
- Focus on non-obvious aspects

### External Documentation

**Decision**: Maintain separate documentation files

**Rationale**:
- High-level overviews don't fit in code
- Better for learning workflows
- Easier to update and organize
- More accessible to newcomers

## Backward Compatibility

### No Compatibility Guarantees

**Decision**: Free to break compatibility between versions

**Rationale**:
- Educational project, not production system
- Allows better designs to replace old ones
- Reduces technical debt
- Simplifies codebase evolution

**Mitigation**: Document breaking changes in release notes

## Version Control

### Git History

**Decision**: Keep clean, meaningful commit history

**Rationale**:
- Easy to trace changes
- Valuable learning resource
- Helps understand evolution
- Enables bisecting bugs

**Practices**:
- Descriptive commit messages
- Atomic commits
- No force-pushes to main
- Squash noisy commits

---

*These decisions are not set in stone. As the project evolves and we learn from experience, some decisions may be revisited. We welcome discussion on any design choice.*
