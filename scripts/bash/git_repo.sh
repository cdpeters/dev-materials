#!/usr/bin/env bash

create_git_repo() {
    # Help flag and messages.
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Usage: create_git_repo [OPTIONS]"
        echo
        echo "Creates a git repository locally and on GitHub, then connects them."
        echo "Uses the current directory name as the repo name."
        echo
        echo "Options:"
        echo "  --help, -h           Show this help message."
        echo "  --license VALUE      Specify the license type (default: apache-2.0)."
        echo "                           Use 'gh repo license list' to see available licenses."
        echo "  --gitignore VALUE    Specify the .gitignore template (default: Python)."
        echo "                           Use 'gh repo gitignore list' to see available templates."
        echo "  --private            Make the repo private (default: public)."
        echo "  --description VALUE  Add a description to the repo."
        echo
        echo "Examples:"
        echo "  create_git_repo"
        echo "  create_git_repo --private --license mit"
        echo "  create_git_repo --gitignore Node --description \"My awesome project\""
        echo
        echo "Note: Requires the GitHub CLI."
        return 0
    fi

    # Default values.
    local license="apache-2.0"
    local gitignore="Python"
    local private=false
    local description=""

    # Parse command line arguments.
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
                echo "Use --help or -h to see usage information."
                return 1
                ;;
        esac
    done

    # Get the name from current directory.
    local name=$(basename "$(pwd)")

    # Check if name is provided
    if [ -z "$name" ]; then
        echo "Error: Could not determine directory name."
        return 1
    fi

    # Convert repo name to title case for README
    local title_name=$(echo "$name" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

    # Show summary and ask for confirmation
    echo "Repository Configuration Summary:"
    echo "--------------------------------"
    echo "repo name: $name"
    echo "license: $license"
    echo "gitignore template: $gitignore"
    echo "visibility: $([ "$private" = true ] && echo "Private" || echo "Public")"
    echo "description: $([ -z "$description" ] && echo "None" || echo "$description")"
    echo "--------------------------------"

    while true; do
        read -p "Do you want to proceed with these settings? (y/n): " confirm
        case $confirm in
            [Yy]*)
                break
                ;;
            [Nn]*)
                echo "Repo creation cancelled."
                return 0
                ;;
            *)
                echo "Please answer 'y' for yes or 'n' for no."
                ;;
        esac
    done

    # 1. Create remote repository first to validate the name
    local visibility_flag=$([ "$private" = true ] && echo "--private" || echo "--public")

    if ! gh repo create "$name" $visibility_flag --description "$description"; then
        echo "Failed to create remote repository."
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
