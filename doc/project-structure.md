Project structure
========
<p align=right>
  <strong>English</strong> |
  <a href=project-structure.kr.md>한국어</a>
</p>

> **Disclaimer** : All of the design decisions below are based on the current situation(November 2016).

[Client side codes](../client/)
--------
[elm] is used for web client-side code. Other tools being used are:

- [yarn] & [elm-package] : Dependency Installation
- [stylus] : CSS Preprocessor
- [webpack] : Module Bundling & Packaging

The client-side code is directly built into and served from the `server` directory.

```bash
▾ client/
  ▾ src/                # Client-side codes (elm, stylus, ...)
      main.js           # Entry point for webpack
      ...
    package.json        # Libraries from "npm", build dependencies
    elm-package.json    # Libraries from "package.elm-lang.org"

    webpack.config.js
    ...
```

As for now, [elm] shows the [best][blazing-fast-1] [performance][blazing-fast-2] as a tool for SPA. Also, the strong
type system of the language makes it suitable for the fast development by a small team, which can't afford a lot of
man-hour(!["production" icon from Civilization V](img/production.png)) being spent on debugging.

[yarn] is a package manager which is better than [npm] in almost every way. Above all, it supports the concept of
[lock file], so we can avoid a build failure caused by other library author's mistake.

[webpack] does require fairly complex configuration, but still it's the best one among the front-end code build
solutions for now. It supports bundling, compression, and [loader] and [plugin] system. Also, upcoming [webpack 2]
provides even more powerful features such as tree-shaking. OpenIRC will probably stick with webpack unless very
compelling alternative shows up.

[stylus] is chosen because it is the most familiar CSS preprocessor for OpenIRC developers. Nevertheless, if someone
wants to contribute in desing-wise and favor othe CSS preprocessor over stylus, we are more than willing to change it.
For now, there aren't much stylus code as our current goal is to make a working MVP.

[elm]: http://elm-lang.org/
[yarn]: https://yarnpkg.com/
[elm-package]: https://github.com/elm-lang/elm-package
[webpack]: https://webpack.github.io/
[stylus]: http://stylus-lang.com/
[blazing-fast-1]: http://elm-lang.org/blog/blazing-fast-html
[blazing-fast-2]: http://elm-lang.org/blog/blazing-fast-html-round-two
[npm]: https://github.com/npm/npm
[lock file]: https://yarnpkg.com/en/docs/yarn-lock
[webpack 2]: https://webpack.js.org/
[loader]: https://webpack.github.io/docs/using-loaders.html
[plugin]: https://webpack.github.io/docs/plugins.html

[Server side codes](../server/)
--------
[python] 3.5 is used for server-side development. On top of that, we used [sanic] as a web framework, and [perl] and
[`venv`] module (which is embedded in the language) for the initialization script for the python dev envirionment.

```bash
▾ server/
  ▾ public/             # Files that will be statically served
    ▸ build/            # Build results of web-client
      index.html
  ▸ src/                # Server-side codes (python)
    requirements.txt    # Server-side dependencies
    install             # Development environment initialization script
    run                 # Execution script
    ...
```

[sanic] is chosen because of [`async`/`await` syntax (PEP 492)][pep492] support. Though there aren't much of
`async`/`await` usage in server-side code yet, we certainly need it for actual communication with MQTT, which requires
the handling of a huge amount of requests. We don't need our web framework to be feature-rich, so it is reasonable to
stick with sanic, which shows the best performance than others.

Most of our scripts regarding server-development are written in [perl]. The reason behind that is, perl is easier to use
compared to shell script, and it's also available from almost all environment. Unless the script logic gets too complex,
we will stick to the choice.

[`venv`] embedded in [python] is used instead of [Virtualenv] because OpenIRC forces developers to use Python 3.5+
anyway. In that case, using [Virtualenv] only introduces unnecessary, additional setup for developers.

[python]: https://www.python.org/
[sanic]: https://github.com/channelcat/sanic
[perl]: https://www.perl.org/
[`venv`]: https://docs.python.org/3/library/venv.html
[pep492]: https://www.python.org/dev/peps/pep-0492/
[Virtualenv]: https://virtualenv.pypa.io/en/stable/
