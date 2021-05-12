#!/bin/bash

SCRIPT=$(cat <<"EOF"
% Preface
echo "Hi."
# This tutorial is an in-depth look at how Git works, performing
# a lot of sometimes unusual steps to walk through interesting
# details. You will have to pay attention closely, or you will
# get lost on the way. But do not despair; you can run this
# tutorial on your computer, at the speed you want, skip to
# any step you want, and investigate the state of things in
# another terminal window at all times.§
# §
# In fact, you are looking at an HTML file generated from the output of that tutorial. (that's why there is that "echo Hi" thing above: the hack that the tutorial script is only allows comments after commands. :) )§
# §
# The code of the tutorial is here: github.com/bakkenbaeck/a-random-walk-through-git - clone it and run it on your machine!§
# §
# This tutorial is NOT for absolute beginners, nor is it a
# collection of "cooking recipies". Recipies will not help you
# understanding the broad picture, nor will they get you out
# of tricky situations.§
# Some deeper understanding by experimentation and investigation
# will, though. So let's get started.
echo "Terms"
# First, a quick recap of Git-related terms.§
# tree: set of files (filenames, perms, pointers to subtrees/file blobs, NOT timedates)§
# commit: metadata (time, author, pointer to tree, possibly pointer to parent commit(s))§
# HEAD: last commit hash/parent of next commit (local only, modified by, e.g., git checkout)§
# index/staging/cache: HEAD plus "changes to be committed" (local only, modified by, e.g., git add/reset, stored in .git)§
# working directory/WIP: index plus "changes not added for commit" (plain files, local only, modified by, e.g., git checkout/reset --hard)§
# §
# Ok? Then let's init a Git repository... and have a look at the
# files in the .git/ folder.
% .git/ files
git init . && git config --local user.name "Ijon Tichy" && git config --local user.email "ijon@beteigeuze.space" && rm -rf .git/hooks/ && find .git -type f
# Then, let's commit a README.
echo "This is not a README yet" > README && git add README && git commit -m "first commit"
# What files were created by the commit in the .git/ folder?
find . -type f
# Now there are three objects: commit, tree, blob (file).
# What file type do the Git object files use?
file .git/objects/*/*
# All internal blobs get compressed. Saves space and keeps grep clean. Yay!§
# More details on these files later.
cat .git/refs/heads/master
# This is the hash of HEAD of the master branch.
cat .git/HEAD
# This is a pointer to current HEAD (or a hash when in "detached HEAD" state).
cat .git/logs/refs/heads/master
# This is the reflog of master HEAD (cf. git reflog).§
# It is not part of repo but for local convenience only.§
# We'll look at it later.
file .git/index
# That's the file Git uses to keep track of the current index (local only).
# It is basically an uncommitted commit, or rather the 'tree' part of that.
# This file is one of the few Git files that is a bit magic, mostly because
# of speed optimization considerations: In order for "git status" to be able
# to run really fast, some data additional to the data kept in the actual repo
# has to be available. This is why .git/index is not just a standard tree
# object (which doesn't have the additional metadata).§
# We will not go into details here. Further reading:§
# https://github.com/git/git/blob/master/Documentation/technical/index-format.txt§
# https://mirrors.edge.kernel.org/pub/software/scm/git/docs/technical/racy-git.txt§
# https://stackoverflow.com/questions/4084921/what-does-the-git-index-contain-exactly§
git log
# Note the commit hash. It's basically§
# sha1sum(commit metadata including pointer to hash of tree)
% Commit hash in detail
sleep 1 && git commit --amend -m "first commit"
# We just amended the last commit but didn't actually change anything:
# same commit message, author, tree, and time.§
# But the commit hash has changed. Why?
git log --pretty=fuller
# Because there's more metadata than git log shows by default.
# There's an author date and a commit date. Amending a commit
# keeps the author date but updates the commit date.§
# Note that Git has separate author and committer to account
# for the traditional Linux email based patch workflow.
# Authors would send in patches by mail, maintainers pick up
# patches and commit (or reject).
GIT_COMMITTER_DATE="Jan 1 12:00 2000 +0000" git commit --amend --date="Jan 1 12:00 2000 +0000" -m "first commit"
# rewrite last commit with fixed times (--date sets author date)
GIT_COMMITTER_DATE="Jan 1 12:00 2000 +0000" git commit --amend --date="Jan 1 12:00 2000 +0000" -m "first commit"
# THAT works: commit hash stays the same.
git log --pretty=fuller
export GIT_COMMITTER_DATE="Jan 1 12:00 2000 +0000" && export GIT_AUTHOR_DATE="Jan 1 12:00 2000 +0000"
# Let us fix dates so that we have deterministic hashes.§
# For the purposes if this demo only; don't do this at home.
file .git/objects/*/*
# That's one tree (we didn't change files so far), one file, three commits (original, hash test, fixed time).
git branch test
file .git/objects/*/*
# Just creating a new branch doesn't create any new trees or commits or blobs.
cat .git/HEAD
# Right, we're still on master.
git checkout test
cat .git/HEAD
cat .git/refs/heads/test
# note that file is all that Git needs to handle (local) branches
file .git/objects/c8/d9b9c01eea11fb1032903b0dd2bea3eeb46f48
# we have an object with that commit hash, let's have a look
git cat-file -t c8d9b9c01eea11fb1032903b0dd2bea3eeb46f48
# cat-file is low level Git ('plumbing'); -t prints the object type...
git cat-file -p c8d9b9c01eea11fb1032903b0dd2bea3eeb46f48
# ...and -p pretty prints that object's content.
# Let's look at the referenced tree.
git cat-file -t b35c99875f5758f64e9348c05dac14848a046f59
# well that was obvious
git cat-file -p b35c99875f5758f64e9348c05dac14848a046f59
# Note file metadata (file mode bits, filename) is found in the tree's data.
# There's no file date: git checkout etc. always writes with current date as many
# tools (GNU make etc.) rely on file dates for their operation, e.g., make
# only rebuilds artifacts if the artifact filedate is older than the source
# file date - so checking out older project versions (with 'correct' old file
# dates) would not trigger rebuilds.§
# Let's look at the referenced blob.
git cat-file -t 5b6c6cb672dc1c3e3f38da4cc819c07da510fb59
git cat-file -p 5b6c6cb672dc1c3e3f38da4cc819c07da510fb59
# But how much magic does cat-file do?
zlib-flate -uncompress < .git/objects/5b/6c6cb672dc1c3e3f38da4cc819c07da510fb59 | hexdump -C
# It really is just zlib compressed type+length header, null byte, data.
# No magic!
zlib-flate -uncompress < .git/objects/5b/6c6cb672dc1c3e3f38da4cc819c07da510fb59 | sha1sum
# ...and the object filename really is just its hash.
zlib-flate -uncompress < .git/objects/b3/5c99875f5758f64e9348c05dac14848a046f59 | hexdump -C
# Same for the tree object. The 'garbage' in the ASCII representation is actually
# the README's blob hash in binary.
% Committing using plumbing commands
echo "The hard way" > test.txt
# Let's create a commit that adds this new file just using Git plumbing commands
# (git add etc. are 'porcelain').
git hash-object -w test.txt
# hash-object calculates the hash of the file (and, with -w, adds it to Git objects).§
# So we have the blob, but no corresponding tree or commit yet. Actually, that file
# is not even staged...
git update-index --add --cacheinfo 100644 3b85187168e709784298f3f62ea2aed5f496e5eb test.txt
# hash-object and update-index are the plumbing of git add.
# The 'cacheinfo' parameter contains file permissions.
git ls-files --stage
# This is the content of the .git/index file.
git status
# It worked! test.txt is a "new file".
# However, we still have no dedicated tree object yet - it's still all in the index.
git write-tree
# This took the index and created a tree object from it.
# We still need the commit object.
echo "a commit, done the hard way" | git commit-tree 9240cdb2b8598f50cb8b66328b5c31d077d14470 -p c8d9b9c01eea11fb1032903b0dd2bea3eeb46f48
# We have to reference the parent here.
git cat-file -p 5350fa43e7e3a6263c85e47d24b3351f84be9a22
# Looks fine!
git log
# ...but the new commit doesn't show up in the log yet since our HEAD
# is still the previous commit, and .git/refs/heads/master still needs
# to get updated.
echo 5350fa43e7e3a6263c85e47d24b3351f84be9a22 > .git/refs/heads/test
git log --format=fuller
# Great! This concludes a 'manual' commit using Git plumbing commands.§
# You can see that going full manual, i.e., creating the files
# needed to represent a commit in the .git/objects directory just
# using echo etc., would not be a big problem either.§
# §
# But isn't what we saw so far horribly inefficient once it comes to
# file changes? No diffs are saved ever, and each file version gets
# compressed to a new object file?§
# §
# That's right, but there's another layer of object storage in Git
# called 'packfiles'.§
# Let's create a new empty branch for testing that.
% Packfiles
git checkout --orphan packfile_demo && git rm --cached -r . && rm *
# Then, let's create a large file.
for i in {1..10000}; do echo $i >> largefile.txt; done && tail -v largefile.txt && git add largefile.txt && git commit -m "a large file"
# There's our large file (10000 numbered lines).
find .git/objects -type f && du -h --max-depth=0 .git/objects
# Note we have just a handful of files in the objects Git directory
# that take up little space.§
# Let's add stuff to the one large file and commit the change;
# repeat that a hundred times.
{ for i in {1..100}; do echo "Adding more... $i" >> largefile.txt; git commit -m "adding to largefile.txt, $i" largefile.txt; done } | tail --l 15
# Now, let's have a look at the Git internal objects.
echo -n "Number of files in objects dir: " && find .git/objects -type f | wc -l && du -h --max-depth=0 .git/objects
# That storage ballooned quite a bit.§
# Modifying and committing one file 100 times resulted in
# 100*3 (commit, tree, blob) files, and we have 100
# near-identical (compressed) copies of the large file
# in object storage now.
git gc
# garbage collection (which is a bit of a misnomer as it includes
# repacking) takes the individual object files and repacks
# them into packfiles, storing only differences for object files
# that are similar.
find .git/objects -type f && du -h --max-depth=0 .git/objects
# The objects directory is much smaller again.
find .git/refs -type f
# But where did our branch references go?
cat .git/packed-refs
# Similar to the object packfile format, Git may
# manage references in an optimized manner.
# Some projects have thousands of branches (and tags),
# and managing those in individual files is a waste.§
# See git-pack-refs for details.§
# Do the plumbing commands (cat-file etc.) still work?
git cat-file -p ddd7a4e
# The packfile layer is transparent to plumbing commands,
# e.g., cat-file will work as before, accessing packfiles
# instead of plain object files if necessary.§
# If you want to know more about packfiles:§
# https://git-scm.com/book/en/v2/Git-Internals-Packfiles§
# §
# Up to something completely different.§
# Some notes on the differences between§
# git checkout, git reset --soft, git reset (--mixed), git reset --hard...
% git checkout and detached HEAD
git checkout master && git status && head -v .git/HEAD
# checkout updates index and working directory.§
# checkout does not alter any branch HEAD (just .git/HEAD).§
# After checkout, the index and working directory (tree) will be identical
# to the chosen commit (tree) (with default options).
git checkout c8d9b9c01eea11fb1032903b0dd2bea3eeb46f48 && git status
# Specifying a commit hash for checkout will result in
# "detached HEAD" state.
cat .git/HEAD
# Note HEAD is just a hash now, not a ref:... reference to some
# .git/refs/heads/BRANCH pointer.§
# You can even commit things...
echo "commit in detached head" > detached.txt && git add detached.txt && git commit -m "detached.txt"
git checkout test
# ...and Git will helpfully warn you when moving away that
# without creating a branch or tag pointing to the last commit,
# it's dangling (a "loose object"). It'll be retrievable by
# hash only, and might get removed by garbage collection in a while
# (see gc.pruneExpire, default is two weeks).
% git reflog
git reflog | head
# The reflog is a local log of the HEAD pointer and other references.
# Whenever you do a commit/checkout/reset, a line will be written to this log.
# The log isn't part of the actual repo and will not be shared by "git push"
# and the like.§
# Note that the fun we had with the plumbing commands didn't update
# the reflog.§
# It's a handy thing to look at if you got lost at any point, or are
# working with detached HEAD and the like.§
# Note the reflog entries expire (see gc.reflogExpire, default 90 days).
# Also, the reflog provides functionality such as the master@{one.week.ago}
# notation, which really looks at the reflog (i.e., "what did master point
# to one week ago on this machine") and NOT at the commit log.§
# Up to git reset...
% The resets of Git
git checkout test && echo "...plus more text" >> test.txt && git add test.txt && git commit -m "changing test.txt" && git log --pretty=oneline
# To recap, in the test branch, we started with one commit adding
# the README, then one commit adding test.txt, and we just committed
# a change to test.txt.
git reset --soft 5350fa4 && git status
# reset --soft moves the HEAD of the current branch to the selected
# tree/commit.§
# It does *not* touch the index nor the working directory.§
# In consequence, after soft reset, git status will show differences
# of your (unchanged) working directory and index to the branch HEAD
# that has been reset.§
# That means that if you soft reset to any commit, then git commit
# again immediately, the resulting tree of the new commit will be
# identical to your starting working directory. One thing you can
# easily do with that is squashing commits within a branch, but
# probably rebase --interactive (we will look at that later) is
# better suited for that.§
# If you want to get rid of changes of a commit, reset --soft
# is not what you want.
git reset 5350fa4 && git status
# reset --mixed (the default) changes current branch HEAD *and* index
# to the selected tree/commit.§
# It does not touch the working directory.§
# This command is good for reworking commit(s), e.g., splitting
# changes that have been accidentally put into one commit,
# but similar to reset --soft, probably rebase --interactive
# will be the better choice for this.§
# Again, if you want to get rid of changes of a commit,
# reset --mixed is not what you want.
git reset --hard 5350fa4 && git status && head -v test.txt
# reset --hard additionally overwrites the working directory with
# the index. Any uncommitted changes of the working directory will be lost.§
# This is the go-to command to get rid of commits completely,
# switching around branches (e.g., if you want to switch master
# and dev branches), or get rid of any local changes (e.g.,
# git reset --hard origin/master).§
# §
# Note that all reset commands potentially move HEAD back in
# history (or to some commit that has no common ancestor with
# the previous state even). If that is done, if working with
# remote repositories, you will need to be able to force push.§
# §
# Time to dive into remote repositories.
% Working with remote repositories
ls -1 ../fakeremote
# For the purposes of this demo, we use a pre-initialized
# local bare repository as remote. A bare repository is
# basically just the contents of the .git/ folder, without
# any working directory.§
# This highlights a key aspect of what remotes
# are: They're basically just pointers to a separate .git/
# directory, regardless of whether they're reachable
# via SSH, HTTP, or directly via filesystem access.
git clone ../fakeremote git-playground
# Just pretend this was something like§
# git clone git@someserver:git-playground.git§
# Cloning a remote repository basically sets up a local
# empty .git/ repository and adds the remote repository
# as a remote called 'origin'. When using defaults, git clone
# then connects to the origin, fetches its Git object files,
# creates remote-tracking branches for the branches of the
# remote, then creates a local master branch, sets its HEAD
# to origin/master and checks it out.§
# Note that if you connect to an actual remote server,
# it will output "Enumerating objects" etc. messages during
# clone; that's the remote server repacking (only) those
# object files that are needed to finish the operation.
# I.e., any "loose objects" etc. are not transmitted,
# and in case you used the --depth or --single-branch
# options with git clone, just a fraction of the remote's
# objects will be transmitted typically.
cat git-playground/.git/config
# .git/config is used to keep track of the fact that the
# local master branch is tracking a remote repository
# branch.
find git-playground/.git/refs -type f && tail -v git-playground/.git/refs/remotes/origin/HEAD
# No magic: Remote branches are just text files
# containing commit references, just as are local branches.§
# There's no .git/refs/remotes/origin/master though...?
cat git-playground/.git/packed-refs
# Remember references may get packed instead of put in their own file.
# §
# Let's go back to the previous local example repository and do some cleanup.
rm -rf git-playground && git checkout master && git branch -D packfile_demo && git branch -D test
# ...and add the remote under the name 'playground':
git remote add playground ../fakeremote && git remote -v
# There's no need to start by cloning; you can add a
# remote to an existing local repository as well.
git branch -a
# No change is visible yet, even with the new remote
# added.
git fetch playground && git branch -a
# After git fetch, we see the remote branches.
# fetch doesn't change local branches nor the index
# nor the working directory.
cat .git/refs/remotes/playground/master && grep "master" .git/packed-refs
# Note that remotes/playground/master is completely
# different from our local master as currently these
# repositories have noting in common, which Git was
# also pointing out nicely during fetch.§
# §
# By the way, you probably don't want to use grep and
# cat to resolve references, especially with references
# getting stored in two different ways possibly.
git show-ref master
# ...is probably easier.§
cat .git/config
# Note that adding a remote didn't make any of our
# local branches track a remote one, in contrast to
# when cloning a repo.§
# §
# Say we want to push the local master to the remote.
# Does simple git push work?
git push playground master
# No. Our local master branch has no reference to the
# current remote master HEAD in its history, i.e.,
# the remote master HEAD is not any ancestor of our
# local master, so standard push will fail.§
# For the time being, let's push the local master
# to the remote, under another branch name.
git push playground master:master_in_playground
# git push supports LOCALBRANCH:REMOTEBRANCH syntax
# for pushing a local branch to a remote under a
# different name.
cat .git/config
# Note that just pushing our branch does *not* make
# our local master track the remote master_in_playground
# branch...
git pull
# ...which means that git pull does not know what to do.
git branch -u playground/master_in_playground
# branch -u (shorthand for branch --set-upstream-to)
# makes the current branch track a remote
# branch. When pushing a branch to a remote for the
# first time, the -u flag is available as well.
cat .git/config
# The tracking info has been added to .git/config...
git pull
# ...and git pull works just as expected.
git push playground --delete master_in_playground
# We did that only for demo purposes and delete the
# remote master_in_playground branch again.§
# Previously, the default push to remote master failed.§
# Let's force push which just overwrites the remote master
# HEAD without any checks.
git push --force playground master
# That works. It might not for 'true' remotes that have
# branch protection enabled. This feature disallows (force) pushes
# if there's no reference to the current remote HEAD in the
# pushed branch history; i.e., for protected branches you
# are limited to adding commits on top.§
# Protected branches are a feature of Git services such as
# GitHub and GitHub and can get configured in their web UIs.§
# Let's check if the push actually worked.
git show-ref master
# It did. The local master HEAD and the remote playground/master
# are identical now.§
# Let's not forget to set up remote tracking.
git branch -u playground/master
# Now, let's play around with commits, pushes, merges, and rebasing.
% Committing, pushing, merging, rebasing
echo "Commit A" > commit_a && git add commit_a && git commit -m 'commit_a' && git push playground
# ...so now we have a file 'commit_a' both locally and on the remote.
# Let's undo that commit locally.
git reset --hard HEAD~ && git status
# As expected, since we 'forgot' the last commit locally, the remote is
# ahead of us now. Let's ignore that and add another file locally,
# just as would happen if we kept developing while someone else
# pushed new commits to the server.
echo "Commit B" > commit_b && git add commit_b && git commit -m 'commit_b' && git status
# Local and remote master have diverged. push will fail now; force push
# would overwrite commit A in the remote repo.§
# Time for a bit of visualization, finally.
git config --local --add alias.graph "log --graph --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative --date-order" && git graph
# Now, what happens if we merge the remote master?§
# Merge never changes existing commits (but may create a new commit and a new tree).
# Typically, this means that other branches' changes are put *on top* of the current branch commits.
# But actually Git doesn't track diffs, so a merge commit is just a marker that two trees have been joined.
# Any merge conflicts get resolved 'within' the merge commit.
# That's nasty if there have been large conflicts as errors in conflict resolving are difficult to spot.
# Also, merging creates a bit of a convoluted git history:
git merge --no-edit playground/master && git graph
# We could push now, but that history is a bit convoluted
# for no good reason, right? It's not like the merge commit
# adds a lot of information here; it rather complicates things.§
# §
# Rebase takes another branch and puts the current branches' changes
# on top that, one by one.
# This of course changes commit hashes of the current branch
# (the history of a commit is part of the basis of its hash) but makes
# the local branch a straightforward continuiation of the remote.
# Let's reset to commit_b and rebase onto the remote master.
git reset --hard 40a1d20 && git rebase playground/master && git graph
# Much clearer. Note that the commit hash of our local commit_b has
# changed because now it has commit_a as parent instead of the first commit.
git status
# But that's okay as we can push now without any further complications.
git push && git graph
# There.§
# Of course, merge commits have their uses. For example, they are a
# good way to document the development process if the merge is the
# result of a (non-trivial) Pull Request: Without the merge commit,
# there would be no link to the Pull Request in the commit history.§
# §
# However, if you want to merge trivial things from a PR, do rebase your
# changes onto the destination branch first, then merge using
# git merge --ff-only MYBRANCH. This is what "Rebase and merge" in GitHub
# does as well (only they know why they don't indicate clearly that
# there'll be no merge commit in that case though, which might not
# always be desirable).§
# And IF you want to merge nontrivial things from a PR, do rebase your
# changes, then do a normal merge creating a merge commit so that
# the history has a pointer to the original PR. Rebasing first
# makes sure you don't have to resolve conflicts in the merge commit,
# which would be a nasty thing (e.g., mistakes introduced in merge
# commit conflict resolution are really hard to find later).
% Merge vs. rebase/cherry pick
# Instead of a rebase, we could also reset --hard to the branch we
# want to rebase onto, then git cherry-pick all the commits we want
# to add.§
# What is difference of cherry-pick and merge?
# git merge looks for the common ancestor, then does a diff between
# that ancestor and the specified commit, applies the diff to the
# current index, then commits the result, giving the specified commit as
# an additional parent of the merge commit (easy, isn't it?).§
# git cherry-pick doesn't look for an ancestor; it just diffs from
# the specified commit to its parent and applies and commits that
# diff. So cherry-pick is really only about changes introduced in
# single commits whereas merge is concerned with "everything up to"
# the specified commit.§
# Let's reset to an older commit, then cherry pick commits.
git reset --hard c8d9b9c && echo "---" && git cherry-pick 21d78fc 2d78b2c && echo "---" && git log --pretty=oneline
# Note the hashes stayed the same! This won't happen in practice,
# if you re-arrange commits, for example (and you didn't pin commit
# and author dates, as we did at the beginning).
git reset --hard c8d9b9c && echo "---" && git cherry-pick 2d78b2c 21d78fc && echo "---" && git log --pretty=oneline
# We changed the order of the two commits, and now their commit
# hashes have changed because their "parent" commit has changed,
# and that metadata is part of the commit hash.
% rebase --interactive
# A more comfortable and versatile way of rearranging commits
# is using interactive rebase. In standard usage, it opens a list
# of commits since the specified commit and lets you rework those
# commits; this includes rearranging/amending/editing/merging/dropping
# commits.
GIT_SEQUENCE_EDITOR=cat git rebase --interactive c8d9b9c
# (note the GIT_SEQUENCE_EDITOR=cat thing here is just to make the
# command non-interactive for the sake of this presentation)§
# Git is nice and displays a rather comprehensive help along with
# the commit list as well.§
# So, for rearranging commits in the style we did above using
# reset plus cherry-pick, we can just edit that list as well.
git reset --hard 2d78b2
# ...first, reset back to the "commit A first, then commit B" version...
GIT_SEQUENCE_EDITOR="../reverse_file" git rebase --interactive c8d9b9c && git log --pretty=oneline
# And behold, it's the same result as with the cherry picks:
# Now commit B comes first, and commit A is second.§
# §
# Note conflicts occurring during rebase may need some concentration
# to resolve. If you want to do something complex, consider issuing
# multiple rebase --interactive commands, rearranging and squashing
# commits in different runs. Take a look at git status often. Remember
# there's always git rebase --abort.§
# In general, a good practice is to do a rebase --interactive on your
# PR branches just before merging them in order to clean up the
# branch (not needed if you squash the PR branch commits in the merge
# anyways).
git reset --hard 2d78b2
# ...again, reset back to "commit A first, then commit B".
echo "Fixed commit A" > commit_a && git commit -m "fixup! commit_a" commit_a
# A quick look at a nice goodie built into rebase --interactive:
# When using the syntax "fixup! (some previous commit message)" as
# a commit message, that commit will be squashed into the referenced
# previous commit on a rebase --interactive --autosquash.
GIT_SEQUENCE_EDITOR=cat git rebase --interactive c8d9b9c --autosquash
# Nice: The fixup commit has been moved immediately after the commit
# it references, and the action has been changed to "fixup" as well.§
# Let's have a look at the history...
git log --pretty=oneline
# The fixup commit is gone and has been melded into the original commit.§
# Let's reset to a cleaner state for the next steps.
git reset --hard 2d78b2c
% Working with branches with differing trees
# Often, you will want to work on several branches that will never
# be identical, e.g., a development and a production branch that
# will diverge with regard to configuration and some code (debugging, etc.).§
# You don't want production-only commits winding up in development;
# you don't want development-only commits getting merged into production.§
# How can you do that?§
git branch production && git checkout production && echo "Production config" > production.conf && git add production.conf && git commit -m "production config"
git checkout master && echo "Development config" > development.conf && git add development.conf && git commit -m "development config"
# Ok great, so let's do some development in the master branch.
echo -e "#!/bin/bash\necho 'Hello world'" > hello_world.sh && chmod a+x hello_world.sh && git add hello_world.sh && git commit -m "add hello_world.sh"
# Now, let's merge that into production.
git checkout production && git merge --no-edit master
# That's not great. The development config was merged into production as well.
# We'll have to undo that.§
# But while we're at it, how does a merge commit look like?
git log -1
# Ok, and what does a merge commit look internally?
git cat-file -p 655b1cfd043d03966c5efcd5862535e7397edc35
# A merge commit has several parent commits instead of one
# parent.§
# Note that in the low level commit view this is nothing
# special at all - it does not spell out "merge"
# anywhere, and any commit might have 100 parent commits
# just as well as one or two parents, and yes,
# git merge actually supports merging more than one
# branch at once.§
# Also, note that there's no "main parent" or anything
# like that. All the parent metadata entries say is that
# the content of those parent commits is "taken care of"
# in this commit tree, and that's just the same for
# commits that have only one parent.§
# Anyways, we didn't want to merge development config.
# Let's quickly undo that.
git reset --hard caae1d1 && git graph
# We have to tell Git to ignore the commit that added the development
# config when merging.§
# This can be done by changing the "merge strategy".
# The default merge strategy is "recursive" which does merges
# as we all know.§
# There are other strategies as well, including the "ours"
# strategy, which actually ignores the things it is told
# to merge. That means it essentially marks things as
# merged (on commit/Git history level) when they are not
# (on file level). Great! That's what we want.
git merge -s ours -m 'fake merge: ignore dev config' 0f12049 && ls -1
# Looking good. Now merge the rest of the dev branch.
git merge --no-edit master && git graph && echo -e "\n---" && ls -1
# That worked! We don't have the dev config, but we do
# have the hello world file introduced in the dev branch.
# §
# By the way, the same outcome can be reached by doing all this
# manually using git commit-tree and giving the commit we want
# to "fake merge" as its parent. We leave this as an exercise to the
# reader.§
# §
# Now, a quick look at some things worth knowing.
% Goodies: --patch
for i in {100..200}; do echo "config_$i=false" >> production.conf; done && git commit -m "some more conf" production.conf
# We add some more lines to the production config.
sed -i -E 's/config_(..)0=false/config_\10=true/' production.conf && tail -v --l 20 production.conf
# ...then we change some lines in that config.§
# For quickly reviewing and staging changes, there's the
# "--patch" (-p) option available for git add and commit:
yes | git add -p production.conf
# This happens interactively (disabled here by the "yes" tool).
# ...git checkout and reset support -p, too,
# so for unstaging a file partially we can use reset HEAD -p:
yes | git reset HEAD -p production.conf
# ...let's check...
git status
# Correct.§
# Let's get rid of the changes for the next part about git bisect.
git checkout production.conf
% Goodies: Git bisect
# If your project has a bug that you knew wasn't there a year ago,
# but there's about 1000 commits to check, git bisect is there
# to help you. It runs a binary search on the commits, finding the
# commit that introduced the bug very quickly, and it can do that
# in an automated way.
git bisect start
# ...to start the process. Then, you have to mark the broken and
# a known good commit.
git bisect bad && git bisect good caae1d1
# Git now tells you how many revisions are left for testing, and
# how many steps this will take. Test, then mark, as appropriate.
git bisect bad
# etc. etc. - if you cannot test the current commit, you can skip:
git bisect skip
# ...of course bisect might not be able to tell the exect commit
# that broke things if it doesn't have complete information.§
# To end the bisect session once you are done, reset:
git bisect reset
# If you have tests ready that can just be run from command line,
# git bisect run SCRIPT is your friend.§
# Note that instead of "bad" and "good", any other terms can get
# used.§
# §
# For more information on git bisect, see§
# https://git-scm.com/docs/git-bisect§
# §
# Another goodie: If you frequently use long lived topic branches,
# you probably struggle with recurring merge conflicts.
# git rerere can help you with that.
% Goodies: Git rerere
# rerere means "Reuse recorded resolution of conflicted merges".
# Basically, rerere keeps a database of conflict resolutions
# and applies those resolutions if it sees the exact conflict
# again in any merge or rebase.
# Let's reset our development branche to the commit with that
# nice long configuration file, and create a new topic branch.
git remote rm playground && git reset --hard d0bb103 && git branch topic && git checkout topic && tail production.conf
# (of course, never branch off production for a topic branch
# in reality...)§
# Ok! Now we change some bits in the topic branch.
sed -i -E 's/config_(..)0=false/config_\10=true/' production.conf && tail -v --l 20 production.conf && git commit -m "changed config" production.conf
# Say that in the production branch some unrelated fix is made.
git checkout production && sed -i 's/config_100=false/config_100=file_not_found/' production.conf && git commit -m "fix config_100" production.conf
# Say we keep developing in the topic branch.
git checkout topic
# At some point, we want to check if merging with the main
# branch still works, so we do a "test merge" (that, once
# it's done, we'll roll back, since we don't really want
# that merge in our topic branch).
git merge production
# This results in a merge conflict.
git diff
# We could fix it and move on, but since in this development
# model we'd be re-doing that merge again later, we'd encounter
# that conflict again.§
# This is where rerere comes into play. We have to enable it first.
git config --local rerere.enabled true
# You might want to use --global instead of --local on your machine.
# Now, we roll back and trigger the merge again.
git merge --abort && git merge production
# There's the conflict again, but note that "Recorded preimage" line;
# that's by the rerere functionality.§
# Let's fix that conflict now.
git checkout topic production.conf && sed -i 's/config_100=true/config_100=file_not_found/' production.conf
# rerere can tell us about the current state of the resolution:
git rerere diff
# Let's finalize and commit the merge.
git add production.conf && git commit --no-edit
# Note the conflict resolution has been recorded by rerere.§
# If we roll back, then do the merge again, the conflict will get
# resolved by rerere without further manual intervention.
git reset --hard ddb58ff && git merge --no-edit production
# The merge will still complain, but the actual conflict is gone,
# i.e., one can add and commit the offending file.§
# Conflict resolutions will be used in rebase, too.
git reset --hard ddb58ff && git rebase production
# This looks bad, but DON'T PANIC.
git status
# This looks fine, doesn't it?
git diff
# ...and this looks even better, so just add and continue
# the rebase.
git add production.conf && git rebase --continue
# Let's look at the diff to production.
git diff production | head --l 20
# Such nice diff! Note there's no trace of the conflict.
git log --pretty=oneline
# ...and such nice history.
# §
# For more information on git rerere, see§
# https://git-scm.com/docs/git-rerere§
# https://git-scm.com/book/en/v2/Git-Tools-Rerere§
% Thanks
echo Thanks go to...
# Pro Git book https://git-scm.com/book/en/v2§
# Git plumbing https://medium.com/@shalithasuranga/how-does-git-work-internally-7c36dcb1f2cf§
# Fellow B&Bers for input§
EOF
)

which hexdump > /dev/null || { echo "Please install hexdump."; exit 1; }
which zlib-flate > /dev/null || { echo "Please install zlib-flate (typically bundled with qpdf)."; exit 1; }

rm -rf fakeremote > /dev/null 2>&1
(
export GIT_COMMITTER_DATE="Jan 1 12:00 2000 +0000" && export GIT_AUTHOR_DATE="Jan 1 12:00 2000 +0000"
mkdir fakeremote && cd fakeremote && git init --bare -q . && cd ..
git clone ./fakeremote git-playground > /dev/null 2>&1
cd git-playground && git config --local user.name "Professor Tarantoga" && git config --local user.email "tarantoga@beteigeuze.space"
touch README && git add README && git commit -q -m 'initial commit' && git push -q && cd .. && rm -rf git-playground
)
rm -rf example > /dev/null 2>&1
mkdir example
cd example
SKIPSTEPS="${1:-0}"
OUTPUTHTML="${OUTPUTHTML:-0}"
INCOMMENT=0
DIDCMD=0
STEPNO=1
IFS=$'\n'
if [[ $OUTPUTHTML == 1 ]]; then
  echo "<html><head><title>A Random Walk Through Git</title><style>.cmdline { background-color: lightgray; margin-top: 36px; } .cmdoutput { background-color: lavender; }</style></head>"
  echo "<body><h2>A Random Walk Through Git</h2><a href='https://bakkenbaeck.github.io/a-random-walk-through-git'>Website</a> - <a href='https://github.com/bakkenbaeck/a-random-walk-through-git'>on GitHub</a>"
fi

for line in $SCRIPT; do
  if [[ $line == \%* ]]; then
    if [[ $OUTPUTHTML == 1 ]]; then
      if [[ $STEPNO == 1 ]]; then echo "<ul>" > ../contents.html; fi
      echo "<li><a href=\"#headline$STEPNO\">$(echo "$line" | tail -c +3)</a></li>" >> ../contents.html
      if [[ $INCOMMENT == 1 ]]; then
        echo "</p>"
        INCOMMENT=0
      fi
      echo "<h3 class=\"headline\" id=\"headline$STEPNO\">$(echo "$line" | tail -c +3)</h3>"
    fi
    continue
  fi
  echo ""
  if [[ $line == \#* ]]; then
    if [[ $OUTPUTHTML == 1 ]]; then
      if [[ $INCOMMENT == 0 ]]; then
        echo "<p class=\"cmdcomment\">"
        INCOMMENT=1
      fi
      line="$(echo "$line" | tail -c +3 | sed 's/§$/<br>/')"
      echo "$line"
    else
      echo -n -e "\e[1m"
      line="$(echo "$line" | sed 's/§$//')"
      echo -n "$line"
      echo -n -e "\e[0m"
    fi
    continue
  fi

  if [[ $DIDCMD == 1 && $SKIPSTEPS -lt 1 ]]; then read; fi
  if [[ $OUTPUTHTML == 1 ]]; then
    if [[ $INCOMMENT == 1 ]]; then
      echo "</p>"
      INCOMMENT=0
    fi
    echo "<pre class=\"cmdline\" id=\"step$STEPNO\">$STEPNO# $(echo "$line" | sed 's/</\&lt;/')</pre>"
    echo "<pre class=\"cmdoutput\">"
    # have to redirect here since in pipes, commands get executed in subshells, which breaks export
    eval "$line" 2>&1 > /tmp/_git_demo.tmp
    cat /tmp/_git_demo.tmp | sed 's/</\&lt;/g'
    echo "</pre>"
  else
    echo -n -e "\e[7m"
    echo -n "$STEPNO"
    echo "# $line"
    echo -n -e "\e[0m"
    eval "$line" 2>&1
  fi
  DIDCMD=1
  STEPNO=$(($STEPNO+1))
  SKIPSTEPS=$(($SKIPSTEPS-1))
done

echo ""
if [[ $OUTPUTHTML == 1 ]]; then
  echo "</body></html>"
  echo "</ul>" >> ../contents.html
fi
