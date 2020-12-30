
# лекция 5: дз

bastion_IP = 130.193.51.231

someinternalhost_IP = 10.130.0.35



> Задача: Подключение workstation > bastion > someinternalhost в одну команду, через ssh-агента:

`ssh -i ~/.ssh/appuser -A appuser@${bastion_IP} -t 'ssh appuser@${someinternalhost_IP}'`

> Задача: Подключение в одну команду, через bastion в качестве Jump Host:

`ssh -i ~/.ssh/appuser -J appuser@${bastion_IP} appuser@${someinternalhost_IP}`

> Задача: Подключение через ssh-агент с созданием алиаса в ~/.ssh/config: 

```
Host someinternalhost
    Hostname @${bastion_IP}
    Port 22
    User appuser
    IdentityFile ~/.ssh/appuser.pub
    RequestTTY force
    ForwardAgent yes
    RemoteCommand ssh appuser@${someinternalhost_IP}
```
 - (недостаток: невозможность выполнения неинтерактивно, e.g. "ssh someinternalhost whoami")

> Через JumpHost с созданием алиаса в ~/.ssh/config:
```
Host someinternalhost
    HostName ${someinternalhost_IP}
    ProxyJump appuser@${bastion_IP}
    RequestTTY force
    Port 22
    User appuser
    IdentityFile ~/.ssh/appuser.pub
```

> Задача: VPN сервер на bastion

>> Проблема: отсутствие подключения

В логах VPN сервера на bastion обнаружено: <br>
`[restless-waterfall-2417][2020-12-29 11:33:31,012][ERROR] Failed to insert iptables rule, retrying...` <br>
 - лечим на лету, а так же на будущее добавлением команды в setupvpn.sh <br>
`sudo apt-get install -y iptables`

 - после этого, vpn начинает работать сразу, перезагрузок ч.-л. не требуется.

>> Проблема: самоподписанный сертификат

```
[and@ryzhkov ~]$ dig +short ${bastion_IP}.sslip.io
130.193.51.231
```

идем на vpn на bastion через браузер `https://${bastion_IP}.sslip.io` <br>
Settings >> Lets Encrypt Domain = ${bastion_IP}.sslip.io


