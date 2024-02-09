<!--
  Copyright (c) 2024 Michael Federczuk
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

<!-- markdownlint-disable-next-line no-inline-html  -->
# Personal System Setup<sub>(Fedora 39 branch)</sub> #

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
        GNU Bash files that define completion functions, which get installed to `$XDG_CONFIG_HOME/bash/completions/`

        * [`git/`](shell/shells/bash/completions/git)  
          GNU Bash files that define completion functions for the custom Git commands located in [`bin/git/`](bin/git),
          which also get installed to `$XDG_CONFIG_HOME/bash/completions/`

## Distributions ##

Each individual distribution — and their distinct versions/releases — has it's own branch.  
These distribution branches are prefixed with the string `distros/`.

As the name implies, the `base` branch is the basis for all other distributions.  
Changes are primarily made on this branch and then get merged into the active `distros/*` branches.

## Installation ##

The files are installed using the script [`manage`](manage).  
Passing the command "`install`" or "`uninstall`" will copy all files to the intended locations or
remove them from there again, respectively.

Where each file will be installed to is declared in the `Instructions.cfg` files.

### Custom Locale ###

I use a custom locale, which is a combination of the US American English language and Austrian regional formats.
(along with some personal customizations to those formats)

This custom locale can be installed using the script [`install-custom-local`](install-custom-locale)
(root access is required) and then set as the system's locale with the script [`set-custom-locale`](set-custom-locale).

## Licensing ##

For information about copying and licensing, see the [`COPYING.txt`](COPYING.txt) file.
