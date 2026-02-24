# Code Style Guide

This guide defines coding conventions for Enhanced Xv6.

## General Principles

- **Clarity over cleverness** — write code that is easy to read and understand
- **Consistency** — follow existing patterns in the codebase
- **Simplicity** — avoid unnecessary abstractions

## C Style

### Indentation

Use **tabs** for indentation (matches original xv6 style):

```c
// Good
void
foo(void)
{
    if (x) {
        bar();
    }
}
```

### Braces

Opening brace on the **same line** for control structures, **new line** for functions:

```c
// Function: brace on new line
void
myfunc(void)
{
    // ...
}

// Control flow: brace on same line
if (condition) {
    do_something();
} else {
    do_other();
}
```

### Naming

| Type | Convention | Example |
|------|-----------|---------|
| Functions | lowercase, underscores | `alloc_page()` |
| Variables | lowercase, underscores | `page_count` |
| Constants | uppercase, underscores | `MAX_PAGES` |
| Structs | lowercase | `struct proc` |
| Types | lowercase | `uint64` |

### Comments

Use `//` for single-line, `/* */` for multi-line:

```c
// Single line comment

/*
 * Multi-line comment for
 * complex explanations
 */
```

Comment the **why**, not the **what**:

```c
// Bad: increment i
i++;

// Good: skip null terminator
i++;
```

### Function Signatures

Return type on its own line:

```c
// Good
int
sys_fork(void)
{
    return fork();
}

// Bad
int sys_fork(void) {
    return fork();
}
```

### Error Handling

Always check return values and return `-1` on error:

```c
int fd = open(path, O_RDONLY);
if (fd < 0)
    return -1;
```

## Assembly Style

```asm
# Use # for comments
# Label on its own line
label:
    instruction  # inline comment
```

## Makefile Style

- Use tabs for recipe indentation
- Group related targets together
- Add comments for non-obvious targets

## Commit Messages

Follow this format:

```
Short summary (50 chars or less)

Optional longer description explaining why the change
was made, not what was changed.
```

Examples:
- `Add COW fork implementation`
- `Fix race condition in wakeup`
- `proc: increase NPROC to 128`

## File Organization

```
kernel/   - Kernel source files
user/     - User space programs
docs/     - Documentation
tester/   - Test scripts
```

New kernel files go in `kernel/`, new user programs in `user/`.

---

When in doubt, match the style of surrounding code.
