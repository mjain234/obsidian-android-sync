#!/data/data/com.termux/files/usr/bin/bash
source /data/data/com.termux/files/usr/etc/bash.bashrc

source "$HOME/log_helper.sh"

log_file="$HOME/sync.log"
setup_logging $log_file

skip_pause_val="--skip-pause"

# Function to run the sync command
cmd () {
  local repo_path="$1"
  local log_path="$2"
  {
    printf "\n\033[0;34m%s\033[0m\n" "$(basename "$repo_path")"
    $HOME/git-sync -ns
  } &> "$log_path" &
}

git_repos=()

# Populate the array with Git repos
for dir in "$OBSIDIAN_DIR_PATH"/*; do
  if [ -d "$dir" ]; then
    if git -C "$dir" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
      git_repos+=("$dir")
    fi
  fi
done

msg="You can try running 'setup' to see if it helps".

# Exit if no Git repos are found
if [ ${#git_repos[@]} -eq 0 ]; then
  echo -e "${YELLOW}No Git repositories found in the Obsidian folder.\n${msg}${RESET}"
  exit 1
fi

# Create a temporary directory for logs
tmp_log_dir=$(mktemp -d)

if [[ -n "$1" && "$1" != "$skip_pause_val" ]]; then # Sync a single repo
  repo_path="$OBSIDIAN_DIR_PATH/$1"
  if [[ " ${git_repos[*]} " =~ " $repo_path " ]]; then
    cmd "$repo_path" "$tmp_log_dir/single_sync.log"
    wait # Wait for background process to finish
    cat "$tmp_log_dir/single_sync.log"
  else
    echo -e "${RED}Specified directory doesn't exist or is not a Git repository.\n${msg}${RESET}"
    exit 1
  fi
else  # Sync all Git repos
  for repo in "${git_repos[@]}"; do
    tmp_log_file="$tmp_log_dir/$(basename "$repo").log"
    cmd "$repo" "$tmp_log_file"
  done

  wait # Wait for all background processes to finish

  # Output all the logs
  for log_file in "$tmp_log_dir"/*.log; do
    cat "$log_file"
  done
fi

log_cleanup $log_file

# Cleanup temporary log directory
rm -rf "$tmp_log_dir"

if [[ -z "$1" ]]; then
  bypass_log "echo -e '\n\033[44;97mPress enter to finish...\033[0m' && read none"
fi
