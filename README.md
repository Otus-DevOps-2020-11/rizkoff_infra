
# лекция 7: дз "packer"

 > используем packer для создания образа для compute instance.

 - ставим packer, создаем service account key file, по шагам в дз.
 - создаем *.json с параметрами и provisioner-инструкциями для packer.
   - исталляция ruby, mongo - представлена 2мя provisioner скриптами
 - запускаем сборку образа: `packer build ./ubuntu16.json`

 > 7.2. Диагностика ошибки

 >> `Build 'yandex' errored: Failed to find instance ip address: instance has no one IPv4 external address.`

 - фиксируется добавлением в секции "builders":

```
            "use_ipv4_nat": true
```

  >> отказ создавать еще одну подсеть (дефолтное поведение CLI-команды создания инстанса)

 - фиксим использованием существующей, указываем в секции "builders":

```
            "subnet_id": "{{user `subnet_id`}}",
```


  > выносим часть параметров в файл variables.json.

 - заносим variables.json в .gitignore; переносим значения privacy-sensitive части параметров в variables.json.
 - создаем variables.json.example с фейковыми значениями параметров из variables.json, для re-use git-кода
 - в новом проекте необходимо 
   -- `cp variables.json.example variables.json`
   -- поставить правильные значения в variables.json
 - команда создания образа: `packer build -var-file=./variables.json ./ubuntu16.json`
 - созданный образ используем при создании compute instance, логинимся по ssh.
 - вручную инсталлируем & запускаем web-приложение `https://github.com/express42/reddit.git` вручную.
 - проверяем работу в браузере: http://<внешний IP машины>:9292

 > 10.1*. Построение bake-образа

 - создаем immutable.json; основные отличия - добавление 2 provisioners
   - `sleep 50`, для снятия блокировки apt-get
   - набор inline команд установки https://github.com/express42/reddit.git с пре-реквизитами
 - команда создания образа: `packer build -var-file=./variables.json ./immutable.json`
 - созданный образ используем при создании compute instance, логинимся по ssh.
 - ручной доустановки приложения не требуется.
 - проверяем работу в браузере: http://<внешний IP машины>:9292

 > 10.2*. Автоматизация создания ВМ

 - скрипт `config-scripts/create-reddit-vm.sh`; вместо создания compute instance через GUI, одна CLI-команда.
 - в случае существования нескольких образов reddit-full-XXXXXXXXXX, через параметр image-family=reddit-full будет взят с более поздней датой создания
 - usage: `bash config-scripts/create-reddit-vm.sh [ instance-name ]`
  - в случае пустого аргумента `instance-name`, инстансу присваивается сгенерированное имя reddit-app-XXXXXXXX.

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


