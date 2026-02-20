# Programming Examples

This guide provides practical examples for programming in Enhanced Xv6.

## Basic User Programs

### Hello World

```c
#include "kernel/types.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
    printf("Hello, Enhanced Xv6!\n");
    exit(0);
}
```

**Build and Run**:
1. Save as `user/hello.c`
2. Add `$U/_hello\` to `UPROGS` in Makefile
3. Run `make qemu`
4. Execute `hello` in the shell

### Command-Line Arguments

```c
#include "kernel/types.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
    if (argc < 2) {
        printf("Usage: greet <name>\n");
        exit(1);
    }

    printf("Hello, %s!\n", argv[1]);
    exit(0);
}
```

## Process Management

### Creating Processes with Fork

```c
#include "kernel/types.h"
#include "user/user.h"

int
main(void)
{
    int pid = fork();

    if (pid < 0) {
        printf("fork failed\n");
        exit(1);
    }

    if (pid == 0) {
        // Child process
        printf("I am the child (PID: %d)\n", getpid());
    } else {
        // Parent process
        printf("I am the parent (PID: %d, child: %d)\n",
               getpid(), pid);
        wait(0);  // Wait for child to finish
    }

    exit(0);
}
```

### Executing Programs

```c
#include "kernel/types.h"
#include "user/user.h"

int
main(void)
{
    int pid = fork();

    if (pid == 0) {
        // Child executes ls
        char *argv[] = {"ls", 0};
        exec("ls", argv);
        printf("exec failed\n");
        exit(1);
    }

    wait(0);
    printf("Child finished\n");
    exit(0);
}
```

### Process Chain

```c
#include "kernel/types.h"
#include "user/user.h"

int
main(void)
{
    for (int i = 0; i < 3; i++) {
        int pid = fork();

        if (pid < 0) {
            printf("fork failed\n");
            exit(1);
        }

        if (pid == 0) {
            printf("Process %d (PID: %d)\n", i, getpid());
            exit(0);
        }
    }

    // Parent waits for all children
    for (int i = 0; i < 3; i++) {
        wait(0);
    }

    printf("All children finished\n");
    exit(0);
}
```

## File Operations

### Reading Files

```c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
    if (argc < 2) {
        printf("Usage: readfile <filename>\n");
        exit(1);
    }

    int fd = open(argv[1], 0);  // O_RDONLY
    if (fd < 0) {
        printf("Cannot open %s\n", argv[1]);
        exit(1);
    }

    char buf[512];
    int n;
    while ((n = read(fd, buf, sizeof(buf))) > 0) {
        write(1, buf, n);  // Write to stdout
    }

    close(fd);
    exit(0);
}
```

### Writing Files

```c
#include "kernel/types.h"
#include "kernel/fcntl.h"
#include "user/user.h"

int
main(void)
{
    int fd = open("output.txt", O_CREATE | O_WRONLY);
    if (fd < 0) {
        printf("Cannot create file\n");
        exit(1);
    }

    char *message = "Hello from Enhanced Xv6\n";
    write(fd, message, strlen(message));

    close(fd);
    printf("File written successfully\n");
    exit(0);
}
```

### File Information

```c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
    if (argc < 2) {
        printf("Usage: fileinfo <filename>\n");
        exit(1);
    }

    struct stat st;
    if (stat(argv[1], &st) < 0) {
        printf("Cannot stat %s\n", argv[1]);
        exit(1);
    }

    printf("File: %s\n", argv[1]);
    printf("Type: %d\n", st.type);
    printf("Inode: %d\n", st.ino);
    printf("Size: %d bytes\n", st.size);

    exit(0);
}
```

## Inter-Process Communication

### Pipes

```c
#include "kernel/types.h"
#include "user/user.h"

int
main(void)
{
    int fds[2];
    char buf[100];

    // Create pipe
    if (pipe(fds) < 0) {
        printf("pipe failed\n");
        exit(1);
    }

    int pid = fork();

    if (pid == 0) {
        // Child: read from pipe
        close(fds[1]);  // Close write end
        int n = read(fds[0], buf, sizeof(buf));
        printf("Child received: %s\n", buf);
        close(fds[0]);
    } else {
        // Parent: write to pipe
        close(fds[0]);  // Close read end
        char *msg = "Hello from parent";
        write(fds[1], msg, strlen(msg) + 1);
        close(fds[1]);
        wait(0);
    }

    exit(0);
}
```

### Pipe Chain (Pipeline)

```c
#include "kernel/types.h"
#include "user/user.h"

int
main(void)
{
    int fds[2];
    pipe(fds);

    if (fork() == 0) {
        // First child: execute 'ls'
        close(1);           // Close stdout
        dup(fds[1]);        // Redirect stdout to pipe write
        close(fds[0]);
        close(fds[1]);

        char *argv[] = {"ls", 0};
        exec("ls", argv);
        exit(1);
    }

    if (fork() == 0) {
        // Second child: execute 'grep'
        close(0);           // Close stdin
        dup(fds[0]);        // Redirect stdin to pipe read
        close(fds[0]);
        close(fds[1]);

        char *argv[] = {"grep", "README", 0};
        exec("grep", argv);
        exit(1);
    }

    // Parent closes pipe and waits
    close(fds[0]);
    close(fds[1]);
    wait(0);
    wait(0);

    exit(0);
}
```

## Memory Management

### Dynamic Allocation with sbrk

```c
#include "kernel/types.h"
#include "user/user.h"

int
main(void)
{
    // Allocate 4096 bytes
    char *ptr = sbrk(4096);
    if (ptr == (char*)-1) {
        printf("sbrk failed\n");
        exit(1);
    }

    // Use the memory
    for (int i = 0; i < 4096; i++) {
        ptr[i] = 'A';
    }

    printf("Memory allocated and initialized\n");

    // Free memory (shrink heap)
    sbrk(-4096);

    exit(0);
}
```

### Simple Memory Pool

```c
#include "kernel/types.h"
#include "user/user.h"

#define POOL_SIZE 8192

char memory_pool[POOL_SIZE];
int pool_offset = 0;

void*
my_malloc(int size)
{
    if (pool_offset + size > POOL_SIZE) {
        return 0;  // Out of memory
    }

    void *ptr = &memory_pool[pool_offset];
    pool_offset += size;
    return ptr;
}

int
main(void)
{
    char *str1 = my_malloc(100);
    char *str2 = my_malloc(200);

    if (str1 && str2) {
        strcpy(str1, "First allocation");
        strcpy(str2, "Second allocation");

        printf("%s\n", str1);
        printf("%s\n", str2);
    }

    exit(0);
}
```

## System Utilities

### Simple Shell

```c
#include "kernel/types.h"
#include "user/user.h"

#define MAX_ARGS 10

int
main(void)
{
    char buf[100];
    char *argv[MAX_ARGS];

    while (1) {
        printf("$ ");

        // Read command
        gets(buf, sizeof(buf));

        if (buf[0] == 0) continue;

        // Parse arguments
        int argc = 0;
        char *p = buf;
        while (*p && argc < MAX_ARGS - 1) {
            while (*p == ' ') p++;
            if (*p == 0) break;

            argv[argc++] = p;
            while (*p && *p != ' ') p++;
            if (*p) *p++ = 0;
        }
        argv[argc] = 0;

        if (strcmp(argv[0], "exit") == 0) {
            break;
        }

        // Execute command
        int pid = fork();
        if (pid == 0) {
            exec(argv[0], argv);
            printf("exec %s failed\n", argv[0]);
            exit(1);
        }
        wait(0);
    }

    exit(0);
}
```

### Process Monitor

```c
#include "kernel/types.h"
#include "user/user.h"

int
main(void)
{
    printf("Process Monitor\n");
    printf("PID\tCommand\n");
    printf("---\t-------\n");

    // Note: This is a simplified example
    // Real implementation would use a system call
    // to get process information

    printf("%d\tmonitor\n", getpid());

    exit(0);
}
```

## Testing Utilities

### Unit Test Framework

```c
#include "kernel/types.h"
#include "user/user.h"

int tests_run = 0;
int tests_passed = 0;

#define ASSERT(test, msg) do { \
    tests_run++; \
    if (test) { \
        tests_passed++; \
        printf("✓ %s\n", msg); \
    } else { \
        printf("✗ %s\n", msg); \
    } \
} while (0)

void
test_string_functions(void)
{
    ASSERT(strlen("hello") == 5, "strlen works");
    ASSERT(strcmp("abc", "abc") == 0, "strcmp equal");
    ASSERT(strcmp("abc", "def") < 0, "strcmp less than");
}

void
test_file_operations(void)
{
    int fd = open("test.txt", O_CREATE | O_WRONLY);
    ASSERT(fd >= 0, "file creation");

    write(fd, "test", 4);
    close(fd);

    fd = open("test.txt", O_RDONLY);
    char buf[10];
    int n = read(fd, buf, 10);
    ASSERT(n == 4, "file read");
    close(fd);

    unlink("test.txt");
}

int
main(void)
{
    printf("Running tests...\n\n");

    test_string_functions();
    test_file_operations();

    printf("\n%d/%d tests passed\n", tests_passed, tests_run);
    exit(tests_passed == tests_run ? 0 : 1);
}
```

## Tips and Best Practices

### Error Handling

Always check return values:
```c
int fd = open("file.txt", O_RDONLY);
if (fd < 0) {
    printf("Error: cannot open file\n");
    exit(1);
}
```

### Resource Cleanup

Close file descriptors when done:
```c
int fd = open("file.txt", O_RDONLY);
// ... use fd ...
close(fd);  // Always close
```

### Process Management

Always wait for child processes:
```c
int pid = fork();
if (pid > 0) {
    wait(0);  // Prevent zombie processes
}
```

---

For more examples, see the `user/` directory in the source code.
