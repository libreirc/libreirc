Setting up your own RabbitMQ cluster
========
> **NOTE**: This document is not translated into English yet. Please contribute!

작은 OpenIRC 서버에서는 [mosquitto]나 [mosca]와 같은 메세지브로커를 사용하는것이
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
RabbitMQ 3.6.1 이상을 써야한다. OpenIRC 프로젝트는 웹소켓을 지원하는 MQTT
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

II. 설정
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

### 2. 프로세스의 Open File Limit 늘리기
대부분의 리눅스 배포판들은 1024를 프로세스의 기본 Open File Limit으로
쓰고있는데, 이 값은 RabbitMQ에겐 너무 작다. 아래의 커맨드로 RabbitMQ의 현재 Max
fd값을 확인할 수 있다.

```bash
cat /proc/$(pgrep rabbitmq)/limits | grep open
# 1024
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

<br>

**쓰는중**
