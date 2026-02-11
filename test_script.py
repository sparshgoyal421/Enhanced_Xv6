#!/usr/bin/env python3
# Test script with intentional bugs for review bot testing

import os
import pickle
import subprocess

# Intentional Issue 1: Hardcoded credentials
API_KEY = "sk-1234567890abcdef"
DATABASE_PASSWORD = "MySecretPass123!"

# Intentional Issue 2: SQL Injection vulnerability
def search_database(user_input):
    query = f"SELECT * FROM users WHERE name = '{user_input}'"
    # Directly interpolating user input - SQL injection!
    return query

# Intentional Issue 3: Command injection vulnerability
def run_system_command(filename):
    # Using shell=True with user input - command injection!
    cmd = f"cat {filename}"
    result = subprocess.run(cmd, shell=True, capture_output=True)
    return result.stdout

# Intentional Issue 4: Insecure deserialization
def load_user_data(data):
    # Pickle is unsafe with untrusted data
    return pickle.loads(data)

# Intentional Issue 5: Path traversal vulnerability
def read_file(filename):
    # No validation - can access ../../../etc/passwd
    with open(filename, 'r') as f:
        return f.read()

# Intentional Issue 6: Weak cryptography
def hash_password(password):
    # Using MD5 for passwords - extremely weak!
    import hashlib
    return hashlib.md5(password.encode()).hexdigest()

# Intentional Issue 7: Resource leak - file not closed properly
def process_log_file(filepath):
    f = open(filepath, 'r')
    data = f.read()
    # File never closed - resource leak!
    return data

# Intentional Issue 8: Infinite loop risk
def wait_for_condition(value):
    while value != 100:
        # If value is never 100, infinite loop!
        pass

# Intentional Issue 9: Inefficient algorithm O(n^3)
def find_triplets(arr):
    result = []
    for i in range(len(arr)):
        for j in range(len(arr)):
            for k in range(len(arr)):
                if arr[i] + arr[j] + arr[k] == 0:
                    result.append((arr[i], arr[j], arr[k]))
    return result

# Intentional Issue 10: No error handling
def divide_numbers(a, b):
    return a / b  # Can raise ZeroDivisionError

# Intentional Issue 11: Using eval() with user input
def calculate(expression):
    # Extremely dangerous - arbitrary code execution!
    return eval(expression)

# Intentional Issue 12: Mutable default argument
def add_item(item, items=[]):
    items.append(item)
    return items

# Intentional Issue 13: Comparing with == instead of 'is' for None
def check_value(value):
    if value == None:  # Should use 'is None'
        return "empty"
    return value

# Intentional Issue 14: Global variable modification
counter = 0

def increment():
    global counter
    counter += 1  # Side effects via global state

# Intentional Issue 15: No input validation
def process_user_age(age):
    # No check if age is reasonable (could be negative, or > 200)
    return f"User is {age} years old"

if __name__ == "__main__":
    # Some test calls
    print(search_database("admin"))
    print(hash_password("password123"))
    print(divide_numbers(10, 2))
