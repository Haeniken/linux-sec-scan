#!/bin/bash

# ANSI color codes
RED="\e[91m"
GREEN="\e[92m"
YELLOW="\e[93m"
RESET="\e[0m"
CYAN="\e[96m"

# Array to store recommendations
recommendations=()

# Function to print a message with a colored status
print_status() {
    local status=$1
    local message=$2
    case $status in
        GOOD) echo -e "${GREEN}[ GOOD ]${RESET} $message" ;;
        BAD)  echo -e "${RED}[ BAD  ]${RESET} $message" ;;
        *)    echo -e "${YELLOW}[ INFO ]${RESET} $message" ;;
    esac
}

# Function to check file owner
check_owner() {
    local file=$1
    local expected_owner=$2
    local current_owner=$(stat -c '%U' "$file" 2>/dev/null)
    if [[ -z "$current_owner" ]]; then
        return 1 # File does not exist or cannot be accessed
    elif [[ "$current_owner" == "$expected_owner" ]]; then
        print_status "GOOD" "File '$file' owner is '$current_owner'."
        return 0
    else
        print_status "BAD" "File '$file': Current owner is '$current_owner', but should be '$expected_owner'."
        recommendations+=("File '$file': Fix owner with: ${CYAN}sudo chown $expected_owner '$file'${RESET}")
        return 1
    fi
}

# Function to check file group
check_group() {
    local file=$1
    local expected_group=$2
    local current_group=$(stat -c '%G' "$file" 2>/dev/null)
    if [[ -z "$current_group" ]]; then
        return 1 # File does not exist or cannot be accessed
    elif [[ "$current_group" == "$expected_group" ]]; then
        print_status "GOOD" "File '$file' group is '$current_group'."
        return 0
    else
        print_status "BAD" "File '$file': Current group is '$current_group', but should be '$expected_group'."
        recommendations+=("File '$file': Fix group with: ${CYAN}sudo chgrp $expected_group '$file'${RESET}")
        return 1
    fi
}

# Function to check file permissions
check_permissions() {
    local file=$1
    local expected_perms=$2
    local current_perms=$(stat -c '%a' "$file" 2>/dev/null)
    if [[ -z "$current_perms" ]]; then
        return 1 # File does not exist or cannot be accessed
    elif [[ "$current_perms" == "$expected_perms" ]]; then
        print_status "GOOD" "File '$file' permissions are '$current_perms'."
        return 0
    else
        print_status "BAD" "File '$file': Current permissions are '$current_perms', but should be '$expected_perms'."
        recommendations+=("File '$file': Fix permissions with: ${CYAN}sudo chmod $expected_perms '$file'${RESET}")
        return 1
    fi
}

# Function to perform all checks for a file
perform_checks() {
    local file=$1
    local owner=$2
    local group=$3
    local perms=$4

    # Check if the file exists and is accessible
    if ! stat "$file" &>/dev/null; then
        print_status "BAD" "File '$file' does not exist or cannot be accessed."
        recommendations+=("File '$file' does not exist or cannot be accessed.")
        return
    fi

    # Perform individual checks
    check_owner "$file" "$owner"
    check_group "$file" "$group"
    check_permissions "$file" "$perms"
}

# Header
echo
echo -e "${CYAN}-------------------------[system files audit in progress]-------------------------${RESET}"

# Define files and their expected attributes
declare -A files=(
    ["/etc/passwd"]="root root 644"
    ["/etc/shadow"]="root shadow 640"
    ["/etc/group"]="root root 644"
    ["/etc/gshadow"]="root shadow 640"
    ["/etc/opasswd"]="root root 600"
    ["/etc/passwd-"]="root root 600"
    ["/etc/shadow-"]="root shadow 600"
    ["/etc/group-"]="root root 600"
    ["/etc/gshadow-"]="root shadow 600"
)

# Perform checks for each file
for file in "${!files[@]}"; do
    # Split attributes into owner, group, and permissions
    IFS=' ' read -r owner group perms <<< "${files[$file]}"

    perform_checks "$file" "$owner" "$group" "$perms"
done

# Print recommendations if any issues were found
if [[ ${#recommendations[@]} -gt 0 ]]; then
    echo
    echo -e "${YELLOW}-------------------------[Recommendations for fixing issues]-------------------------${RESET}"
    for recommendation in "${recommendations[@]}"; do
        echo -e "${YELLOW}=> $recommendation${RESET}"
    done
else
    echo
    echo -e "${GREEN}No issues found. System files are secure.${RESET}"
fi

echo
