
# лекция 6: дз


testapp_IP = 178.154.253.46

testapp_port = 9292


 > создать compute instance с помощью yc

```
yc compute instance create --name reddit-app --hostname reddit-app --memory=512M --core-fraction=5 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --metadata serial-port-enable=1 --ssh-key ~/.ssh/appuser.pub
```

 >> Команды по настройке системы и деплоя приложения заворачиваем в bash скрипты

 - install_ruby.sh
 - install_mongodb.sh
 - deploy.sh

 >> Создать startup script, исполняемый после создания compute instance

 - создаем metadata.yaml с необходимыми данными и командами и передаем имя файла `--metadata-from-file user-data=./metadata.yaml` команде yc при создании инстанса:

```
yc compute instance create --name reddit-app --hostname reddit-app --memory=512M --core-fraction=5 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --metadata serial-port-enable=1 --metadata-from-file user-data=./metadata.yaml
```

# лекция 5: дз

bastion_IP = 178.154.253.107

someinternalhost_IP = 10.130.0.14


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
178.154.253.107
```

идем на vpn на bastion через браузер `https://${bastion_IP}.sslip.io` <br>
Settings >> Lets Encrypt Domain = ${bastion_IP}.sslip.io


