---
title: Using Git Hooks Effectively
date: December 4, 2013
template: article.jade
---

#### What are they?

Git hooks run arbitrary code from executable files stored in the .git/hooks directory of your git repository. The are a a number of different hooks available, and you can find the definitive list of them [here][1]. These are some example of how to put the pre- and post-commit hooks to good use in your projects.

---

#### Pushing to gh-pages

A great example of using the git post-commit hook is mention in [this article][2], which looks at a number of ways to efficiently manage GitHub's pages feature without constantly switching between branches and merging content. Using this hook, you can effectively keep your repository's gh-pages branch up-to-date every time you commit a change on your current branch.

```bash
#!/bin/sh
git checkout gh-pages
git rebase master
git checkout master
```

One thing to note with this example is that the `gh-pages` branch must already exist, and you must use the `--all` flag when pushing your changes to GitHub.

#### Compiling/linting build directories before commits

If you maintain library code that needs to be compiled or linted everytime you commit chages, this is the hook for you. This hooks has been useful in several projects in order to make sure the build files are kept up to date with any changes to the source code. In this example, it's running the build and lint functions declared in the projects Cakefile, but you could use it with grunt or any other compilation tool. When building, this hook is using the `package.json` for the version number, so that all committed files are correctly labelled when using `npm version`.

```bash
#!/bin/sh
cake build
cake lint
git add --all
```

The last command ensures all the modified files are added to the current commit. Be careful here if you want to only commit build files. You might instead specify `git add path/to/build/dir/*`.

#### Collaborating

Git hooks are not pushed remotely. You will have to manually share these hooks if you want other members of your team to use them.


[1]: http://git-scm.com/book/en/Customizing-Git-Git-Hooks
[2]: http://oli.jp/2011/github-pages-workflow/
