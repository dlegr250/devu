#!/usr/bin/env bash

#=======================================================================
# Developer Utilities (DEVU)
# Convenient functions for developers and utility.
# 
# INSTALLATION
# - Copy this file to some directory (recommended: ~/devu.sh)
# - Source this file in your shell profile (e.g. ~/.bashrc, ~/.zshrc)
#   `source ~/devu.sh`
# - (optional) Create a `.devu` config file in your project directory
#   to override default values. See config section for keys.
# - Run `devu` to see the available commands.
#=======================================================================

# Config (default values)
# Add '.devu' file to override these values for a single project.
# Add '~/.devu' file to override these values globally.
#-----------------------------------------------------------------------

BRANCH_DESCRIPTION_WORD_SEPARATOR="-"
BRANCH_ISSUE_ID_SEPARATOR="/"
COMMITS_REQUIRE_ISSUE_KEY=false
ISSUE_ID_REGEX="[0-9]+"
PROJECT_KEY="DEVU"
PROTECTED_BRANCHES=(main master development)

# DEVU functions
#-----------------------------------------------------------------------

function devu() {
  util.echo
  util.echo "$(devu.version)"
  util.echo
  util.echo "Shell functions useful for developers."
  util.echo
  util.echo "Run <command> without args to see the usage (if applicable)."
  util.echo "Use 'which <command>' to see the implementation."
  util.echo
  util.echo "HELP" "${RED}"
  util.echo "  devu | devu.help # Show this help message"
  util.echo "  devu.config      # Show the configuration"
  util.echo "  devu.version     # Show the DEVU version"
  util.echo
  util.echo "COMMANDS (alias)" "${RED}"
  util.echo "  branch.create <branch>          # Create a new branch"
  util.echo "  branch.current                  # Show the current branch"
  util.echo "  branch.delete <branch>    (dlb) # Delete a local branch"
  util.echo "  branch.default                  # Show the default branch"
  util.echo "  branches                    (b) # Show local branches"
  util.echo "  commits [<number>]        (glo) # Show commits (defaults to all)"
  util.echo "  checkout <branch>          (co) # Checkout a branch"
  util.echo "  checkout.file <file>       (cf) # Checkout a single file from the default branch"
  util.echo "  checkout.issue <issue_id>  (ci) # Checkout a branch prefixed with the issue ID"
  util.echo "  commit <message>                # Commit changes and push to remote"
  util.echo "  force-push                      # Force push changes to remote (with lease)"
  util.echo "  gd                              # Git diff"
  util.echo "  gl [<number>]                   # Git log (defaults to all)"
  util.echo "  gp                              # Git pull latest changes"
  util.echo "  gs                              # Git status"
  util.echo "  issue <issue_id> <branch>       # Create a branch for the given issue ID"
  util.echo "  ll                              # List files in long format"
  util.echo "  log.cleanup                     # Remove '/log/*.log' files"
  util.echo "  main-pull                  (mp) # Switch to default branch and pull changes"
  util.echo "  pull-request               (pr) # Display the URL to create a pre-filled pull request"
  util.echo "  sha                             # Show the SHA of the current commit"
  util.echo "  uncommit [<number=1>]           # Soft uncommit/undo last number of commits"
  util.echo
  util.echo "SUPPORT NAMESPACES (TAB-complete to see list)" "${RED}"
  util.echo "  array.* # Array functions"
  util.echo "  file.*  # File functions"
  util.echo "  git.*   # Git functions"
  util.echo "  is.*    # Boolean test functions"
  util.echo "  util.*  # Utility functions"
  util.echo
}

function devu.help() {
  devu
}

function devu.config() {
  file.exists $(devu.config_file) && source $(devu.config_file)

  if file.exists $(devu.config_file); then
    util.echo "Config file: $(devu.config_file)"
  else
    util.echo "No .devu config file, using defaults."
  fi
  util.echo "----"
  util.echo "BRANCH_DESCRIPTION_WORD_SEPARATOR=${BRANCH_DESCRIPTION_WORD_SEPARATOR}"
  util.echo "BRANCH_ISSUE_ID_SEPARATOR=${BRANCH_ISSUE_ID_SEPARATOR}"
  util.echo "COMMITS_REQUIRE_ISSUE_KEY=${COMMITS_REQUIRE_ISSUE_KEY}"
  util.echo "ISSUE_ID_REGEX=${ISSUE_ID_REGEX}"
  util.echo "PROJECT_KEY=${PROJECT_KEY}"
  util.echo "PROTECTED_BRANCHES=(${PROTECTED_BRANCHES})"
}

# Used to override default values for a project.
# Falls back to global config if no project config is found.
function devu.config_file() {
  if file.exists .devu; then
    echo .devu
  elif file.exists ~/.devu; then
    echo $HOME/.devu
  fi
}

function devu.version() {
  echo "DEVU Developer Utilities 1.1.0 (2024-05-18)"
}

# DEVU functions
# Commonly used functions for development
#-----------------------------------------------------------------------

# Create a new branch. The branch name can include spaces.
function branch.create() {
  if is.blank "${1}"; then
    util.echo
    util.echo "Create a new branch."
    util.echo
    util.echo "USAGE (spaces allowed in name)" "${RED}"
    util.echo "  branch.create <branch>"
    util.echo
    util.echo "EXAMPLES" "${RED}"
    util.echo "  branch.create feature/branch_name"
    util.echo "  branch.create 123-branch_name"
    util.echo "  branch.create new branch name"
    util.echo
    return
  fi

  # $@ is an array of args, $* is a single string of combined args. Need array.
  local branch_name=$(array.join "${BRANCH_DESCRIPTION_WORD_SEPARATOR}" ${@})

  util.echo.execute "git checkout -b ${branch_name}"
}

function branch.delete() {
  if is.blank "${1}"; then
    util.echo
    util.echo "Delete a local branch."
    util.echo
    util.echo "Cannot deleted protected branches:"
    array.to.bullet-list ${PROTECTED_BRANCHES}
    util.echo
    util.echo "USAGE" "${RED}"
    util.echo "  branch.delete <branch>"
    util.echo
    util.echo "EXAMPLES" "${RED}"
    util.echo "  branch.delete feature/branch_name"
    util.echo "  branch.delete 123-branch_name"
    util.echo
    return
  fi

  local branch="${1}"

  if array.includes "$branch" ${PROTECTED_BRANCHES}; then
    util.echo "Cannot delete protected branch '$branch'" "${RED}"
    return
  fi

  util.echo "Deleting local branch only..." "${YELLOW}"
  # -D (uppercase D) forces deletion even if branch is not merged
  util.echo.execute "git branch -D ${branch}"
}

# "dlb" => "delete local branch"
function dlb() {
  branch.delete "${*}"
}

function branches() {
  util.echo.execute "git branch"
}

function b() {
  branches
}

# Checkout a branch.
function checkout() {
  local branch="$1"

  if is.blank "${branch}"; then
    util.echo
    util.echo "Checkout a branch."
    util.echo
    util.echo "USAGE" "${RED}"
    util.echo "  checkout <branch>"
    util.echo
    util.echo "EXAMPLES" "${RED}"
    util.echo "  checkout main"
    util.echo "  checkout 123-branch_name"
    util.echo "  checkout 456/another_branch_name"
    util.echo
    util.echo "ALIASES" "${RED}"
    util.echo "  co"
    util.echo
    return
  fi

  util.echo.execute "git checkout ${branch}"
}

function co() {
  checkout "${*}"
}

# Checkout a single file from the main/default branch.
function checkout.file() {
  local file="${1}"

  if is.blank "${file}"; then
    util.echo
    util.echo "Checkout a single file from the default branch."
    util.echo
    util.echo "USAGE" "${RED}"
    util.echo "  checkout.file <file>"
    util.echo
    util.echo "EXAMPLES" "${RED}"
    util.echo "  checkout.file README.md"
    util.echo
    return
  fi
  
  util.echo.execute "git restore --source $(git.branch.default) ${file}"
}

function cf() {
  checkout.file "${*}"
}

# Checkout a branch that is prefixed with the issue ID.
# e.g. `checkout.issue 1234` will checkout the branch `1234-branch_name`
function checkout.issue() {
  file.exists $(devu.config_file) && source $(devu.config_file)

  local issue_id="$1"

  if is.blank "${issue_id}"; then
    util.echo
    util.echo "Checkout branch prefixed with the issue ID."
    util.echo
    util.echo "If there are more than one branch with the"
    util.echo "same issue ID, you will be asked to clarify"
    util.echo "which branch you want to checkout."
    util.echo
    util.echo "USAGE" "${RED}"
    util.echo "  checkout.issue <issue_id>"
    util.echo
    util.echo "EXAMPLES" "${RED}"
    util.echo "  checkout.issue 1234"
    util.echo
    util.echo "ALIASES" "${RED}"
    util.echo "  ci"
    util.echo
    return
  fi

  local issue_id="$1"
  local matched_branches_count=$(git branch | grep -c "${issue_id}${BRANCH_ISSUE_ID_SEPARATOR}")

  if [[ $matched_branches_count -eq 0 ]]; then
    util.echo "No local branches found for issue ID: $issue_id" "${RED}"
  elif [[ $matched_branches_count -eq 1 ]]; then
    checkout $(git for-each-ref --format='%(refname:short)' refs/heads/ | grep "${issue_id}${BRANCH_ISSUE_ID_SEPARATOR}")
  else
    local matched_branches=($(git for-each-ref --format='%(refname:short)' refs/heads/ | grep "${issue_id}${BRANCH_ISSUE_ID_SEPARATOR}"))

    local i=1
    for branch in $matched_branches; do
      util.echo "[$i] $branch"
      i=$((i + 1))
    done

    local branch_number
    # ZSH shell has its own way of reading input
    if [[ -n "$ZSH_VERSION" ]]; then
      read branch_number\?"Enter [number] to checkout: "
    else # Normal bash/shell
      read -p "Enter [number] to checkout: " branch_number
    fi

    if [[ $branch_number -gt 0 && $branch_number -le $matched_branches_count ]]; then
      checkout $(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -m ${branch_number} ${issue_id}${BRANCH_ISSUE_ID_SEPARATOR} | tail -n 1)
    else
      util.echo "Invalid number." "${RED}"
    fi
  fi
}

function ci() {
  checkout.issue "${*}"
}

function commit() {
  file.exists $(devu.config_file) && source $(devu.config_file)

  if [[ $# -eq 0 ]]; then
    util.echo
    util.echo "Commit changes and push to remote."
    util.echo
    util.echo "Quotes are optional unless the <message> contains"
    util.echo "quote or special characters."
    util.echo
    util.echo "USAGE" "${RED}"
    util.echo "  commit <message>"
    util.echo
    util.echo "EXAMPLES" "${RED}"
    util.echo "  commit Fix issue #1234"
    util.echo "  commit \"Fix issue #1234\""
    util.echo
    return
  fi

  local message="$*"

  # In case the default value isn't there, set it to false.
  local require_issue_key_prefix="false"
  if [[ -v COMMITS_REQUIRE_ISSUE_KEY ]]; then
    require_issue_key_prefix=$COMMITS_REQUIRE_ISSUE_KEY
  fi

  if is.true $require_issue_key_prefix; then
    if [[ ! ("$message" =~ "^${PROJECT_KEY}-${ISSUE_ID_REGEX}.*") ]]; then
      util.echo "Prepending issue key to commit message." $YELLOW
      local issue_id=$(util.extract_issue_id_from_branch_name)
      local issue_key="${PROJECT_KEY}-${issue_id}"
      message="${issue_key} - ${message}"
    fi
  else
    util.echo "Commits do not require issue key." $YELLOW
  fi

  util.echo.execute "git add ."
  util.echo.execute "git commit -m \"${message}\""
  util.echo.execute "git push --set-upstream origin $(git.branch.current)"
}

function commits() {
  local number_of_commits="${1}"

  if is.blank "${number_of_commits}"; then
    util.echo.execute "git log --oneline"
  else
    util.echo.execute "git log --oneline -n ${number_of_commits}"
  fi
}

function gl() {
  local number_of_commits="${1}"

  if is.blank "${number_of_commits}"; then
    util.echo.execute "git log"
  else
    util.echo.execute "git log -n ${number_of_commits}"
  fi
}

function glo() {
  commits "${*}"
}

function force-push() {
  util.echo.execute "git push --force-with-lease origin $(git.branch.current)"
}

function gd() {
  util.echo.execute "git diff"
}

function gp() {
  util.echo.execute "git pull"
}

function gs() {
  util.echo.execute "git status"
}

# Create a branch for the given issue ID. Putting the issue ID in the
# branch name makes it easier to track the issue associated with the
# branch.
function issue() {
  file.exists $(devu.config_file) && source $(devu.config_file)

  if [[ $# -lt 2 ]]; then
    util.echo
    util.echo "Create a branch for the issue ID."
    util.echo
    util.echo "USAGE" "${RED}"
    util.echo "  issue <issue_id> <branch>"
    util.echo
    util.echo "ARGUMENTS" "${RED}"
    util.echo "  <issue_id> # Must follow format: ${ISSUE_ID_REGEX}"
    util.echo "  <branch>   # May include spaces between words"
    util.echo
    util.echo "EXAMPLES" "${RED}"
    util.echo "  issue 1234 branch_name"
    util.echo "  issue 1234 branch name"
    util.echo
    return
  fi

  local issue_id="$1"; shift
  # $@ is an array of args, $* is a single string of combined args. Need array.
  local branch_name=$(array.join "${BRANCH_DESCRIPTION_WORD_SEPARATOR}" ${@})

  if [[ ! "${issue_id}" =~ "${ISSUE_ID_REGEX}" ]]; then
    util.echo "<issue_id> must follow format: ${ISSUE_ID_REGEX}" "${RED}"
    return
  fi

  branch.create "${issue_id}${BRANCH_ISSUE_ID_SEPARATOR}${branch_name}"
}

function ll() {
  util.echo.execute "ls -al"
}

function log.cleanup() {
  if is.a-directory "log"; then
    util.echo.execute "rm log/*.log*"
  else
    util.echo "No logs directory found at /log" "${RED}"
  fi
}

function main-pull() {
  checkout "$(git.branch.default)"
  gp
}

function mp() {
  main-pull "${*}"
}

# Display the PR URL to create a pull request that can be copied/pasted.
# Pre-fills the TITLE and DESCRIPTION for the PR.
function pull-request() {
  local to_branch="$(git.branch.default)"

  if is.present "${1}"; then
    to_branch="${1}"
  fi

  if [[ "${to_branch}" == "$(git.branch.current)" ]]; then
    util.echo "Cannot create a PR to the same branch." "${RED}"
    return
  fi

  util.echo "From: $(git.branch.current)"
  util.echo "To: ${to_branch}"

  local url="$(git.pr_url)/${to_branch}...$(git.branch.current)?expand=1&title=$(git.branch.current)"
  open "${url}"
}

function pr() {
  pull-request "${*}"
}

# Show first 7 characters of sha by default, or full sha if argument provided.
function sha() {
  local full="${1}"

  if [[ "${full}" == "full" ]]; then
    util.echo.execute "git rev-parse HEAD"
  else
    util.echo.execute "git rev-parse --short=7 HEAD"
  fi
}

function uncommit() {
  local number="$1"

  if is.blank "$number"; then
    number=1
  fi

  is.numeric "${number}" || {
    util.echo "Argument must be a number." "${RED}"
    return
  }

  util.echo.execute "git reset --soft HEAD~${number}"
}

# Utility functions
#-----------------------------------------------------------------------

GREEN=32; RED=31; BLUE=34; YELLOW=33;
function util.echo() {
  echo -e "\033[0;$2m$1\033[0m"
}

# Show the command and the execute it. Not as useful as it sounds,
# because you can do 'which <command>' to see a command's implementation.
function util.echo.execute() {
  util.echo "=> ${@}" "${YELLOW}"
  eval "${@}"
}

# 123-branch_name => 123
function util.extract_issue_id_from_branch_name() {
  echo $(git.branch.current) | grep -oE "^${ISSUE_ID_REGEX}"
}

# 123-branch_name => "branch name"
function util.extract_description_from_branch_name() {
  local issue_id=$(util.extract_issue_id_from_branch_name)
  echo $(git.branch.current) | sed "s/^${issue_id}-//" | tr "_" " "
}

# Git functions
#-----------------------------------------------------------------------

function git.branch.current() {
  git branch --show-current
}

# Technically git does not have a "default" branch, but this is the
# branch that is typically used as the main branch.
function git.branch.default() {
  local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

  if is.blank "$default_branch"; then
    util.echo "You do not seem to have a default REMOTE branch." "${RED}"
    util.echo "Set one with: git remote set-head origin --auto"
  else
    echo $default_branch
  fi
}

function git.config.get() {
  local location="global"

  if [[ $# -eq 0 ]] && {
    util.echo
    util.echo "Get a git configuration value."
    util.echo
    util.echo "USAGE" "${RED}"
    util.echo "  git.config.get <location> <key>"
    util.echo "  git.config.get --list"
    util.echo
    util.echo "ARGUMENTS" "${RED}"
    util.echo "  <location> # global (default), local"
    util.echo "  <key>      # e.g. user.name, user.email"
    util.echo
    util.echo "EXAMPLES" "${RED}"
    util.echo "  git.config.get global user.name"
    util.echo "  git.config.get user.name # default to global"
    util.echo
    return
  }

  # Overwrite default location if provided
  if [[ "$1" == "global" || "$1" == "local" ]]; then
    location="$1"
    shift
  fi
  
  local key="$1"

  util.echo.execute "git config --${location} ${key}"
}

# Is the current directory a valid git repo?
function git.is-valid-repo() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    return 0 # success
  else
    util.echo "Not in a git directory." "${RED}"
    return 1 # failure
  fi
}

# GitHub URL to create a pull request.
function git.pr_url() {
  echo "https://$(git.repo.host)/$(git.repo.owner)/$(git.repo.name)/compare"
}

# `git@<host>:<owner>/<repo>.git` => <host>
function git.repo.host() {
  echo $(git.repo.url) | cut -d '@' -f2 | cut -d ':' -f1
}

# `git@<host>:<owner>/<repo>.git` => <repo>
function git.repo.name() {
  echo $(git.repo.url) | cut -d '/' -f 2 | cut -d '.' -f 1
}

# `git@<host>:<owner>/<repo>.git` => <owner>
function git.repo.owner() {
  echo $(git.repo.url) | cut -d '@' -f2 | cut -d ':' -f2 | cut -d '/' -f1
}

# Absolute URL of git repo `git@<host>:<owner>/<repo>.git`
function git.repo.url() {
  # git config --get remote.origin.url
  git ls-remote --get-url
}

# File functions
#-----------------------------------------------------------------------

function file.exists() {
  [[ -f "$1" ]]
}

# IS boolean test functions
#-----------------------------------------------------------------------

function is.a-directory() {
  [[ -d "${1}" ]]
}

function is.blank() {
  [[ -z "${1}" ]]
}

# Check if variable is set. Do not pass in the "value" of the
# variable as $1, just the variable name.
function is.defined() {
  [[ -v $1 ]]
}

# Check if a string is a number, including negatives, floats, and integers.
function is.numeric() { 
  [[ $1 =~ ^[+-]?([0-9]+([.][0-9]*)?|\.[0-9]+)$ ]]
}

function is.present() {
  [[ -n "${1}" ]]
}

# Any of these values are considered true.
function is.true() {
  array.includes "$1" true "true" "TRUE" "yes" "YES" "y" "Y" "1"
}

# Array functions
#-----------------------------------------------------------------------

# Does not print anything, just returns 0 if includes, 1 if not.
function array.includes() {
  local search="$1"; 
  is.blank "$search" && return 1
  shift

  [[ "$*" =~ "${search}" ]] || return 1
  
  for e in "${@}"; do
    [[ "$e" == "${search}" ]] && {
      return 0
    }
  done

  return 1
}

# Combine $2* elements with $1 separator between each item.
function array.join() {
  local delimiter="$1"; shift
  echo -n "$1"; shift
  # ZSH prints out ending "%" if no endline
  printf "%s" "${@/#/$delimiter}"; echo
}

# Print array of $2* items one per line with $1 prefix.
function array.print-per-line() {
  if [[ $# -lt 2 ]]; then
    util.echo
    util.echo "Print array of items one per line with a prefix."
    util.echo
    util.echo "USAGE" "${RED}"
    util.echo "  array.print-per-line <prefix> <item1> <item2> ..."
    util.echo
    util.echo "EXAMPLES" "${RED}"
    util.echo "  array.print-per-line '- ' item1 item2 item3"
    util.echo
    return
  fi

  local prefix="$1"; shift

  for item in "${@}"; do
    printf "%s%s\n" "$prefix" "$item"
  done
}

function array.to.csv() {
  array.join ", " $*
}

function array.to.bullet-list() {
  array.print-per-line "- " $*
}
