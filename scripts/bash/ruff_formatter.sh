#!/usr/bin/env bash

# This file creates the function `formatter` for sourcing within `.bashrc`.
# `formatter` runs the ruff linter with import sorting and then the formatter.

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check all required dependencies
check_dependencies() {
    local missing_deps=()

    if ! command_exists ruff; then
        missing_deps+=("ruff")
    fi

    # If we found missing dependencies
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Error: Required dependencies are missing:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo "Please install missing dependencies:"
        echo "  <package_manager> <install_command> ${missing_deps[*]}"
        return 1
    fi

    return 0
}

formatter() {
    # Check dependencies first
    if ! check_dependencies; then
        return 1
    fi

    # Show usage if no arguments provided
    if [ $# -eq 0 ]; then
        echo "formatter: Run ruff's linter (with import sorting) and formatter"
        echo
        echo "Usage:"
        echo "  formatter --py             # Process all .py files in current directory"
        echo "  formatter --ipynb          # Process all .ipynb files in current directory"
        echo "  formatter file1.py file2.ipynb      # Process specific .py and/or .ipynb files"
        return 1
    fi

    # Handle directory-wide flags
    if [ "$1" = "--py" ]; then
        ruff check --select I --fix ./**/*.py && ruff format ./**/*.py
        return 0
    elif [ "$1" = "--ipynb" ]; then
        ruff check --select I --fix ./**/*.ipynb && ruff format ./**/*.ipynb
        return 0
    fi

    # Handle individual files
    local valid_files=()

    for file in "$@"; do
        if [ -f "$file" ] && [[ "$file" =~ \.(py|ipynb)$ ]]; then
            valid_files+=("$file")
        else
            echo "Warning: Skipping $file (invalid file or unsupported file type)"
        fi
    done

    # Execute ruff on valid files
    if [ ${#valid_files[@]} -ne 0 ]; then
        ruff check --select I --fix "${valid_files[@]}" && ruff format "${valid_files[@]}"
    fi
}
