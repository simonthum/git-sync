#!/usr/bin/env bash
#
# git-sync
#
# synchronize tracking repositories
#
# 2012-20 by Simon Thum and contributors
# Licensed as: CC0
#
# This script intends to sync via git near-automatically
# in "tracking" repositories where a nice history is not
# crucial, but having one at all is.
#
# Unlike the myriad of scripts to do just that already available,
# it follows the KISS principle: It is small, requires nothing but
# git and bash, but does not even try to shield you from git.
#
# Mode sync (default)
#
# Sync will likely get from you from a dull normal git repo with trivial
# changes to an updated dull normal git repo equal to origin. No more,
# no less. The intent is to do everything that's needed to sync
# automatically, and resort to manual intervention as soon
# as something non-trivial occurs. It is designed to be safe
# in that it will likely refuse to do anything not known to
# be safe.
#
# Mode check
#
# Check only performs the basic checks to make sure the repository
# is in an orderly state to continue syncing, i.e. committing
# changes, pull etc. without losing any data. When check returns
# 0, sync can start immediately. This does not, however, indicate
# that syncing is at all likely to succeed.

# command used to auto-commit file modifications
DEFAULT_AUTOCOMMIT_CMD="git add -u ; git commit -m \"%message\";"

# command used to auto-commit all changes
ALL_AUTOCOMMIT_CMD="git add -A ; git commit -m \"%message\";"

# default commit message substituted into autocommit commands
DEFAULT_AUTOCOMMIT_MSG="changes from $(uname -n) on $(date)"


# AUTOCOMMIT_CMD="echo \"Please commit or stash pending changes\"; exit 1;"
# TODO mode for stash push & pop

print_usage() {
    cat << EOF
usage: $0 [-h] [-n] [-s] [MODE]

Synchronize the current branch to a remote backup
MODE may be either "sync" (the default) or "check", to verify that the branch is ready to sync

OPTIONS:
   -h      Show this message
   -n      Commit new files even if branch.\$branch_name.syncNewFiles isn't set
   -s      Sync the branch even if branch.\$branch_name.sync isn't set
EOF
}
sync_new_files_anyway="false"
sync_anyway="false"

while getopts "hns" opt ; do
    case $opt in
        h )
            print_usage
            exit 0
            ;;
        n )
            sync_new_files_anyway="true"
            ;;
        s )
            sync_anyway="true"
            ;;
    esac
done
shift $((OPTIND-1))

#
#    utility functions, some adapted from git bash completion
#

__log_msg()
{
    echo git-sync: $1
}

# echo the git dir
__gitdir()
{
	if [ "true" = "$(git rev-parse --is-inside-work-tree "$PWD" | head -1)" ]; then
		git rev-parse --git-dir "$PWD" 2>/dev/null
	fi
}

# echos repo state
git_repo_state ()
{
	local g="$(__gitdir)"
	if [ -n "$g" ]; then
		if [ -f "$g/rebase-merge/interactive" ]; then
			echo "REBASE-i"
		elif [ -d "$g/rebase-merge" ]; then
			echo "REBASE-m"
		else
			if [ -d "$g/rebase-apply" ]; then
				echo "AM/REBASE"
			elif [ -f "$g/MERGE_HEAD" ]; then
				echo "MERGING"
			elif [ -f "$g/CHERRY_PICK_HEAD" ]; then
				echo "CHERRY-PICKING"
			elif [ -f "$g/BISECT_LOG" ]; then
				echo "BISECTING"
			fi
		fi
		if [ "true" = "$(git rev-parse --is-inside-git-dir 2>/dev/null)" ]; then
			if [ "true" = "$(git rev-parse --is-bare-repository 2>/dev/null)" ]; then
				echo "|BARE"
			else
				echo "|GIT_DIR"
			fi
		elif [ "true" = "$(git rev-parse --is-inside-work-tree 2>/dev/null)" ]; then
			git diff --no-ext-diff --quiet --exit-code || echo "|DIRTY"
#			if [ -n "${GIT_PS1_SHOWSTASHSTATE-}" ]; then
#			        git rev-parse --verify refs/stash >/dev/null 2>&1 && s="$"
#			fi
#
#			if [ -n "${GIT_PS1_SHOWUNTRACKEDFILES-}" ]; then
#			   if [ -n "$(git ls-files --others --exclude-standard)" ]; then
#			      u="%"
#			   fi
#			fi
#
#			if [ -n "${GIT_PS1_SHOWUPSTREAM-}" ]; then
#				__git_ps1_show_upstream
#			fi
		fi
	else
	    echo "NOGIT"
	fi
}

# check if we only have untouched, modified or (if configured) new files
check_initial_file_state()
{
    local syncNew="$(git config --get --bool branch.$branch_name.syncNewFiles)"
    if [[ "true" == "$syncNew" || "true" == "$sync_new_files_anyway" ]]; then
	# allow for new files
	if [ ! -z "$(git status --porcelain | grep -E '^[^ \?][^M\?] *')" ]; then
	    echo "NonNewOrModified"
	fi
    else
	# also bail on new files
	if [ ! -z "$(git status --porcelain | grep -E '^[^ ][^M] *')" ]; then
	    echo "NotOnlyModified"
	fi
    fi
}

# look for local changes
# used to decide if autocommit should be invoked
local_changes()
{
    if [ ! -z "$(git status --porcelain | grep -E '^(\?\?|[MARC] |[ MARC][MD])*')" ]; then
	echo "LocalChanges"
    fi
}

# determine sync state of repository, i.e. how the remote relates to our HEAD
sync_state()
{
    local count="$(git rev-list --count --left-right $remote_name/$branch_name...HEAD)"

    case "$count" in
	"") # no upstream
	    echo "noUpstream"
	    false
	    ;;
	"0	0")
	    echo "equal"
	    true
	    ;;
	"0	"*)
	    echo "ahead"
	    true
	    ;;
	*"	0")
	    echo "behind"
	    true
	    ;;
	*)
	    echo "diverged"
	    true
	    ;;
    esac
}

# exit, issue warning if not in sync
exit_assuming_sync() {
    if [ "equal" == "$(sync_state)" ] ; then
	__log_msg "In sync, all fine."
	exit 0;
    else
	__log_msg "Synchronization FAILED! You should definitely check your repository carefully!"
	__log_msg "(Possibly a transient network problem? Please try again in that case.)"
	exit 3
    fi
}

#
#        Here git-sync actually starts
#

# first some sanity checks
rstate="$(git_repo_state)"
if [[ -z "$rstate" || "|DIRTY" = "$rstate" ]]; then
    __log_msg "Preparing. Repo in $(__gitdir)"
elif [[ "NOGIT" = "$rstate" ]] ; then
    __log_msg "No git repository detected. Exiting."
    exit 128 # matches git's error code
else
    __log_msg "Git repo state considered unsafe for sync: $(git_repo_state)"
    exit 2
fi

# determine the current branch (thanks to stackoverflow)
branch_name=$(git symbolic-ref -q HEAD)
branch_name=${branch_name##refs/heads/}

if [ -z "$branch_name" ] ; then
    __log_msg "Syncing is only possible on a branch."
    git status
    exit 2
fi

# while at it, determine the remote to operate on
remote_name=$(git config --get branch.$branch_name.pushRemote)
if [ -z "$remote_name" ] ; then
    remote_name=$(git config --get remote.pushDefault)
fi
if [ -z "$remote_name" ] ; then
    remote_name=$(git config --get branch.$branch_name.remote)
fi

if [ -z "$remote_name" ] ; then
    __log_msg "the current branch does not have a configured remote."
    echo
    __log_msg "Please use"
    echo
    __log_msg "  git branch --set-upstream-to=[remote_name]/$branch_name"
    echo
    __log_msg "replacing [remote_name] with the name of your remote, i.e. - origin"
    __log_msg "to set the remote tracking branch for git-sync to work"
    exit 2
fi

# check if current branch is configured for sync
if [[ "true" != "$(git config --get --bool branch.$branch_name.sync)" && "true" != "$sync_anyway" ]] ; then
    echo
    __log_msg "Please use"
    echo
    __log_msg "  git config --bool branch.$branch_name.sync true"
    echo
    __log_msg "to enlist branch $branch_name for synchronization."
    __log_msg "Branch $branch_name has to have a same-named remote branch"
    __log_msg "for git-sync to work."
    echo
    __log_msg "(If you don't know what this means, you should change that"
    __log_msg "before relying on this script. You have been warned.)"
    echo
    exit 1
fi

# determine mode
if [[ -z "$1" || "$1" == "sync" ]]; then
    mode="sync"
elif [[ "check" == "$1" ]]; then
    mode="check"
else
    __log_msg "Mode $1 not recognized"
    exit 100
fi

__log_msg "Mode $mode"

__log_msg "Using $remote_name/$branch_name"

# check for intentionally unhandled file states
if [ ! -z "$(check_initial_file_state)" ] ; then
    __log_msg "There are changed files you should probably handle manually."
    git status
    exit 1
fi

# if in check mode, this is all we need to know
if [ $mode == "check" ] ; then
    __log_msg "check OK; sync may start."
    exit 0
fi

# check if we have to commit local changes, if yes, do so
if [ ! -z "$(local_changes)" ]; then
    autocommit_cmd=""
    config_autocommit_cmd="$(git config --get branch.$branch_name.autocommitscript)"

    # discern the three ways to auto-commit
    if [ ! -z "$config_autocommit_cmd" ]; then
	autocommit_cmd="$config_autocommit_cmd"
    elif [[ "true" == "$(git config --get --bool branch.$branch_name.syncNewFiles)" || "true" == "$sync_new_files_anyway" ]]; then
	autocommit_cmd=${ALL_AUTOCOMMIT_CMD}
    else
        autocommit_cmd=${DEFAULT_AUTOCOMMIT_CMD}
    fi

    commit_msg="$(git config --get branch.$branch_name.syncCommitMsg)"
    if [ "" == "$commit_msg" ]; then
      commit_msg=${DEFAULT_AUTOCOMMIT_MSG}
    fi
    autocommit_cmd=$(echo "$autocommit_cmd" | sed "s/%message/$commit_msg/")

    __log_msg "Committing local changes using ${autocommit_cmd}"
    eval $autocommit_cmd

    # after autocommit, we should be clean
    rstate="$(git_repo_state)"
    if [[ ! -z "$rstate" ]]; then
	__log_msg "Auto-commit left uncommitted changes. Please add or remove them as desired and retry."
	exit 1
    fi
fi

# fetch remote to get to the current sync state
# TODO make fetching/pushing optional
__log_msg "Fetching from $remote_name/$branch_name"
git fetch $remote_name $branch_name
if [ $? != 0 ] ; then
    __log_msg "git fetch $remote_name returned non-zero. Likely a network problem; exiting."
    exit 3
fi

case "$(sync_state)" in
"noUpstream")
	__log_msg "Strange state, you're on your own. Good luck."
	exit 2
	;;
"equal")
	exit_assuming_sync
	;;
"ahead")
	__log_msg "Pushing changes..."
	git push $remote_name $branch_name:$branch_name
	if [ $? == 0 ]; then
	    exit_assuming_sync
	else
	    __log_msg "git push returned non-zero. Likely a connection failure."
	    exit 3
	fi
	;;
"behind")
	__log_msg "We are behind, fast-forwarding..."
	git merge --ff --ff-only $remote_name/$branch_name
	if [ $? == 0 ]; then
	    exit_assuming_sync
	else
	    __log_msg "git merge --ff --ff-only returned non-zero ($?). Exiting."
	    exit 2
	fi
	;;
"diverged")
	__log_msg "We have diverged. Trying to rebase..."
	git rebase $remote_name/$branch_name
	if [[ $? == 0 && -z "$(git_repo_state)" && "ahead" == "$(sync_state)" ]] ; then
	    __log_msg "Rebasing went fine, pushing..."
	    git push $remote_name $branch_name:$branch_name
	    exit_assuming_sync
	else
	    __log_msg "Rebasing failed, likely there are conflicting changes. Resolve them and finish the rebase before repeating git-sync."
	    exit 1
	fi
	# TODO: save master, if rebasing fails, make a branch of old master
	;;
esac
