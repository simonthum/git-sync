# git-sync

Synchronize tracking repositories.

This script intends to sync near-automatically via git
in "tracking" repositories where a nice history is not
as crucial as having one.

2012-2022 by Simon Thum and contributors, licensed under _CC0_

## Use case

Suppose you have a set of text files you care about, multiple machines
to work on, and a central git repository (a.k.a. bare repository) at
your disposal. You do not care about atomic commits, but coarse
versioning and backup is grave. For example, server configuration or
[org-mode](http://orgmode.org) files.

In that case, `git-sync` will help you keep things in sync.

Unlike the myriad of scripts to do just that already available,
it follows the KISS principle: It is safe, small, requires nothing but
git and bash, but does not even try to shield you from git. It is
non-interactive, but will cautiously exit with a useful hint or error
if there is any kind of problem.

It is ultimately intended for git-savvy people. As a rule of thumb, if
you know how to complete a failed rebase, you're fine.

To synchronize automatically on filesystem changes, have a look at the
`contrib` directory. Alternatively, here is an older blog about automatic
`git-sync` operation:

[Automated Syncing with Git](https://worthe-it.co.za/programming/2016/08/13/automated-syncing-with-git.html)

Tested on msysgit and a real bash. In case you know bash scripting, it
will probably make your eyes bleed, but for some reason it works.

If you prefer, there is a [Typescript implementation](https://github.com/tiddly-gittly/git-sync-js) too.

### What does `git-sync` do?

`git-sync` will likely get you from a dull normal git repo with some
changes to an updated dull normal git repo equal to origin. It does
this by commiting, pulling & pushing as appropriate.

Care has been taken that any kind of problem, pre-existing or not,
results in clear error messages and non-zero return code, but of
course no guarantee can be given.

The intent is to do everything that's needed to sync
automatically, and resort to manual intervention as soon
as something non-trivial occurs. It is designed to be safe
in that `git-sync` will likely refuse to do anything not known to
be safe.

You can invoke git-sync in "check" mode, in which `git-sync` will not do
anything except return zero if syncing may start, and non-zero if
manual intervention is required.

### How am I supposed to use it?

    git-sync [mode]

Mode can be empty, sync, or check.

In "check" mode, `git-sync` will indicate if synchronization may start. This is useful
to see if manual intervention is required (indicated by text and
non-zero exit code).

In sync mode (the default), just calling `git-sync` inside your
repository will sync with the current branches remote, if that
branch is enlisted.  The repository must not be in the middle of a
rebase, git-am, merge or whatever, not detached, and untracked files
may also be treated as an obstacle (see Options). However, sync is
likely to just work. Else, a clear error message should appear.

If you don't sync in an intertwined manner (from multiple
repositories/machines), `git-sync` is virtually guaranteed to succeed.
When required git-sync will try to rebase, which may fail. This is
when you'll need your git skills.

## How does it work?

The flow is roughly:

1. Sanity checks. You don't want to do this in the middle of a rebase.
2. Check for new files; exit if there are, unless allowed (see Options). In check mode, exit with 0.
3. Check for auto-commitable changes.
4. Perform auto-commit if there are any, see options.
5. Do one more check for leftover changes / general tidyness.
6. Fetch the upstream.
7. Relate upstream to ours. If ahead, push. If behind, fast-forward. If diverged, rebase, then push.
6. At exit, assert sync state once more just to be safe.

On the first invocation, `git-sync` will ask you to enlist the
current branch for sync using git config. This has to be done once for
every repository (and branch, for completeness).

Because git-sync rebases, the order of commits does not always reflect
the order of changes. However auto-commit records the originating machine
name and time by default.

## Options

There are three `git config`-based options for tailoring your sync:

    branch.$branch_name.syncNewFiles (bool)

Tells git-sync to invoke auto-commit even if new (untracked) files are
present. Normally you have to commit those yourself to prevent
accidental additions. git-sync will exit at stage 3 with an
explanation in that case.

    branch.$branch_name.syncCommitMsg (string)

A string which will be used in place of the default commit message (as shown
below).

    branch.$branch_name.autocommitscript (string)

A string which is being eval'ed by this script to perform an
auto-commit. Here you can run a commit script which should not
leave any uncommited state. The default will commit modified or
all files with a more or less useful message.

By default, commit is done using:

    git add -u ; git commit -m "changes from $(uname -n) on $(date)"

Or if you enable `syncNewFiles`:

    git add -A ; git commit -m \"changes from $(uname -n) on $(date)\";"

### Command-line flags

There are also some command-line flags you can set to control the sync:

`-n` is the equivalent of `branch.$branch_name.syncNewFiles`, adding new files
even if the matching `git config` option is not set.

`-s` is the equivalent of `branch.$branch_name.sync`, allowing syncing a branch
even if the matching `git config` option is not set.

# `contrib` contents

## git-sync-on-inotify

Automatically synchronize your git repository whenever a file is touched.

`git-sync-on-inotify` uses the functionality of `git-sync` together with an
`inotifywait` to automatically synchronize local changes you have made to your
files as soon as they happen. `inotifywait` waits for events from the operating
system which are triggered by any edits you make to files in the git repository.
This means that updates are near instantaneous, without the need to resort to
polling. `git-sync-on-inotify` still does a polling call to `git-sync` to ensure that changes from the upstream do make it in. This polling interval is configurable with the environment variable `GIT_SYNC_INTERVAL`.

By design, this solution may miss changes until the next
GIT_SYNC_INTERVAL time.

## modd.conf

Automatically sync upon local filesystem changes using modd.

https://github.com/cortesi/modd

This is a more robust solution to sync on local chances, but will not
poll upstream except on startup. If you manage not to interleave
sessions, that's fine.

# License

I declare this work to be useable under the provisions of the CC0 license.

http://creativecommons.org/publicdomain/zero/1.0/

Attribution is appreciated, but not required.

# Thanks

Thanks go to all the people behind git.
