Project structure
========

[Client side codes](../client/)
--------
웹 클라이언트단 코드는 [elm]을 써서 개발되었습니다. 디펜던시 설치에는 [yarn]과
[elm-package]가 사용되며, 현재 [웹팩]을 써서 패키징하고있습니다. CSS
프리프로세서로는 [stylus]를 쓰고있습니다.

현재는 프로젝트를 빌드하면, 빌드 결과물이 서버로 들어가 서빙되는 방식을
쓰고있습니다.

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

[elm]은 2016년 11월 기준, SPA 어플리케이션 개발에 쓸 수 있는 프레임워크중 가장
성능이 우수하며, 강타입시스템을 장착하고있기때문에 디버깅에 쓸 맨아워(![문명 5의
"production" 아이콘](img/production.png))가 많지 않은 소규모 팀의 빠른 개발에
적합합니다.

[yarn]은 거의 모든면에서 [npm]보다 우수한 패키지매니저입니다. 무엇보다, [락파일]
개념을 지원하기때문에, 다른 라이브러리 제작자의 실수로 OpenIRC 빌드가 깨져서
개발이 중단되는 일을 막을 수 있습니다.

[웹팩]은 설정이 상당히 복잡하지만, OpenIRC 프로젝트가 시작된 2016년 11월
기준으로, 프론트엔드 코드 빌드에 쓸 수 있는 솔루션들 가운데에 제일 나은
선택지였습니다. 파일을 하나로 합치거나 압축하는것은 물론이고, 강력한
[로더]기능과 [플러그인] 시스템 등, 개발 당시 고를 수 있는 선택지중에선 가장 나은
선택지였고, 출시가 임박한 [웹팩 2]는 트리셰이킹을 비롯해 더 강력한 기능을
갖고있습니다. 강력한 경쟁자가 등장하지 않는다면, OpenIRC 프로젝트는 앞으로도
웹팩을 사용할것으로 보입니다.

[stylus]는 OpenIRC 개발자들에게 가장 익숙한 툴이기 때문에 선택하였지만, 현재
작동하는 MVP를 만드는것이 목적이기때문에 [stylus]코드가 그리 많지는 않습니다.
디자인 기여를 하고싶으신분이 [stylus]가 아닌 다른 언어가 익숙하다면, 바꿀 의향이
있습니다.

[elm]: http://elm-lang.org/
[yarn]: https://yarnpkg.com/
[웹팩]: https://webpack.github.io/
[stylus]: http://stylus-lang.com/
[npm]: https://github.com/npm/npm
[elm-package]: https://github.com/elm-lang/elm-package
[락파일]: https://yarnpkg.com/en/docs/yarn-lock
[로더]: https://webpack.github.io/docs/using-loaders.html
[플러그인]: https://webpack.github.io/docs/plugins.html
[웹팩 2]: https://webpack.js.org/

[Server side codes](../server/)
--------
서버단 코드는 [파이썬] 3.5를 사용하여 개발하였습니다. 웹프레임워크로는 [sanic]을
쓰고있고, 파이썬 개발환경 초기화 스크립트들은 [perl]과 파이썬 내장 [`venv`] 모듈
을 사용하였습니다.

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

[sanic]은 [`async`/`await`문법 (PEP 492)][pep492] 지원때문에 선택하였습니다.
아직 서버단 코드에는 [`async`/`await`][pep492] 코드가 많지 않지만, MQTT와
통신하는 기능이 들어가기 시작하면 많은 수의 리퀘스트를 처리하기위해선 꼭
필요합니다. 2016년 11월 기준으로 [sanic]자체의 성능이 다른 프레임워크들보다
우수한것도 있고, OpenIRC 프로젝트 구조상 웹프레임워크에 많은 기능을 필요로하지
않기 때문에 [sanic]을 선택하였습니다.

현재 대부분의 서버개발관련 스크립트들은 [perl]로 짜여져있고, 앞으로도 로직이
심각하게 복잡해지지 않는다면 [perl]로 짤 예정입니다. 쉘스크립트를 대체하기에
좋고, 거의 모든 개발환경에는 [perl]이 이미 탑재되어있기 때문입니다.

[Virtualenv]대신 [파이썬] 내장 [`venv`] 모듈을 사용하는 이유는, 어차피 OpenIRC
프로젝트는 파이썬 3.5 이상의 버전을 강제할 예정이고, [Virtualenv]를 쓰면
개발자에게 추가적인 세팅을 요구하기 때문입니다.

[파이썬]: https://www.python.org/
[sanic]: https://github.com/channelcat/sanic
[perl]: https://www.perl.org/
[`venv`]: https://docs.python.org/3/library/venv.html
[pep492]: https://www.python.org/dev/peps/pep-0492/
[Virtualenv]: https://virtualenv.pypa.io/en/stable/
