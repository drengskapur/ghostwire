#!/bin/bash

# Universal Claude Code Attribution Removal Script
# 
# This script can be run from any git repository to remove Claude Code
# attribution messages from the entire git history using git filter-repo.
#
# Usage:
#   ./remove-claude-attribution.sh [OPTIONS]
#
# Options:
#   --help, -h     Show help message
#   --dry-run      Show what would be affected without making changes
#
# WARNING: This will rewrite git history and change all commit hashes!
# Make sure you understand the implications before running this script.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_BRANCH="backup-before-claude-removal-$(date +%Y%m%d-%H%M%S)"
ATTRIBUTION_PATTERN='🤖 Generated with \[Claude Code\]\(https://claude\.ai/code\)\n\nCo-Authored-By: Claude <noreply@anthropic\.com>\n?'

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository!"
        print_error "Please run this script from within a git repository."
        exit 1
    fi
    
    # Check if git filter-repo is installed
    if ! command -v git-filter-repo >/dev/null 2>&1; then
        print_error "git-filter-repo is not installed!"
        print_error "Install it with one of the following:"
        print_error "  pip install git-filter-repo"
        print_error "  pip3 install git-filter-repo"
        print_error "  dnf install git-filter-repo    (RHEL/Fedora)"
        print_error "  apt install git-filter-repo    (Debian/Ubuntu)"
        exit 1
    fi
    
    # Check if working directory is clean
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        print_error "Working directory is not clean. Please commit or stash your changes."
        print_error "Run: git status to see uncommitted changes"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Function to show what will be affected
show_impact() {
    print_status "Analyzing repository..."
    
    local current_branch=$(git branch --show-current)
    local total_commits=$(git rev-list --count HEAD)
    local affected_commits=$(git log --grep="Generated with \[Claude Code\]" --oneline 2>/dev/null | wc -l)
    local repo_path=$(git rev-parse --show-toplevel)
    
    echo
    echo "Repository Analysis:"
    echo "  Repository path: $repo_path"
    echo "  Current branch: $current_branch"
    echo "  Total commits: $total_commits"
    echo "  Commits with Claude attribution: $affected_commits"
    echo
    
    if [ "$affected_commits" -eq 0 ]; then
        print_success "No Claude Code attribution messages found in commit history."
        echo "Nothing to remove. Repository is already clean!"
        exit 0
    fi
    
    print_warning "This will rewrite the entire git history!"
    print_warning "All commit hashes will change!"
    
    # Check for remotes
    local remotes=$(git remote 2>/dev/null || echo "")
    if [ ! -z "$remotes" ]; then
        echo
        echo "Remote repositories detected:"
        git remote -v 2>/dev/null | while read -r line; do
            echo "  $line"
        done
        echo
        print_warning "You will need to force-push the changes to update remotes!"
        print_warning "Anyone with a clone will need to re-clone the repository!"
    fi
}

# Function to create backup
create_backup() {
    print_status "Creating backup branch: $BACKUP_BRANCH"
    
    # Create backup branch
    git branch "$BACKUP_BRANCH"
    print_success "Backup branch '$BACKUP_BRANCH' created"
    
    echo "If something goes wrong, you can restore with:"
    echo "  git checkout $BACKUP_BRANCH"
    echo "  git branch -D main  # or your current branch name"
    echo "  git checkout -b main"
}

# Function to perform the filter-repo operation
filter_repository() {
    print_status "Rewriting git history to remove Claude Code attribution..."
    print_status "This may take a while for large repositories..."
    
    # Store original remotes
    local remotes_file=$(mktemp)
    git remote -v > "$remotes_file" 2>/dev/null || true
    
    # Run git filter-repo with the message callback
    git filter-repo --force --message-callback "
import re
pattern = r'$ATTRIBUTION_PATTERN'
cleaned = re.sub(pattern, '', message.decode(), flags=re.MULTILINE)
# Remove any trailing whitespace that might be left
cleaned = cleaned.rstrip() + '\n' if cleaned.strip() else cleaned
return cleaned.encode()
"
    
    # Restore remotes if they existed
    if [ -s "$remotes_file" ]; then
        print_status "Restoring remote repositories..."
        while read -r name url type; do
            if [ "$type" = "(fetch)" ]; then
                git remote add "$name" "$url" 2>/dev/null || true
                print_status "Restored remote '$name': $url"
            fi
        done < "$remotes_file"
    fi
    
    rm -f "$remotes_file"
    print_success "Git history rewritten successfully"
}

# Function to run garbage collection
cleanup_repository() {
    print_status "Cleaning up repository and reclaiming disk space..."
    
    # Clean up reflogs and unreachable objects
    git reflog expire --expire-unreachable=now --all 2>/dev/null || true
    git gc --prune=now --aggressive
    
    print_success "Repository cleanup completed"
}

# Function to verify the results
verify_results() {
    print_status "Verifying results..."
    
    local remaining_attributions=$(git log --grep="Generated with \[Claude Code\]" --oneline 2>/dev/null | wc -l)
    local total_commits_after=$(git rev-list --count HEAD)
    
    if [ "$remaining_attributions" -eq 0 ]; then
        print_success "All Claude Code attributions have been removed!"
    else
        print_error "$remaining_attributions Claude Code attributions still found!"
        print_error "Manual review may be needed."
    fi
    
    echo
    echo "Results:"
    echo "  Total commits after cleanup: $total_commits_after"
    echo "  Remaining Claude attributions: $remaining_attributions"
    echo
    echo "Recent commits after cleanup:"
    git log --oneline -n 5 2>/dev/null || echo "No commits found"
}

# Function to handle remote operations
handle_remote() {
    local remotes=$(git remote 2>/dev/null || echo "")
    
    if [ ! -z "$remotes" ]; then
        echo
        print_warning "Remote repositories detected."
        print_warning "The local history has been rewritten and is now incompatible with remotes."
        echo
        echo "Your options:"
        echo "  1. Force-push to update remotes (DESTRUCTIVE - affects all collaborators)"
        echo "  2. Skip pushing (you can push manually later)"
        echo "  3. Create a new repository with the cleaned history"
        echo
        
        read -p "Do you want to force-push the changes to ALL remotes? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Force-pushing to all remotes..."
            
            # Try to remove backup branch from remotes (in case it was accidentally pushed before)
            for remote in $remotes; do
                git push "$remote" --delete "$BACKUP_BRANCH" 2>/dev/null || true
            done
            
            # Force push all branches and tags
            git push --force --all
            git push --force --tags
            
            print_success "Changes force-pushed to all remotes"
            echo
            print_warning "IMPORTANT: Anyone else with a clone of this repository must:"
            print_warning "  1. Delete their local clone"
            print_warning "  2. Clone the repository again fresh"
            print_warning "  3. They cannot use 'git pull' - it will fail!"
        else
            print_status "Skipping remote push."
            echo
            echo "To push manually later, use:"
            echo "  git push --force --all"
            echo "  git push --force --tags"
            echo
            echo "Or create a new repository and push there:"
            echo "  git remote set-url origin <new-repository-url>"
            echo "  git push -u origin main"
        fi
    else
        print_status "No remote repositories found. Local cleanup completed."
    fi
}

# Function to offer cleanup options
offer_cleanup() {
    echo
    read -p "Do you want to delete the local backup branch '$BACKUP_BRANCH'? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git branch -D "$BACKUP_BRANCH"
        print_success "Backup branch deleted"
    else
        print_status "Backup branch '$BACKUP_BRANCH' preserved for safety"
        echo "You can delete it later with:"
        echo "  git branch -D $BACKUP_BRANCH"
        echo "Or restore from it if needed:"
        echo "  git checkout $BACKUP_BRANCH"
    fi
}

# Function to show summary
show_summary() {
    local repo_name=$(basename "$(git rev-parse --show-toplevel)")
    
    echo
    echo "=============================================="
    print_success "Claude Code Attribution Removal Complete!"
    echo "=============================================="
    echo
    echo "Repository: $repo_name"
    echo "Summary of changes:"
    echo "  ✓ Git history rewritten"
    echo "  ✓ All Claude Code attribution messages removed"
    echo "  ✓ Repository optimized and cleaned"
    echo "  ✓ Backup branch created: $BACKUP_BRANCH"
    
    local remotes=$(git remote 2>/dev/null || echo "")
    if [ ! -z "$remotes" ]; then
        echo "  ✓ Remote repositories handled"
    fi
    echo
    
    print_warning "IMPORTANT REMINDERS:"
    echo "  • All commit hashes have changed"
    echo "  • This operation cannot be undone (without the backup)"
    echo "  • If you have remotes, collaborators must re-clone"
    echo "  • The backup branch is available for recovery if needed"
    echo
    
    if [ ! -z "$remotes" ] && git log --grep="Generated with \[Claude Code\]" --oneline >/dev/null 2>&1; then
        print_warning "If you didn't force-push and want to update remotes later:"
        echo "  git push --force --all"
        echo "  git push --force --tags"
    fi
}

# Main execution function
main() {
    local repo_name=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo 'unknown')")
    
    echo "=============================================="
    echo "  Claude Code Attribution Removal Script"
    echo "=============================================="
    echo "Repository: $repo_name"
    echo "$(date)"
    echo
    
    check_prerequisites
    show_impact
    
    echo
    print_warning "This operation will permanently modify git history!"
    read -p "Do you want to proceed with removing Claude Code attributions? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled by user"
        exit 0
    fi
    
    echo
    create_backup
    filter_repository
    cleanup_repository
    verify_results
    handle_remote
    offer_cleanup
    show_summary
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Claude Code Attribution Removal Script"
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Remove Claude Code attribution messages from git history."
        echo
        echo "OPTIONS:"
        echo "  --help, -h     Show this help message"
        echo "  --dry-run      Show what would be affected without making changes"
        echo
        echo "This script will:"
        echo "  1. Check prerequisites (git-filter-repo, clean working directory)"
        echo "  2. Analyze repository and show impact"
        echo "  3. Create a timestamped backup branch"
        echo "  4. Rewrite git history using git filter-repo"
        echo "  5. Clean up and optimize the repository"
        echo "  6. Verify all attributions were removed"
        echo "  7. Handle remote repository updates (optional)"
        echo "  8. Clean up backup branch (optional)"
        echo
        echo "PREREQUISITES:"
        echo "  • git-filter-repo must be installed"
        echo "  • Working directory must be clean"
        echo "  • Must be run from within a git repository"
        echo
        echo "INSTALLATION:"
        echo "  pip install git-filter-repo"
        echo "  # OR #"
        echo "  dnf install git-filter-repo    (RHEL/Fedora)"
        echo "  apt install git-filter-repo    (Debian/Ubuntu)"
        echo
        echo "WARNING:"
        echo "  This rewrites git history and changes all commit hashes!"
        echo "  Anyone with a clone must re-clone after you push changes!"
        echo "  Always create a backup before running this script!"
        echo
        echo "EXAMPLES:"
        echo "  $0 --dry-run    # See what would be changed"
        echo "  $0              # Perform the removal"
        exit 0
        ;;
    --dry-run)
        echo "=============================================="
        echo "  Claude Code Attribution Removal (DRY RUN)"
        echo "=============================================="
        echo "$(date)"
        echo
        print_status "This is a dry run - no changes will be made"
        echo
        check_prerequisites
        show_impact
        echo
        print_success "Dry run completed. No changes were made."
        echo "Run without --dry-run to perform the actual removal."
        exit 0
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac