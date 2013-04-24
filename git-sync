#!/usr/bin/env bash
#
# git-sync
#
# sychronize tracking repositories
#
# 2012 by Simon Thum
# Licensed as: CC0
#
# This scrips intends to sync via git near-automatically
# in "tracking" repositories where a nice history is not
# crucial as having one.
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
# Check only performs the basic checks sync checks for to
# make sure the repository is in a state sufficiently "normal"
# to continue syncing, i.e. committing changes, pull etc. without
# losing any data. When check returns 0, sync can start immediately.
# This does not, however, indicate that syncing is at all likely to
# succeed.

# command used to auto-commit file modifications
DEFAULT_AUTOCOMMIT_CMD="git add -u ; git commit -m \"changes from $(uname -n) on $(date)\";"

# command used to auto-commit all changes
ALL_AUTOCOMMIT_CMD="git add -A ; git commit -m \"changes from $(uname -n) on $(date)\";"


# AUTOCOMMIT_CMD="echo \"Please commit or stash pending changes\"; exit 1;"
# TODO mode for stash push & pop



#
#    utility functions, some adapted from git bash completion
#

# echo the git dir
__gitdir()
{
	if [ "true" = "$(git rev-parse --is-inside-work-tree)" ]; then
		git rev-parse --git-dir 2>/dev/null
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
    if [ "true" == "$syncNew" ]; then
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
	echo "git-sync: In sync, all fine."
	exit 0;
    else
	echo "git-sync: Synchronization FAILED! You should definitely check your repository carefully!"
	echo "(Possibly a transient network problem? Please try again in that case.)"
	exit 3
    fi
}

#
#        Here git-sync actually starts
#

# first some sanity checks
rstate="$(git_repo_state)"
if [[ -z "$rstate" || "|DIRTY" = "$rstate" ]]; then
    echo "git-sync: Preparing. Repo in $(__gitdir)"
elif [[ "NOGIT" = "$rstate" ]] ; then
    echo "git-sync: No git repository detected. Exiting."
    exit 128 # matches git's error code
else
    echo "git-sync: Git repo state considered unsafe for sync: $(git_repo_state)"
    exit 2
fi

# determine the current branch (thanks to stackoverflow)
branch_name=$(git symbolic-ref -q HEAD)
branch_name=${branch_name##refs/heads/}

if [ -z "$branch_name" ] ; then
    echo "git-sync: Syncing is only possible on a branch."
    git status
    exit 2
fi

# while at it, determine the remote to operate on
remote_name=$(git config --get branch.$branch_name.remote)

if [ -z "$remote_name" ] ; then
    echo "git-sync: the current branch does not have a configured remote."
    exit 2
fi

# check if current branch is configured for sync
if [ "true" != "$(git config --get --bool branch.$branch_name.sync)" ] ; then
    echo
    echo "git-sync: Please use"
    echo
    echo "  git config --bool branch.$branch_name.sync true"
    echo
    echo "to whitelist branch $branch_name for synchronization."
    echo "Branch $branch_name has to have a same-named remote branch"
    echo "for git-sync to work."
    echo
    echo "(If you don't know what this means, you should change that"
    echo "before relying on this script. You have been warned.)"
    echo
    exit 1
fi

# determine mode
if [[ -z "$1" || "$1" == "sync" ]]; then
    mode="sync"
elif [[ "check" == "$1" ]]; then
    mode="check"
else
    echo "git-sync: Mode $1 not recognized"
    exit 100
fi

echo "git-sync: Mode $mode"

echo "git-sync: Using $remote_name/$branch_name"

# check for intentionally unhandled file states
if [ ! -z "$(check_initial_file_state)" ] ; then
    echo "git-sync: There are changed files you should probably handle manually."
    git status
    exit 1
fi

# if in check mode, this is all we need to know
if [ $mode == "check" ] ; then
    echo "git-sync: check OK; sync may start."
    exit 0
fi

# check if we have to commit local changes, if yes, do so
if [ ! -z "$(local_changes)" ]; then
    autocommit_cmd=""
    config_autocommit_cmd="$(git config --get branch.$branch_name.autocommitscript)"
    
    # discern the three ways to auto-commit
    if [ ! -z "$config_autocommit_cmd" ]; then
	autocommit_cmd="$config_autocommit_cmd"
    elif [ "true" == "$(git config --get --bool branch.$branch_name.syncNewFiles)" ]; then
	autocommit_cmd=${ALL_AUTOCOMMIT_CMD}
    else
        autocommit_cmd=${DEFAULT_AUTOCOMMIT_CMD}
    fi
    
    echo "git-sync: Commiting local chages using ${autocommit_cmd}"
    eval $autocommit_cmd

    # after autocommit, we should be clean
    rstate="$(git_repo_state)"
    if [[ ! -z "$rstate" ]]; then
	echo "git-sync: Auto-commit left uncommited changes. Please add or remove them as desired and retry."
	exit 1
    fi
fi

# fetch remote to get to the current sync state
# TODO make fetching/pushing optional
echo "git-sync: Fetching from $remote_name"
git fetch $remote_name
if [ $? != 0 ] ; then
    echo "git-sync: git fetch $remote_name returned non-zero. Likely a network problem; exiting."
    exit 3
fi

case "$(sync_state)" in
"noUpstream")
	echo "git-sync: Strange state, you're on your own. Good luck."
	exit 2
	;;
"equal")
	exit_assuming_sync
	;;
"ahead")
	echo "git-sync: Pushing changes..."
	git push $remote_name $branch_name:$branch_name
	if [ $? == 0 ]; then
	    exit_assuming_sync
	else
	    echo "git-sync: git push returned non-zero. Likely a connection failure."
	    exit 3
	fi
	;;
"behind")
	echo "git-sync: We are behind, fast-forwarding..."
	git merge --ff --ff-only $remote_name/$branch_name
	if [ $? == 0 ]; then
	    exit_assuming_sync
	else
	    echo "git-sync: git merge --ff --ff-only returned non-zero ($?). Exiting."
	    exit 2
	fi
	;;
"diverged")
	echo "git-sync: We have diverged. Trying to rebase..."
	git rebase $remote_name/$branch_name
	if [[ $? == 0 && -z "$(git_repo_state)" && "ahead" == "$(sync_state)" ]] ; then
	    echo "git-sync: Rebasing went fine, pushing..."
	    git push $remote_name $branch_name:$branch_name
	    exit_assuming_sync
	else
	    echo "git-sync: Rebasing failed, likely there are conflicting changes. Resolve them and finish the rebase before repeating git-sync."
	    exit 1
	fi
	# TODO: save master, if rebasing fails, make a branch of old master
	;;
esac

