# Security in Enhanced Xv6

This document covers security features, vulnerabilities, and best practices in Enhanced Xv6.

## Security Model

### Design Goals

Enhanced Xv6 is a **teaching operating system**, not designed for production security. However, it demonstrates fundamental OS security concepts:

1. **Process Isolation**: Separate address spaces
2. **Privilege Separation**: Kernel vs. user mode
3. **Resource Protection**: File permissions and access control
4. **System Call Validation**: Checking user-provided arguments

### Non-Goals

xv6 intentionally **does not** include:
- Network security (no network stack yet)
- Cryptography (no encryption primitives)
- Advanced access control (no SELinux-like features)
- Audit logging
- Secure boot

## Security Features

### Memory Protection

#### Address Space Isolation

Each process has its own page table:
```c
// Kernel ensures user processes cannot access:
// - Other processes' memory
// - Kernel memory (except via syscalls)
// - Physical memory directly
```

**Protection Mechanism**:
- User mode cannot access kernel pages (supervisor bit)
- Page tables prevent cross-process access
- Invalid addresses trigger page faults

#### Kernel/User Separation

```c
// User code runs in U-mode (unprivileged)
// Kernel code runs in S-mode (supervisor)
// Transition via trap mechanism
```

**Protected Operations**:
- I/O operations (must use system calls)
- Memory management (cannot modify page tables)
- Interrupt handling (handled by kernel only)

### System Call Security

#### Argument Validation

All system calls validate user-provided pointers:

```c
// Example from kernel
int
sys_write(void)
{
    int fd;
    uint64 addr;
    int n;

    // Fetch arguments
    argint(0, &fd);
    argaddr(1, &addr);
    argint(2, &n);

    // Validate fd
    if (fd < 0 || fd >= NOFILE)
        return -1;

    // Validate address range
    if (!is_valid_user_addr(addr, n))
        return -1;

    // Proceed with write
    // ...
}
```

**Checks Performed**:
- Pointer in user space (not kernel)
- Entire buffer accessible
- File descriptor valid
- Permission checks

#### Preventing Kernel Exploits

**Dangerous**:
```c
// Bad: trusting user pointer
char *user_ptr = (char*)addr;
strcpy(kernel_buf, user_ptr);  // Could fault!
```

**Safe**:
```c
// Good: copying safely
if (copyin(p->pagetable, kernel_buf, addr, n) < 0)
    return -1;
```

### File System Security

#### Basic Permissions

Currently limited permissions:
```c
// File ownership tracked by inode
// Access control: owner can read/write/delete
```

**Limitations**:
- No multi-user support (single user system)
- No file permissions (rwx bits)
- No groups or ACLs

#### Path Traversal Protection

```c
// Prevents: open("../../kernel/proc.c")
// Path resolution stops at root
```

## Common Vulnerabilities

### Buffer Overflows

**Vulnerable Code**:
```c
char buf[100];
// No bounds checking!
read(fd, buf, 1000);  // Overflow!
```

**Safe Code**:
```c
char buf[100];
int n = read(fd, buf, sizeof(buf));  // Bounded
```

### Integer Overflows

**Vulnerable**:
```c
int size = user_input;
char *buf = malloc(size);  // What if size < 0?
```

**Safe**:
```c
int size = user_input;
if (size < 0 || size > MAX_SIZE)
    return -1;
char *buf = malloc(size);
```

### Use-After-Free

**Vulnerable**:
```c
struct file *f = get_file(fd);
close_file(f);  // Frees f
write_file(f, buf, n);  // Use after free!
```

**Safe**:
```c
struct file *f = get_file(fd);
write_file(f, buf, n);
close_file(f);  // Use, then free
```

### Race Conditions

**Vulnerable** (Time-of-Check-Time-of-Use):
```c
if (file_exists("temp.txt")) {
    // Race window here!
    fd = open("temp.txt", O_RDONLY);
}
```

**Better**:
```c
fd = open("temp.txt", O_RDONLY);
if (fd < 0) {
    // Handle error
}
```

### Null Pointer Dereferences

**Vulnerable**:
```c
struct proc *p = find_proc(pid);
p->state = RUNNING;  // Crash if p == NULL
```

**Safe**:
```c
struct proc *p = find_proc(pid);
if (p == NULL)
    return -1;
p->state = RUNNING;
```

## Security Best Practices

### Writing Secure System Calls

```c
int
sys_my_syscall(void)
{
    uint64 user_addr;
    int size;

    // 1. Fetch arguments
    argaddr(0, &user_addr);
    argint(1, &size);

    // 2. Validate arguments
    if (size < 0 || size > MAX_ALLOWED)
        return -1;

    // 3. Validate user addresses
    if (!is_valid_user_range(user_addr, size))
        return -1;

    // 4. Copy from user space safely
    char kernel_buf[MAX_SIZE];
    if (copyin(myproc()->pagetable, kernel_buf,
               user_addr, size) < 0)
        return -1;

    // 5. Perform operation
    // ...

    // 6. Copy results back safely
    if (copyout(myproc()->pagetable, user_addr,
                result, size) < 0)
        return -1;

    return 0;
}
```

### Safe User Programs

#### Check Return Values

```c
int fd = open("file.txt", O_RDONLY);
if (fd < 0) {
    printf("Error opening file\n");
    exit(1);
}
```

#### Bounds Checking

```c
char buf[256];
int n = read(fd, buf, sizeof(buf) - 1);  // Leave room for null
if (n > 0) {
    buf[n] = '\0';  // Null terminate
}
```

#### Safe String Operations

```c
// Avoid unbounded operations
gets(buf);           // NEVER use
scanf("%s", buf);    // NEVER use

// Use bounded versions
fgets(buf, sizeof(buf), stdin);     // Safe
```

### Kernel Development Guidelines

1. **Always validate user pointers** before dereferencing
2. **Use `copyin`/`copyout`** instead of direct access
3. **Check array bounds** before indexing
4. **Validate ranges** (check for negative, too large)
5. **Hold appropriate locks** when accessing shared data
6. **Clean up resources** on all error paths
7. **Avoid integer overflows** in size calculations

## Testing for Security Issues

### Fuzzing System Calls

```c
// Test with random/invalid inputs
int
fuzz_test(void)
{
    // Try invalid file descriptors
    read(-1, buf, 100);
    write(999, buf, 100);

    // Try invalid addresses
    read(0, (void*)0xFFFFFFFF, 100);

    // Try huge sizes
    read(0, buf, -1);

    // All should fail gracefully, not crash
    exit(0);
}
```

### Stress Testing

```c
// Create many processes
for (int i = 0; i < 100; i++) {
    if (fork() == 0) {
        // Do work
        exit(0);
    }
}

// Wait for all
for (int i = 0; i < 100; i++) {
    wait(0);
}
```

### Memory Testing

```c
// Try to access kernel memory (should fail)
int
test_kernel_access(void)
{
    // Attempt to read kernel memory
    char *kernel_addr = (char*)0x80000000;
    char c = *kernel_addr;  // Should trap

    // Should never reach here
    printf("SECURITY FAILURE!\n");
    exit(1);
}
```

## Known Limitations

### Current Security Gaps

1. **No user authentication**: Single-user system
2. **No file permissions**: Any process can access any file
3. **No resource limits**: Process can use all memory
4. **No network security**: No network stack yet
5. **No encryption**: No crypto primitives
6. **Simple scheduler**: Potential DoS via CPU hogging

### Educational Value

These limitations are **intentional** for teaching:
- Simpler codebase
- Focus on core concepts
- Easier to understand
- Room for student projects

## Future Security Enhancements

### Short-term (Roadmap v2.0)

- [ ] File permissions (rwx bits)
- [ ] User authentication
- [ ] Basic resource limits
- [ ] Enhanced system call validation

### Long-term (Roadmap v3.0)

- [ ] Multi-user support
- [ ] Access control lists (ACLs)
- [ ] Capability-based security
- [ ] Security audit logging
- [ ] Basic cryptography support

## Security Research Topics

### Student Projects

1. **Add file permissions**: Implement Unix-style rwx bits
2. **Resource limits**: Limit memory, CPU, file descriptors
3. **Sandboxing**: Restricted execution environments
4. **Audit logging**: Track security-relevant events
5. **Vulnerability analysis**: Find and fix security bugs

### Advanced Topics

1. **Capability-based security**: Replace UIDs with capabilities
2. **Memory safety**: Add bounds checking, canaries
3. **Formal verification**: Prove security properties
4. **Trusted boot**: Verify kernel integrity
5. **Compartmentalization**: Isolate kernel components

## Security Resources

### Learning Materials

- "Operating Systems: Three Easy Pieces" - Security chapter
- "The Design and Implementation of the FreeBSD Operating System"
- "A Nine Year Study of File System and Storage Benchmarking"
- MIT 6.858 Computer Systems Security course

### Common Vulnerabilities

- **CWE-119**: Buffer overflow
- **CWE-20**: Improper input validation
- **CWE-362**: Race conditions (TOCTOU)
- **CWE-476**: NULL pointer dereference
- **CWE-190**: Integer overflow

## Reporting Security Issues

Since this is an educational project, security issues are learning opportunities:

1. **Open a GitHub issue** describing the vulnerability
2. **Provide a proof-of-concept** if possible
3. **Suggest a fix** or mitigation
4. **Label with "security"** for visibility

All reports are welcome and help improve the codebase!

---

**Remember**: Enhanced Xv6 is for **learning**, not production use. Security features are simplified to focus on teaching fundamental concepts.
