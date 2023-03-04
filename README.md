<!--
  Copyright (c) 2023 Michael Federczuk
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

<!-- markdownlint-disable-next-line no-inline-html  -->
# Personal System Setup<sub>(Fedora 37 branch)</sub> #

This repository tracks all of my user/system configurations, preferences, dotfiles, custom aliases, functions, scripts,
programs, etc. of my personally used Linux distributions.

## Distributions ##

Each individual distribution — and their distinct versions/releases — has it's own branch.  
These distribution branches are prefixed with the string `distros/`.

As the name implies, the `base` branch is the basis for all other distributions.  
Changes are primarily made on this branch and then get merged into the active `distros/*` branches.

## Installation ##

To install (or uninstall) the files to their correct locations, the [`manage`](manage) script is used.  
This script will read the [`Instructions.cfg`](Instructions.cfg) files, which declare which files need to be installed
where.

## Licensing ##

For information about copying and licensing, see the [`COPYING.txt`](COPYING.txt) file.
