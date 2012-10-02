Title: How to Write Portable Node.js Code
Author: Domenic Denicola
Date: 2012-10-02T18:00:00Z
Node: v0.8.11

Node.js core does its best to treat every platform equally. Even if most Node developers use OS X day to day, some use
Windows, and most everyone deploys to Linux or Solaris. So it's important to keep your code portable between platforms,
whether you're writing a library or an application.

Predictably, most cross-platform issues come from Windows. Things just work differently there! But if you're careful,
and follow some simple best practices, your code can run just as well on Windows systems.

## Paths and URLs

On Windows, paths are constructed with backslashes instead of forward slashes. So if you do your directory manipulation
by splitting on `"/"` and playing with the resulting array, [your code will fail dramatically on Windows][codex].

Instead, you should be using the [path module][path]. So instead of resolving paths with string contatenation, e.g.
`x + "/" + y`, you should instead do `path.resolve(x, y)`. Similarly, instead of relativizing paths with string
replacement, e.g. `x.replace(/^parent\/dirs\//, "")`, you [should][wrench] do `path.relative("/parent/dirs", y)`.

Another area of concern is that, when writing portable code, you cannot count on URLs and module IDs having the same
separators as paths. If you use something like `path.join` [on a URL][knox], Windows users will get URLs containing
backslashes! [Similarly][npm-www] for `path.normalize`, or in general any path methods. All this applies if you're
[working with module IDs][browserify], too: they are forward-slash delimited, so you shouldn't use path functions with
them either.


[codex]: https://github.com/logicalparadox/codex/commit/7f91b451e7cdc9d794f30bd026029aea797bb1e0
[path]: http://nodejs.org/docs/latest/api/path.html
[wrench]: https://github.com/ryanmcgrath/wrench-js/commit/01190602dac64924fca2dae11912ffb560e636a0
[knox]: https://github.com/domenic/knox/compare/eabef00df9bf79085229f4ed39b2679eb579ea20...9b1a4e9f644ababd5d9ced227de44709e1fccf4b
[npm-www]: https://github.com/isaacs/npm-www/pull/88
[browserify]: https://github.com/substack/node-browserify/pull/158

## Non-portable APIs

Windows is completely missing the `process.(get|set)(gid|uid)` methods, so calling them will instantly crash your
program on Windows. Always [guard such calls][winston] with a conditional.

The [`fs.watchFile`][watchFile] API is not sufficiently cross-platform, and is recommended against in the docs because
of it. You [should][codex-watch] use [`fs.watch`][watch] instead.

The [child_process module][] requires care cross-platform. In particular, `spawn` and `execFile` do not execute in a
shell, which means that on Windows only `.exe` files will run. This is rather problematic, as many cross-platform
binaries are included on Windows as `.cmd` or `.bat` files, [among them Git][npm-git], [CouchDB][npm-www-couchdb], and
many others. So if you're using these APIs, things will likely work great on OS X, Linux, etc. But when you tell your
users “just install the Git build for Windows, and make sure it's in your path!” that ends up not being sufficient.
There is [talk][node-bug] of fixing this behavior in libuv, but that's still tentative. In the meantime, if you don't
need to stream your output, `exec` works well. Otherwise you'll need [branching logic][npm-www-couchdb] to take care
of Windows.

A final edge-case comes when using named sockets, e.g. with `net.connect`. On Unix, simple filenames suffice, but on
Windows, they must conform to a [bizarre syntax][pipe-names]. There's not really a better solution for this than
[branching per-platform][cleanPipeName].


[winston]: https://github.com/flatiron/winston/commit/a32d92ba1be3c21859d8c1c9e8e0e701846fcaf4
[watchFile]: http://nodejs.org/docs/latest/api/fs.html#fs_fs_watchfile_filename_options_listener
[codex-watch]: https://github.com/logicalparadox/codex/commit/be2fe18f5561f7bbd3bd0099bb47f7e58c23638d
[watch]: http://nodejs.org/docs/latest/api/fs.html#fs_fs_watch_filename_options_listener
[child_process module]: http://nodejs.org/api/child_process.html
[npm-git]: https://github.com/isaacs/npm/issues/2333
[npm-www-couchdb]: https://github.com/isaacs/npm-www/blob/fd3a96e861989338676937736599598f7c0fde8f/dev/go.js#L22-27
[node-bug]: https://github.com/joyent/node/issues/2318
[pipe-names]: http://msdn.microsoft.com/en-us/library/windows/desktop/aa365783%28v=vs.85%29.aspx
[cleanPipeName]: https://gist.github.com/2790533#gistcomment-331356

## Being Windows-Developer Friendly

One of the most egregious problems with many projects is their unnecessary use of Unix Makefiles. Windows does not have a
`make` command, so the tasks stored in these files are entirely inaccessible to Windows users who might try to
contribute to your project. This is especially egregious if you put your test command in there!

Fortunately, we have a solution: npm comes with a [scripts feature][npm-scripts] where you can include commands to be
run for testing (`test`), installation (`install`), building (`prepublish`), and starting your app (`start`), among many
others. You can also create custom scripts, which are then run with `npm run <script-name>`; I often use this for
[lint steps][linting]. Also of note, you can reference any commands your app depends on by their short names here: for
example, `"mocha"` instead of `"./node_modules/.bin/mocha"`. So, please use these! If you must have a Makefile for
whatever reason, just have it [delegate to an npm script][knox-test].

Another crucially important step is not using Unix shell scripts as part of your development process. Windows doesn't
have bash, or `ls`, or `mv`, or any of those other commands you might use. Instead, write your shell scripts
[in JavaScript][shell-scripts], using a tool like [Grunt][] if you'd like.


[npm-scripts]: https://npmjs.org/doc/scripts.html
[linting]: https://github.com/domenic/sinon-chai/blob/baf878ee7ba98bae507ac8bc91c94ea1fe287964/package.json#L28
[knox-test]: https://github.com/LearnBoost/knox/blob/c1b680c80b7a4493970e3e9a92305387ef96c1eb/Makefile#L2-3
[shell-scripts]: http://www.2ality.com/2011/12/nodejs-shell-scripting.html
[Grunt]: http://gruntjs.com/

## Bonus: Something that Breaks on Linux and Solaris!

Both Windows and, by default, OS X, use case-insensitive file systems. That means if you install a package named foo,
any of `require("foo")` or `require("FOO")` or `require("fOo")` will work—on Windows and OS X. But then when you go to
deploy your code, out of your development environment and into your Linux or Solaris production system, the latter two
will *not* work! So it's a little thing, but make sure you always get your module and package name casing right.

## Conclusion

As you can see, writing cross-platform code is sometimes painful. Usually, it's just a matter of best practices, like
using the path module or remembering that URLs are different from filesystem paths. But sometimes there are APIs that
just don't work cross-platform, or have annoying quirks that necessitate branching code.

Nevertheless, it's worth it. Node.js is the most exciting software development platform in recent memory, and one of its
greatest strengths is its portable nature. Try your best to uphold that!
