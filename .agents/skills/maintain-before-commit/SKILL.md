---
name: maintain-before-commit
description: >-
  Before any git commit, check that names still match what they do, that new
  and moved files sit in the existing layout, and that the code under
  development does not reach the network unless the user has confirmed it.
  Use before committing, when asked to commit, or when staging changes in any
  repository.
---

# Maintain before commit

Run this on the changes about to be committed. Fix mismatches in that change set before the commit. Leave unrelated code alone.

## Names match use

Check every identity the change adds or changes: directories, files, packages, types, functions, methods, variables, constants, and configuration keys.

- The name states the current role. A reader can tell what it is from the name and where it lives.
- If behavior changed and the name did not, rename the identity and its references in this change.
- Do not keep a name that describes a former role, a broader role than the code has, or a narrower role than the code has.
- Match the naming style already used next to the change.

## Layout matches the repository

- Put new files beside the code they belong with. Follow directories and file-name patterns already in the tree.
- Add a new directory only when existing directories cannot hold the file without mixing unrelated responsibilities.
- Do not introduce a second place for the same kind of file.

## The product does not reach the network unless confirmed

This applies to code, scripts, hooks, docs, and dependency declarations that ship as part of the program under development.

- Do not add or leave behavior that fetches, dials, downloads, phones home, or calls a remote API unless the user has confirmed that access in this conversation.
- If a plan or task already requires confirmation before a network step, get that confirmation before writing the step in.

Cloning, fetching, pushing, and installing tools to work on the repository are ordinary maintainer actions. They are not a violation of this rule. A plan may still require confirmation before those actions; follow that plan.

## Before the commit

1. Read the staged and unstaged diff.
2. Fix name and layout mismatches caused by that diff.
3. Remove or rewrite unconfirmed network access in the product code in that diff, then tell the user what was removed.
4. Commit only after those fixes are included, and only when the user asked for the commit.
