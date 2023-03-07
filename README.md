<!--
  Copyright (c) 2023 Michael Federczuk
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

<!-- markdownlint-disable-next-line no-inline-html  -->
# Personal System Setup<sub>(base branch)</sub> #

This repository tracks all of my user/system configurations, preferences, dotfiles, custom aliases, functions, scripts,
programs, etc. of my personally used Linux distributions.

## Directory Structure ##

* [`bin/`](bin)  
  Executable files, which all get installed to `$HOME/.local/bin/`

  * [`git/`](bin/git)  
    Custom Git commands, which also get installed to `$HOME/.local/bin/`

* [`cfg/`](cfg)  
  Configuration files for various programs, which mostly get installed either to `$HOME` or under `$XDG_CONFIG_HOME`

  * [`git/`](cfg/git)  
    Git configuration files, which get installed specifically to `$XDG_CONFIG_HOME/git/`

* [`shell/`](shell)  
  Shell setup files, which get installed under either `$HOME` or `$XDG_CONFIG_HOME`.  
  POSIX sh related files get installed specifically to `$HOME`

  * [`shells/`](shell/shells)  
    Subdirectories for different Unix shells

    * [`bash/`](shell/shells/bash)  
      GNU Bash startup files, which get installed either under `$HOME` or to `$XDG_CONFIG_HOME/bash/`

      * [`lib/`](shell/shells/bash/lib)  
        GNU Bash files that define various custom functions, which get installed to `$XDG_CONFIG_HOME/bash/lib/`

      * [`completions/`](shell/shells/bash/completions)  
        GNU Bash files that define completion functions, which get installed to `$HOME/.local/etc/bash_completion.d/`

        * [`git/`](shell/shells/bash/completions/git)  
          GNU Bash files that define completion functions for the custom Git commands located in [`bin/git/`](bin/git),
          which also get installed to `$HOME/.local/etc/bash_completion.d/`

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
