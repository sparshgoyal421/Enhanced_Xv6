# API Reference

## System Calls

### Process Control

#### fork()
```c
int fork(void);
```
Creates a new process by duplicating the calling process.

**Returns**:
- Child PID in parent process
- 0 in child process
- -1 on error

**Example**:
```c
int pid = fork();
if (pid == 0) {
    // Child process
    printf("I am child\n");
} else if (pid > 0) {
    // Parent process
    printf("Child PID: %d\n", pid);
}
```

#### exec()
```c
int exec(char *path, char **argv);
```
Replaces the current process image with a new program.

**Parameters**:
- `path`: Path to executable
- `argv`: Argument vector (NULL-terminated)

**Returns**: -1 on error (does not return on success)

#### wait()
```c
int wait(int *status);
```
Waits for a child process to terminate.

**Returns**: PID of terminated child, or -1 if no children

#### exit()
```c
void exit(int status);
```
Terminates the calling process with given status code.

### File Operations

#### open()
```c
int open(char *path, int flags);
```
Opens a file for reading or writing.

**Flags**:
- `O_RDONLY`: Read-only
- `O_WRONLY`: Write-only
- `O_RDWR`: Read and write
- `O_CREATE`: Create if doesn't exist

**Returns**: File descriptor, or -1 on error

#### read()
```c
int read(int fd, void *buf, int n);
```
Reads up to n bytes from file descriptor.

**Returns**: Number of bytes read, 0 on EOF, -1 on error

#### write()
```c
int write(int fd, void *buf, int n);
```
Writes n bytes to file descriptor.

**Returns**: Number of bytes written, or -1 on error

#### close()
```c
int close(int fd);
```
Closes a file descriptor.

**Returns**: 0 on success, -1 on error

### Memory Management

#### sbrk()
```c
void *sbrk(int n);
```
Grows process heap by n bytes.

**Parameters**:
- `n`: Number of bytes to allocate (can be negative to shrink)

**Returns**: Previous heap limit, or -1 on error

#### mmap()
```c
void *mmap(void *addr, int length, int prot, int flags);
```
Maps files or devices into memory.

**Returns**: Pointer to mapped area, or -1 on error

### Inter-Process Communication

#### pipe()
```c
int pipe(int *fds);
```
Creates a unidirectional data channel.

**Parameters**:
- `fds[0]`: Read end
- `fds[1]`: Write end

**Returns**: 0 on success, -1 on error

**Example**:
```c
int fds[2];
pipe(fds);
if (fork() == 0) {
    close(fds[1]);
    read(fds[0], buf, sizeof(buf));
} else {
    close(fds[0]);
    write(fds[1], "hello", 5);
}
```

## Library Functions

### Standard I/O

#### printf()
```c
int printf(const char *fmt, ...);
```
Formatted output to stdout.

#### fprintf()
```c
int fprintf(int fd, const char *fmt, ...);
```
Formatted output to file descriptor.

### String Operations

#### strlen()
```c
int strlen(const char *s);
```
Returns length of string.

#### strcmp()
```c
int strcmp(const char *s1, const char *s2);
```
Compares two strings.

**Returns**: 0 if equal, <0 if s1 < s2, >0 if s1 > s2

#### strcpy()
```c
char *strcpy(char *dst, const char *src);
```
Copies string from src to dst.

### Memory Operations

#### memset()
```c
void *memset(void *ptr, int value, int n);
```
Fills memory with constant byte.

#### memcpy()
```c
void *memcpy(void *dst, const void *src, int n);
```
Copies n bytes from src to dst.

## Error Handling

Most system calls return -1 on error. Check return values and handle errors appropriately:

```c
int fd = open("file.txt", O_RDONLY);
if (fd < 0) {
    printf("Error opening file\n");
    exit(1);
}
```
