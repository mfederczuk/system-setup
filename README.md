<!--
  Copyright (c) 2025 Michael Federczuk
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

<!-- markdownlint-disable-next-line no-inline-html  -->
# Personal System Setup<sub>(Ubuntu 22.04 branch)</sub> #

This repository tracks all of my user/system configurations, preferences, dotfiles, custom aliases, functions, scripts,
programs, etc. of my personally used Linux distributions.

## [`setup`](setup) Directory Structure ##

* [`bin/`](setup/bin)  
  Executable files, which all get installed to `$HOME/.local/bin/`

  * [`git/`](setup/bin/git)  
    Custom Git commands, which also get installed to `$HOME/.local/bin/`

* [`custom-locale/`](setup/custom-locale)  
  Files and scripts for my custom locale (see [the section Custom Locale](#custom-locale))

* [`gnome/`](setup/gnome)  
  Custom GNOME shell theme, which gets installed to `$HOME/.themes`

* [`gtk/`](setup/gtk)  
  GTK configuration files, which get installed under `$XDG_CONFIG_HOME`

* [`programs/`](setup/programs)  
  Configuration files for various programs, which mostly get installed either to `$HOME` or under `$XDG_CONFIG_HOME`.  
  Each separate program has its own subdirectory.

* [`shell/`](setup/shell)  
  Shell setup files, which get installed to `$HOME`

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

This custom locale can be installed using the script [`setup/custom-locale/install`](setup/custom-locale/install)
(root access is required) and then set as the system's locale with
the script [`setup/custom-locale/set-as-system-locale`](setup/custom-locale/set-as-system-locale).

## Licensing ##

For information about copying and licensing, see the [`COPYING.txt`](COPYING.txt) file.
