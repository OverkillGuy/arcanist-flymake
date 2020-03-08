# arcanist-flymake.el - An arc lint backend for flymake

Report `arc lint` issues in Emacs via flymake.

[Arcanist](https://phacility.com/phabricator/arcanist/) is the [Phabricator](https://phacility.com/phabricator) command-line interface. Among many other cool features, it provides a way to run code checkers via its subcommand `arc lint`.
This project parses the output of `arc lint --output compiler` and reports them in Emacs by using flymake, a universal on-the-fly syntax checker.

# Dependencies
- Emacs and Flymake (bundled in Emacs)
- [Arcanist](https://secure.phabricator.com/book/phabricator/article/arcanist_quick_start/), set up with [linters](https://secure.phabricator.com/book/phabricator/article/arcanist_lint/)

# Installation

Currently, this project isn't uploaded to any of the Emacs package
repositories, so installation is not really supported right now.

However, the code is regular emacs lisp, so it can be loaded inside the editor via

	(load-library "arcanist-flymake.el")


# Usage
Assuming you have the library loaded as per installation instructions above.

Enable flymake as you would normally

	(flymake-mode)
and enable this backend

	(arcanist-setup-flymake-backend)

you should now see the code issues pop up on screen. 

## Troubleshooting

### I don't see any (meaningful) output

This project runs `arc lint` with a compiler-friendly format output
and parses it, so it might be worth checking arcanist setup.

Check `arc lint` is set up properly:

	arc lint --output compiler  # should not see setup errors

A common issue is lack of meaningful linters set up. Please refer to
the [arcanist documentation on linters](https://secure.phabricator.com/book/phabricator/article/arcanist_lint/).

# Licence

This project is licensed using GPLv3-or-later, see `LICENCE.txt`.
