#!/bin/bash

# ANSI color codes
RED="\e[91m"
GREEN="\e[92m"
YELLOW="\e[93m"
RESET="\e[0m"

# Array to store recommendations
recommendations=()

# Function to check file owner
check_owner() {
    local file=$1
    local expected_owner=$2
    local current_owner=$(stat -c '%U' "$file" 2>/dev/null)
    if [[ -z "$current_owner" ]]; then
        return 1 # File does not exist or cannot be accessed
    elif [[ "$current_owner" == "$expected_owner" ]]; then
        echo -e "${GREEN}[ GOOD ]${RESET}"
        return 0
    else
        echo -e "${RED}[ BAD  ]${RESET}"
        recommendations+=("File '$file': Current owner is '$current_owner', but should be '$expected_owner'. Fix with: \e[1;95msudo chown $expected_owner '$file'\e[0m")
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
        echo -e "${GREEN}[ GOOD ]${RESET}"
        return 0
    else
        echo -e "${RED}[ BAD  ]${RESET}"
        recommendations+=("File '$file': Current group is '$current_group', but should be '$expected_group'. Fix with: \e[1;95msudo chgrp $expected_group '$file'\e[0m")
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
        echo -e "${GREEN}[ GOOD ]${RESET}"
        return 0
    else
        echo -e "${RED}[ BAD  ]${RESET}"
        recommendations+=("File '$file': Current permissions are '$current_perms', but should be '$expected_perms'. Fix with: \e[1;95msudo chmod $expected_perms '$file'\e[0m")
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
        printf "%-60s" "[*] Checking $file"
        echo -e "${RED}[ BAD  ]${RESET}"
        recommendations+=("File '$file' does not exist or cannot be accessed.")
        return
    fi

    # Perform individual checks
    printf "%-60s" "[*] Checking $file owner"
    check_owner "$file" "$owner"

    printf "%-60s" "[*] Checking $file group"
    check_group "$file" "$group"

    printf "%-60s" "[*] Checking $file file permissions"
    check_permissions "$file" "$perms"
}

# Header
echo
echo -e "\e[1;95m-------------------------[system files audit in progress]-------------------------\e[0m"

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
