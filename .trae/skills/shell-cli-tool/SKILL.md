---
name: "shell-cli-tool"
description: "Provides shell command line tool development guidance and best practices. Invoke when user needs help with shell scripting, CLI tool design, or command-line utilities."
---

# Shell CLI Tool

This skill helps with shell command line tool development.

## Capabilities

- Shell script development (Bash, Zsh, etc.)
- CLI tool design patterns
- Command-line argument parsing
- Error handling in shell scripts
- Best practices for CLI tools

## Usage Guidelines

1. Follow POSIX standards for portability
2. Use meaningful command names and options
3. Provide helpful error messages
4. Support `--help` and `--version` flags
5. Handle edge cases gracefully

## Examples

### Basic CLI Structure

```bash
#!/bin/bash

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--version)
      echo "Version 1.0.0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done
```
