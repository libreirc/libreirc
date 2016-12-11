Why OpenIRC?
========

## A. 개요
IRC는 정말 재미난 대화수단이지만, 처음보는사람이 사용하는데에는 상당한 진입장벽이 있습니다. 일반적인 IRC 클라이언트를 사용하면 창을 끈동안 접속이 끊기고, 그렇다고 리눅스 서버에 tmux/screen과 weechat/irssi를 써서 24시간 켜져있는 IRC 클라이언트를 세팅하자니 관련 지식이 없는 사람들에겐 너무 힘들기 때문입니다.

전 예전부터 이 문제를 해결하고싶었고, 아마 IRC를 쓰시는 대부분의 분들이 그러하셨을 것입니다. 그래서 저는, OpenIRC 프로젝트를 시작하기로 결심했습니다.

## B. 문제 정의
![weechat]

현재 리눅스 서버와 tmux/screen, 그리고 weechat/irssi를 사용한 IRC 환경에는 아래와 같은 문제가 있습니다.

1. 쓸 수 있는 리눅스 서버가 있어야합니다.
1. 리눅스를 쓸 줄 알아야 하고, putty와 screen/tmux와 같은 커맨드라인 도구의 사용에 익숙해야합니다.
1. 멘션이나 노티가 와도, 푸시알림을 받을 수 없습니다.
1. 모바일의경우, 사용하는 ssh 클라이언트와 키보드에 따라 한글입력이 안됩니다.
1. 안드로이드 유저의경우, Weechat Relay를 쓰면 3-4번 문제를 해결할 수 있지만, 세팅이 어렵습니다.
1. 기본설정에서 실수로 weechat/irssi를 꺼버리면, 채널목록이 모두 없어져서 손으로 복구해줘야합니다.

이런 불편함이 있습니다.

## C. 사전조사
그래서 여러가지 솔루션들을 고민했었습니다. 주로 기존에 있던 소프트웨어들을 활용하려고 했습니다. 요구사항은 아래와 같았습니다.

1. **IRC나 리눅스를 전혀 모르는사람도 바로 사용가능할것** (가장 중요한 기준)
2. 내가 화면을 꺼도 IRC 연결이 24시간 유지될것
3. 현재 모바일지원이 없더라도, 차후에 모바일 지원이 가능하도록 확장 가능한 구조일것

그래서 인터넷으로 각종 IRC 클라이언트들을 하나하나 시도해봤습니다.

### 1. Glowing Bear, Weechat Android
<img height=240 src="https://openirc.github.io/img/glowing-bear.png">
<img height=240 src="https://openirc.github.io/img/weechat-android.png">

개인적으로 쓰기에 굉장히 좋았지만 치명적인 단점이 있었습니다.

1. 개인 리눅스서버에 tmux/weechat 세팅해놔야 저걸 쓸 수 있음
2. weechat 세팅이 다 되어있어도 저거에 연결시키는 과정이 어려움

결국 저건 "IRC를 핸드폰으로 하면 굉장히 편하구나!" 라는 PoC 용도로만 쓸 수 있었고, 선택지로 쓸수는 없었습니다.

### 2. Mibbit, Kiwi IRC, mIRC, HexChat, ...
<img height=240 src="https://openirc.github.io/img/mibbit.png">
<img height=240 src="https://openirc.github.io/img/kiwi.png">

이 소프트웨어들이 세팅 없이 당장 접속하기에는 제일 좋았습니다. 그러나

1. 커넥션 유지 불가능
2. 여러 클라이언트로 한 유저에 로그인 가능한 구조가 아님

결국 저 소프트웨어들은 IRC UX에 참고하는 용도로만 쓰게되었습니다.

### 3. Shout IRC, The Lounge
![lounge]

개인서버가 있는 사람들이 쓰기에는 제일 좋아보였지만, 이런 문제가 있었습니다.

1. 개인 리눅스서버가 하나 있어야함.
2. 개인 리눅스 서버에 nodejs 설치한뒤, npm으로 직접 설치해야함.
3. 회원가입 기능이 없음. 고정된 숫자의 계정들만 들락날락할수있음
3. 이를 고치려고 해도, 기존 코드가 개인사용에 완전 포커스 맞춰서 만들어진거라 수정이 용이한 구조가 아님.
4. 현재 웹클라만 있는 상황인데, 프로토콜이 문서화되어있지 않아 모바일에서는 웹브라우저로 써야하고 알림 못받음

### 4. IRCtalk
![irctalk]

한국 개발자들이 예전에 개발했던, OpenIRC와 굉장히 유사한 프로젝트입니다. 아마 만들게되신 동기는 저와 똑같았을거라고 봅니다. 그러나

1. 공식 출시하기 전에 베타상태로 개발이 멈춰서, 개인적으로 요청하는게 아니면 앱을 받을수 없음
2. 옵을 주지 못하는 식으로 몇몇 기능이 없음
3. 부족한 기능을 고치고싶어도 클로즈드소스라 기여할수가 없음

### 5. IRCCloud
![irccloud]

제일 훌륭합니다. 웹클라/모바일클라 둘다 있고, 둘다 푸시노티 받을 수 있고 제일 편합니다. 그러나

1. **연 7만원** (IRC가 뭔지도 모르는 사람들이 사람들이랑 이야기하려고 이 돈을 낼것같진 않다..)
2. 클로즈드소스

유료라는점때문에 이걸 널리 쓰기는 힘들어보였지만, "IRCCloud랑 똑같이 만들면 되겠다" 이런 기준점으로 삼을수는 있었습니다.

## D. 해결책
그래서 결국 새로 만들기로했습니다. 당분간은 전체 기능 구현보단 MVP 만드는데에 주력할 생각이고, 당분간의 목표는 아래의 목표를 만족하는 물건을 만드는걸로 하기로했습니다

1. **IRC나 리눅스를 전혀 모르는사람도 바로 사용가능할것** (가장 중요한 기준)
2. 내가 화면을 꺼도 IRC 연결이 24시간 유지될것
3. 메시징 프로토콜이 HTTP agnostic할것 (나중에 모바일로 확장할 수 있어야해서..)

메세지브로커나 DB와 같이 기존에 이미 있는 솔루션을 최대한 활용하기로 했습니다. 현재 생각중인 대략적인 구조는 아래와 같습니다.

<p align=center><img src="https://openirc.github.io/img/openirc-bigpicture.png"></p>

좀더 세부적인 설명은 OpenIRC [프로젝트 구조][project-arch] 문서를 참고해주세요.

## E. 현재상태
**프론트엔드** - 아직 디자인이 입혀지지 않아 보기는 싫지만, 쓸 수 있는 웹
프론트엔드가 만들어져있는 상황입니다. Elm으로 개발하였는데, 기대했던대로
개발속도가 상당히 빨라 웹 UI는 별로 걱정하지 않고있습니다

**메세지브로커** - 현재 [Elm용 MQTT 라이브러리][elm-mqtt] 개발 진행중입니다.

**MQTT-IRC 게이트웨이** - 아직 이부분은 개발을 시작하지 않았습니다.

[weechat]:        https://openirc.github.io/img/weechat.png
[lounge]:         https://openirc.github.io/img/lounge.png
[irctalk]:        https://openirc.github.io/img/irctalk.png
[irccloud]:       https://openirc.github.io/img/irccloud.png
[project-arch]:   project-structure.md
[elm-mqtt]:       https://github.com/simnalamburt/elm-mqtt
