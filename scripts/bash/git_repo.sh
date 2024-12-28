#!/usr/bin/env bash

create_git_repo() {
    # Default values
    local license="apache-2.0"
    local gitignore="Python"
    local private=false
    local description=""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --license)
                license="$2"
                shift 2
                ;;
            --gitignore)
                gitignore="$2"
                shift 2
                ;;
            --private)
                private=true
                shift
                ;;
            --description)
                description="$2"
                shift 2
                ;;
            *)
                echo "Unknown parameter: $1"
                return 1
                ;;
        esac
    done

    # Get the name from current directory
    local name=$(basename "$(pwd)")

    # Check if name is provided
    if [ -z "$name" ]; then
        echo "Error: Could not determine directory name"
        return 1
    fi

    # Convert repo name to title case for README
    local title_name=$(echo "$name" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

    # 1. Create remote repository first to validate the name
    local visibility_flag=$([ "$private" = true ] && echo "--private" || echo "--public")

    if ! gh repo create "$name" $visibility_flag --description "$description"; then
        echo "Failed to create remote repository"
        return 1
    fi

    # 2. Initialize git repository
    git init

    # 3. Create README.md
    echo "# $title_name" > README.md

    # 4. View and save license content
    gh repo license view "$license" > LICENSE

    # 5. View and save gitignore template
    gh repo gitignore view "$gitignore" > .gitignore

    # 6. Stage and commit all files
    git add .
    git commit -m "Initial commit with README, LICENSE, and .gitignore"

    # 7. Add remote and push
    git remote add origin "$(gh repo view "$name" --json url -q .url)"
    git push -u origin main
}
