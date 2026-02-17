// User management system with intentional bugs for testing review bot

#include "types.h"
#include "stat.h"
#include "user.h"

#define MAX_USERS 100
#define PASSWORD_LEN 50

// Intentional Issue 1: Hardcoded credentials (security issue)
char admin_password[] = "admin123";

struct user {
    char username[32];
    char password[PASSWORD_LEN];
    int uid;
    int is_admin;
};

struct user users[MAX_USERS];
int user_count = 0;

// Intentional Issue 2: No bounds checking (buffer overflow vulnerability)
int add_user(char* username, char* password, int is_admin) {
    strcpy(users[user_count].username, username);  // No length check!
    strcpy(users[user_count].password, password);  // No length check!
    users[user_count].uid = user_count;
    users[user_count].is_admin = is_admin;
    user_count++;  // No check if user_count exceeds MAX_USERS!
    return 0;
}

// Intentional Issue 3: Insecure password comparison (timing attack vulnerability)
int authenticate(char* username, char* password) {
    int i;
    for (i = 0; i < user_count; i++) {
        // String comparison is vulnerable to timing attacks
        if (strcmp(users[i].username, username) == 0 &&
            strcmp(users[i].password, password) == 0) {
            return 1;  // Success
        }
    }
    return 0;  // Failure
}

// Intentional Issue 4: SQL Injection-like vulnerability
// Intentional Issue 5: No input validation
int search_user(char* query) {
    char search_buffer[256];
    // Directly using user input without sanitization
    sprintf(search_buffer, "SELECT * FROM users WHERE name='%s'", query);
    printf(1, "Executing: %s\n", search_buffer);
    return 0;
}

// Intentional Issue 6: Memory leak - allocated memory never freed
char* get_user_info(int uid) {
    char* info = (char*)malloc(1024);  // Allocated but never freed
    int i;
    for (i = 0; i < user_count; i++) {
        if (users[i].uid == uid) {
            sprintf(info, "User: %s, UID: %d, Admin: %d",
                    users[i].username, users[i].uid, users[i].is_admin);
            return info;
        }
    }
    return info;  // Returns allocated memory even on failure
}

// Intentional Issue 7: Race condition - no synchronization
int global_counter = 0;

void increment_counter() {
    int temp = global_counter;
    // Simulating some work
    temp = temp + 1;
    global_counter = temp;  // Not atomic - race condition!
}

// Intentional Issue 8: Inefficient algorithm (performance issue)
// O(n^2) when O(n) is possible
int count_duplicates() {
    int i, j, count = 0;
    for (i = 0; i < user_count; i++) {
        for (j = i + 1; j < user_count; j++) {
            if (strcmp(users[i].username, users[j].username) == 0) {
                count++;
            }
        }
    }
    return count;
}

// Intentional Issue 9: Integer overflow vulnerability
int calculate_total_storage(int num_files, int file_size) {
    return num_files * file_size;  // Can overflow!
}

// Intentional Issue 10: Using deprecated/unsafe functions
void copy_username(char* dest, char* src) {
    strcpy(dest, src);  // Should use strncpy or strlcpy
    gets(dest);  // Extremely unsafe - deprecated function!
}

// Intentional Issue 11: Missing error handling
int delete_user(int uid) {
    // No check if uid is valid
    // No check if operation succeeded
    users[uid].uid = -1;
    return 0;
}

// Intentional Issue 12: Hardcoded array size causing performance issues
void process_all_users() {
    int i;
    // Always iterates MAX_USERS times even if user_count is much smaller
    for (i = 0; i < MAX_USERS; i++) {
        if (users[i].uid >= 0) {
            printf(1, "Processing user %d\n", users[i].uid);
        }
    }
}

int main(int argc, char *argv[]) {
    // Testing the buggy code
    add_user("alice", "password123", 0);
    add_user("bob", "qwerty", 0);

    if (authenticate("alice", "password123")) {
        printf(1, "Alice authenticated\n");
    }

    exit();
}
