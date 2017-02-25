_**NOTE!** 아직 RabbitMQ를 LibreIRC용 메세지 브로커로 써서는 안됩니다! 현재의
RabbitMQ는 LibreIRC 서비스에 필수적인 보안기능들이 아직 구현되어있지 않습니다._

###### References
- https://github.com/rabbitmq/rabbitmq-server/issues/505
- https://github.com/rabbitmq/rabbitmq-mqtt/issues/95
- https://antoine-galataud.github.io/messaging/rabbitmq/mqtt/stomp/authorization/2015/10/15/rabbit-topic-auth.html

<br>

<br>

Setting up your own RabbitMQ cluster
========
작은 LibreIRC 서버에서는 [mosquitto]나 [mosca]와 같은 메세지브로커를 사용하는것이
편리하지만, 유저 수가 많아질경우 이 솔루션들은 수평확장이 힘들다. 이때
RabbitMQ의 클러스터 기능을 쓰면, [SPOF]없이 아주 편리하게 고가용성을 유지한채로
수평확장을 할 수 있다.

###### References:
- [RabbitMQ Hits One Million Messages Per Second on Google Compute Engine][ref1]
- [How does the MQTT (mosquitto) work with multiple brokers?][ref2]

[RabbitMQ]: https://www.rabbitmq.com/
[mosquitto]: https://mosquitto.org/
[mosca]: http://www.mosca.io/
[SPOF]: https://en.wikipedia.org/wiki/Single_point_of_failure
[ref1]: https://blog.pivotal.io/pivotal/products/rabbitmq-hits-one-million-messages-per-second-on-google-compute-engine
[ref2]: https://www.quora.com/How-does-the-MQTT-mosquitto-work-with-multiple-brokers/answer/Dominik-Obermaier

<br>

I. 설치
--------
RabbitMQ 3.6.1 이상을 써야한다. LibreIRC 프로젝트는 웹소켓을 지원하는 MQTT
브로커를 필요로하는데, [rabbitmq-web-mqtt] 플러그인이 RabbitMQ 3.6.1 이상 버전을
필요로 하기때문이다.

### OS X
```bash
brew install rabbitmq
```
[`brew`] 없이 설치하는 법에 대해선 [공식문서][doc-osx] 참고

### Arch Linux
```bash
# Install rabbitmq
sudo pacman -S rabbitmq

# Enable & run it
sudo systemctl enable rabbitmq
sudo systemctl start rabbitmq

# "root" 유저가 RabbitMQ에 액세스 권한을 갖도록 설정
sudo cp /var/lib/rabbitmq/.erlang.cookie /root/.erlang.cookie
```
설치 직후에 서비스등록이 되어있지 않고, 자동으로 켜지지도 않기때문에 수동으로
서비스에 등록하고 실행시켜줘야한다. `.erlang.cookie`에 관해선, 이후에 나온다.

### Ubuntu 17.04+
```bash
sudo apt install rabbitmq-server
```

### Ubuntu 14.04 LTS, 16.10 LTS
우분투 기본 리포지터리에서 제공하는 [`rabbitmq-server`] 패키지의 버전이
낮기때문에, PPA를 써야한다. RabbitMQ 팀이 [PackageCloud] 리포지터리를 공식적으로
관리하므로, 이를 사용하는것이 제일 간편하다.

```bash
curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.deb.sh |
        sudo bash
```

PackageCloud가 아닌 rabbitmq.com APT 리포지터리를 쓰고싶거나, [Chef]나
[Puppet]을 써서 인프라를 관리한다면, 아래의 문서들을 참고하라.

- https://www.rabbitmq.com/install-debian.html#apt
- https://packagecloud.io/rabbitmq/rabbitmq-server/install#chef

### Ubuntu 12.04 LTS
자세한 내용은 [공식문서][doc-12] 참고

```bash
# Add Debian Wheezy backports repository to obtain init-system-helpers
gpg --keyserver pgpkeys.mit.edu --recv-key 7638D0442B90D010
gpg -a --export 7638D0442B90D010 | sudo apt-key add -
echo 'deb http://ftp.debian.org/debian wheezy-backports main' | sudo tee /etc/apt/sources.list.d/wheezy_backports.list

# Add Erlang Solutions repository to obtain esl-erlang
wget -O- https://packages.erlang-solutions.com/debian/erlang_solutions.asc | sudo apt-key add -
echo 'deb https://packages.erlang-solutions.com/debian wheezy contrib' | sudo tee /etc/apt/sources.list.d/esl.list

sudo apt-get update
sudo apt-get install init-system-helpers socat esl-erlang

# continue with RabbitMQ installation as explained above
wget -O- https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | sudo apt-key add -
echo 'deb http://www.rabbitmq.com/debian/ testing main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list

sudo apt-get update
sudo apt-get install rabbitmq-server
```

### RPM-based Linux (RHEL, CentOS, Fedora, openSUSE)
RabbitMQ 팀이 [PackageCloud] 리포지터리를 공식적으로 관리하므로, 이를 사용하는것이 제일 간편하다.
```bash
curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh |
        sudo bash
```

이외의 방법들에 대해선, [공식문서][doc-rpm] 참고

### 그 외 기타 OS
아래의 공식문서 참고

- [Install: Windows](https://www.rabbitmq.com/install-windows.html)
- [Install: Windows (manual)](https://www.rabbitmq.com/install-windows-manual.html)
- [Install: Generix Unix](https://www.rabbitmq.com/install-generic-unix.html)
- [Install: Solaris](https://www.rabbitmq.com/install-solaris.html)

###### References
- https://www.rabbitmq.com/download.html

[rabbitmq-web-mqtt]: https://github.com/rabbitmq/rabbitmq-web-mqtt
[`rabbitmq-server`]: https://launchpad.net/ubuntu/+source/rabbitmq-server
[`brew`]: http://brew.sh/
[PackageCloud]: https://packagecloud.io/rabbitmq/rabbitmq-server
[수동설치]: https://packagecloud.io/rabbitmq/rabbitmq-server/install#manual
[Chef]: https://www.chef.io/chef/
[Puppet]: https://puppet.com/
[doc-osx]: https://www.rabbitmq.com/install-standalone-mac.html
[doc-12]: https://www.rabbitmq.com/install-debian.html#ubuntu-12.04
[doc-rpm]: https://www.rabbitmq.com/install-rpm.html

<br>

II. 머신 설정
--------
**NOTE**: 이하의 설명들은 Arch Linux와 Ubuntu 16.04 LTS를 기준으로 작성되었다.

### 1. `fs.file-max` 높이기
이 값은 리눅스 커널이 허용하는 최대 파일 갯수이다. 대부분의 경우, 고칠필요 없다.
아래의 커맨드로 이 값을 확인할 수 있다.

```bash
sysctl fs.file-max
# fs.file-max = 332536
```

이 값이 작을경우, `sysctl` 설정을 아래와 같이 추가해야 한다. `/etc/sysctl.conf`
파일을 만들거나, `/etc/sysctl.d/` 디렉토리 안에 설정파일을 추가하면 된다.

```bash
# ...

# Increase kernel open file limit
fs.file-max = 1620401
```

###### References
- [sysctl.conf (5)](http://man7.org/linux/man-pages/man5/sysctl.conf.5.html)
- https://www.rabbitmq.com/install-generic-unix.html#max-open-files-limit

### 2. 프로세스의 Open File Limit 늘리기
대부분의 리눅스 배포판들은 1024를 프로세스의 기본 Open File Limit으로
쓰고있는데, 이 값은 RabbitMQ에겐 너무 작다. 아래의 커맨드로 RabbitMQ의 현재 Max
fd값을 확인할 수 있다.

```bash
cat /proc/$(pgrep rabbitmq)/limits | grep open
# 1024

sudo rabbitmqctl status | grep file_desc
# {file_descriptors,[{total_limit,924},

# 위의 924라는 숫자는 항상 프로세스의 제한인 1024보다 100 작은 값으로 표시된다.
```

이 값은 아래와 같이 늘릴 수 있다.

```bash
# Ubuntu 16.04 LTS
sudo mkdir -p /etc/systemd/system/rabbitmq-server.service.d/
cat | sudo tee /etc/systemd/system/rabbitmq-server.service.d/limits.conf <<END
[Service]
LimitNOFILE=300000
END

sudo systemctl restart rabbitmq-server
```
```bash
# Arch Linux
sudo mkdir -p /etc/systemd/system/rabbitmq.service.d/
cat | sudo tee /etc/systemd/system/rabbitmq.service.d/limits.conf <<END
[Service]
LimitNOFILE=300000
END

sudo systemctl restart rabbitmq
```

###### References
- https://www.rabbitmq.com/install-debian.html#linux-max-open-files-limit-options-debian

<br>

III. 클러스터 형성
--------
> **NOTE**: 노드가 하나뿐이라면 본 대단원을 스킵해도 좋다.

위 절차들을 통해 클러스터를 구성할 각각의 노드 세팅을 마쳤다면, 이제 노드들을
하나로 묶어줘야한다.

### 1. Erlang Cookie 맞추기
*Erlang Cookie*는 RabbitMQ 클러스터의 노드들이, 서로를 인증하기위해 사용하는
BASE64 문자열이다. 두 RabbitMQ 노드의 얼랭 쿠키가 같으면 인증에 성공하고, 다르면
인증에 실패한다.

한가지 알아야하는점은, 같은 머신 안에서도 사용자별로/프로세스별로 독립적인 얼랭
쿠키를 갖고있다는 점이다. 아래와 같이 여러개 있을 수 있다.

- RabbitMQ 프로세스의 얼랭 쿠키 : `/var/lib/rabbitmq/.erlang.cookie`
- 루트 계정의 얼랭 쿠키         : `/root/.erlang.cookie`
- 일반 계정들의 얼랭 쿠키         : `~/.erlang.cookie`

RabbitMQ 프로세스의 얼랭 쿠키가 기준이므로, 여러 머신들의
`/var/lib/rabbitmq/.erlang.cookie` 쿠키를 직접 **똑같이** 맞춰줘야한다. 저
파일을 텍스트에디터로 고칠경우 newline이 멋대로 삽입되어 에러가 발생할 수
있으므로, 아래와 같이 해야한다.

```bash
echo $(sudo cat /var/lib/rabbitmq/.erlang.cookie)
# ABCDEFGHIJKLMNOPQRST

echo "ABCDEFGHIJKLMNOPQRST" | sudo tee /var/lib/rabbitmq/.erlang.cookie
echo "ABCDEFGHIJKLMNOPQRST" | sudo tee /root/.erlang.cookie
```

이때 루트계정의 얼랭 쿠키도 같이 맞춰주지 않으면 커맨드 라인에서 `sudo
rabbitmqctl` 커맨드를 전혀 쓸 수 없게되므로, 머신별로 두쌍의 얼랭 쿠키를
바꿔줘야한다.

###### Reference
- https://www.rabbitmq.com/clustering.html#erlang-cookie

### 2. 노드들 연결하기
`rabbitmqctl`의 `join_cluster` 명령어를 이용해 노드들을 하나로 연결해주면 된다.
중심으로 사용할 노드를 하나 정해서 해당 노드의 IP주소 혹은 hostname을 알아낸 뒤,
나머지 모든 노드들에서 해당 노드로 `join_cluster` 명령어를 실행시켜주자.

노드들끼리 하나의 LAN 안에 묶여있을경우, 가능한한 지역 IP를 사용하는것이 라우팅
오버헤드를 줄여준다. AWS와 같은 VPS들에선, 한 VPC 서브넷 안의 서버들은 머신들의
hostname이 저장되어있는 지역 DNS가 있어서 머신들의 hostname을 지역 IP 대신 바로
사용할수도 있기때문에, IP주소가 변해도 연결을 다시 맺어줄필요가 없다.

```bash
# 중심 노드 IP 혹은 hostname 알아내기

ip -4 a | grep -oP '(?<=inet\s)(?!127\.0\.0\.1/8)\d+(?:\.\d+){3}'
# 172.13.3.128

ip -6 addr | grep -P '(?<=inet6\s)(?!::1/128)[\da-f:]+'
# fe80::42:daff:fe39:5729

hostname
# ip-172-31-3-128
```
```bash
# 나머지 모든 노드들에서, 중심노드로 연결
sudo rabbitmqctl stop_app
sudo rabbitmqctl join_cluster rabbit@ip-172-31-3-128
sudo rabbitmqctl start_app

# 클러스터 현황 보기
sudo rabbitmqctl cluster_status
```

`cluster_status` 명령어를 이용해, 노드를 추가할때마다 클러스터가 커지는것을 알
수 있다.

###### References
- https://www.rabbitmq.com/clustering.html#creating
- https://www.rabbitmq.com/man/rabbitmqctl.1.man.html#Options

<br>

IV. 후속 세팅
--------
### 1. 관리자 콘솔 플러그인 켜기
RabbitMQ는 웹브라우저용 관리자 콘솔을 제공한다. 관리자 콘솔을 쓰면 유저 추가
삭제나 권한관리 등 설정을 편하게 검토하고, 변경시킬 수 있다. 그러나 CLI에
설치되는 `rabbitmqctl`로도 관리자 콘솔로 할 수 있는 모든 일을 동일하게 할 수
있으니, 필요하지 않으면 이 섹션을 스킵해도 된다.

클러스터의 노드들가운데에서, 관리용으로 쓸 노드를 하나 정하자. 해당 관리용
노드에는 `rabbitmq-management` 플러그인을 켜주고, 관리용 노드를 제외한 나머지
모든 노드들에선 `rabbitmq-management-agent` 플러그인을 켜줘야한다. 아래와 같이
하면 된다.

```bash
# 관리용 노드
sudo rabbitmq-plugins enable rabbitmq_management

# 나머지 모든 노드
sudo rabbitmq-plugins enable rabbitmq_management_agent

# See http://IP_ADDRESS:15672
```

이 다음 관리용 노드 IP의 15672번 포트로 접속해보면, 관리자 로그인 페이지가 뜬다.
기본값으로 생성되는 관리자계정은 아래와 같다.

- ID: *guest*
- Password: *guest*

그러나 이 계정은 **localhost에서 접속하는 유저의 로그인만을 허용**하므로,
원격에서 접속해야한다면 새 계정을 만들고 위 계정은 삭제시켜주자. 아래 커맨드는
RabbitMQ 클러스터의 노드중 아무거나 한곳에서만 실행해주면, 자동으로 나머지
노드들에도 반영된다.

```bash
# 한 머신에서만 입력해주면 된다!

# 전체 유저목록 보기
sudo rabbitmqctl list_users

# 게스트유저 삭제
sudo rabbitmqctl delete_user guest

# 새 유저 생성.
sudo sh
rabbitmqctl add_user <ADMIN_ID> <PASSWORD>
history -c 2>/dev/null
exit

# NOTE!! 쉘 히스토리파일에 계정의 비밀번호가 남지않도록
#        "history -c" 명령어를 꼭 실행시켜줘야한다.

# 어드민 권한 부여
sudo rabbitmqctl set_user_tags <ADMIN_ID> administrator
sudo rabbitmqctl set_permissions -p "/" <ADMIN_ID> ".*" ".*" ".*"
```

**중요!!** `rabbitmqctl` 커맨드의 한계로, 비밀번호를 쉘에 입력하는수밖에 없다.
상기한 방법대로 하지 않으면 쉘의 히스토리파일(`.bash_history`)에 비밀번호가
**평문으로 남을 수 있으니** 주의해야한다. 아치리눅스와 OS X와 같은 몇몇
배포판에선 `sh`가 `dash`가 아니라 `bash`와 같이 쉘 히스토리가 남는 쉘로
링크되어있으니, 히스토리 삭제 명령어를 항상 실행시켜주도록 하자.

이와 같은 방식으로 CLI에서 유저를 생성하면, 쉘의 한계로 인해 특정 특수문자는
사용하기 어려울 수 있다. (`!`, `&`, ...) 관리자 콘솔에 접근하면 비밀번호를
수정할 수 있으니, 임시비밀번호로 관리자 콘솔에 로그인 한 다음 관리자콘솔에서
원하는 비밀번호로 바꿔주면 된다.

###### References
- https://www.rabbitmq.com/management.html

### 2. 서비스용 계정, VirtualHost 만들기
위 챕터에서 만든 관리자계정은 반드시 관리용으로만 쓰고 실제 서비스에서 사용해선
안된다. 실제 서비스용 계정은 *낮고 제한된* 권한을 부여해줘야한다.  아래와 같이
관리자계정과는 별도로 새 계정을 만들어주자.

```bash
sudo sh
rabbitmqctl add_user <USER_ID> <PASSWORD>
history -c 2>/dev/null
exit
```

이제 이 유저가 접근할 수 있는 VirtualHost를 지정해줘야한다. VirtualHost는 한
RabbitMQ 서버 안에서, 마치 독립적인 RabbitMQ 서버가 여러개 떠있는것처럼
느껴지도록 독립적인 RabbitMQ 환경을 여러개 만들어주는 기능이다. 기본으로 `/`
라는 이름의 VirtualHost가 생기지만, 서비스 전용으로 사용할 VirtualHost를 새로
하나 만들어주는것이 낫다.

```bash
sudo rabbitmqctl add_vhost <VHOST>

sudo rabbitmqctl set_permissions -p <VHOST> <ADMIN_ID> ".*" ".*" ".*"
sudo rabbitmqctl set_permissions -p <VHOST> <USER_ID> ".*" ".*" ".*"
```

새로 만든 VirtualHost에 서비스용 유저뿐만이 아니라 관리자 유저도 함께
추가해줘야함에 유의하라.

###### References
- https://www.rabbitmq.com/access-control.html

### 3. High Availability 정책 구성
RabbitMQ에서 고가용성을 얻어내는 방법엔 여러가지가 있고, 그중 제일 쉬운 방법은
큐 미러링을 쓰는것이다. 자세한것은 [문서참고](https://www.rabbitmq.com/ha.html)

아래의 커맨드를 이용해 고가용성 정책을 설정할 수 있다. 아래 커맨드에서
`mqtt-ha-policy`는 policy의 이름을 지정하는것인데, 아무 이름으로 해도 상관 없다.

```bash
sudo rabbitmqctl set_policy -p <VHOST> mqtt-ha-policy "^mqtt-subscription-" \
   '{"ha-mode":"exactly","ha-params":2,"ha-sync-mode":"automatic"}'
```

위처럼 CLI로 정책을 추가해줘도 되고, 아래와 같이 관리자콘솔에서도 해줄 수 있다.

![Management Console Screenshot](https://libreirc.github.io/img/ha-policy.png)

###### References
- https://www.rabbitmq.com/ha.html

### 4. `rabbitmq-web-mqtt` 플러그인 설치하기
/usr/lib/rabbitmq/lib/rabbitmq-server-**VERSION**/plugins/ 디렉토리에 플러그인
바이너리를 설치하면 된다. 예를들어 3.6.5 버전이라면, 아래와 같다.

```bash
# 플러그인 설치
sudo wget "https://bintray.com/rabbitmq/community-plugins/download_file?file_path=rabbitmq_web_mqtt-3.6.x-14dae543.ez" \
  -O /usr/lib/rabbitmq/lib/rabbitmq-server-3.6.5/plugins/rabbitmq_web_mqtt-3.6.x-14dae543.ez

# 플러그인 활성화
sudo rabbitmq-plugins enable rabbitmq_web_mqtt
```

위와 같이 하면, 웹소켓 기반 MQTT 프로토콜과 TCP기반 MQTT 프로토콜이 동시에
활성화된다.

###### References
- https://github.com/rabbitmq/rabbitmq-web-mqtt
