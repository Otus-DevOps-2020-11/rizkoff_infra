
# лекция 10: дз "ansible-1"

 > следуем инструкциям ДЗ

 - ansible --version
   - `ansible 2.9.15`
 - поднимаем инфраструктуру stage из ДЗ terraform-2
   - `cd terraform/stage; terraform apply` (подробнее - 'ДЗ terraform-2')
 - создаем статический `ansible/inventory` с 2 строками (в ini-формате) - определяем appserver, dbserver.
   - проверяем: `ansible appserver -i ./inventory -m ping; ansible dbserver -i ./inventory -m ping`
 - создаем `./ansible.cfg`, переносим в него `inventory, remote_user, private_key_file`. Это позволяет убрать из статического inventory соответствующие поля.
   - команда ansible редуцируется до `ansible dbserver -m command -a uptime`
 - группируем хосты в `inventory`; 
   - становятся доступны групповые команды: `ansible app -m ping`
 - конвертируем inventory в yaml формат; указываем в `./ansible.cfg` новый статический инвентори-файл: `inventory = inventory.yml`
   - проверяем: `ansible app -m ping; ansible all -m ping; ansible dbserver -m ping`
   - вместо модификации `./ansible.cfg`, альтернативный inventory можно указывать из командной строки: `ansible all -m ping -i inventory.yml`
 - проверяем работу и сравниваем поведение модулей `ansible`: `command, shell, systemd, service, git`
 - создаем playbook `clone.yml` для клонирования git-репозитория
   - запускаем `ansible-playbook clone.yml`
     - клонирование не имело места, т.к. код уже находится в указанном месте.
   - выполняем `ansible app -m command -a 'rm -rf ~/reddit'; ansible-playbook clone.yml`
     - 2е клонирование было не "вхолостую", т.к. код в указанном месте отсутствовал.

 > задание со *: динамический inventory

 - создаем ruby-скрипт `dynainv.rb`, генерирующий inventory динамически, в требуемом (см. дз) формате. 
 - скрипт опрашивает параметры инстансов через обращение к YC cli;
 - преимущества скрипта: используется naming convention, фильтруются только VMs с именами /reddit-(app|db)/
   - в вывод добавляем ключ _meta с пустой секцией hostvars, для того чтобы ansible вызывал инвентори скрипт с --host для каждого хоста.
     - указываем скрипт в атрибуте `inventory = dynainv.rb` в `ansible.cfg`;  проверяем работу скрипта: `ruby dynainv.rb  --list | tee inventory.json.example`
     - проверяем работу ansible с динамическим inventory; `ansible all -m ping`
     - можно так же проверить командой `ansible-inventory --list; ansible-inventory --graph`
 - создаем так же bash-скрипт `dynainv_tf.sh`, работающий как парсинг запроса `terraform output`.
 - преимущества скрипта: зависит от лайф-цикла terraform, не конфликтует с "соседними" ресурсами.
   - проверяем аналогичным образом;`inventory = dynainv_tf.sh` в `ansible.cfg`; `ansible-inventory --list; ansible all -m ping`

# лекция 9: дз "terraform-2. Создание Terraform модулей для управления компонентами инфраструктуры."

 > следуем инструкциям ДЗ

 - lb.tf переносим в files/; параметр кол-во инстансов для lb ставим = 1
 - создаем сетевые ресурсы `yandex_vpc_network, yandex_vpc_subnet` 
 - выносим redis бэкенд нашего приложения в отдельный VM instance; для этого
   - модифицируем packer и пересобираем образы 2 VM для расщепленных инстансов app, db:
   - `(cd packer/; packer build -var-file=./variables.json ./app.json)`
   - `(cd packer/; packer build -var-file=./variables.json ./db.json)`
 - разносим конфиги из `main.tf` в `app.tf, db.tf`; конфигурацию сети в `vpc.tf`
 - соотв-е изменения с переменными и параметрами `variables.tf, outputs.tf, terraform.tfvars, terraform.tfvars.example`
 - `terraform apply` #проверяем создание ресурсов - с последующим `terraform destroy`
 - разбиваем код на модули `modules/db, modules/app`, переносим соотв. контент из `app.tf, db.tf, vpc.tf`; в `main.tf` определяем модули
 - загружаем модули из локального источника в кэш `.terraform`:
   - `terraform get`
 - модифицируем переменные на пользование модулями `module.app, module.db` вместо `yandex_compute_instance.app....`
 - `terraform apply` #проверяем создание ресурсов - с последующим `terraform destroy`
 - создаем инфраструктуру для 2х окружений - `stage, prod`
 - дублируем код в `stage/, prod/` для создания идентичных ресурсов для `stage, prod`
 - `terraform apply` #проверяем создание ресурсов - с последующим `terraform destroy`

 > самостоятельное задание: 

 - удаляем из `terraform/` файлы `main.tf, outputs.tf, terraform.tfvars, variables.tf` так как они теперь перенесены в `stage/ prod/`
 - параметризуем модули переменными `path.module, app_disk_image, subnet_id`
   - при желании, можем параметризовать разные defaults для `core_fraction, cores, memory` для stage VS prod; но по задаче у нас пока идентичные env'ы
 - `terraform fmt`


 > самостоятельное задание со *: перенос tfstate на удаленный бэкенд - в S3 бакет на облаке Yandex Object Storage

 - создаем или используем созданный service-account (в нашем примере `serviceotus`):
   - `yc iam service-account list` - в случае если таковой есть, используем; иначе
   - `yc iam service-account create --name serviceotus --description "otus exercizes-only service account"`
 - создаем cred's для работы по S3 (и запоминаем, т.к. команда дает разовый output без возм-ти повтора)
   - `yc iam access-key create --service-account-name serviceotus --description "S3 access key for state remote backend" [ --folder-id xxxxxxxxxxxxxxxxxxxx ]` # --folder-id по умолчанию будет использован из вывода `yc config list`
   - output:
```
access_key:
  id: xxxxxxxxxxxxxxxxxxxx
  service_account_id: aje6c58u7js0pl8n2284
  created_at: "2021-02-05T10:48:53.369498Z"
  description: S3 access key for state remote backend
  key_id: xxxxxxxxxxxxxxxxxxxx <<<<<<<<<<<<<<<<<<<<<<<<<<<<< запоминаем: см. access_key в backend.tf
secret: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  <<<<<<<<<< запоминаем: см. secret_key в backend.tf
```
 - создаем через UI console.cloud.yandex.ru >> Object Storage >> "создать бакет": бакет с именем (в нашем примере) `state-remote-backend`
 - в `stage/backend.tf, prod/backend.tf` переопределяем хранение tfstate на remote (S3) backend.
 - избавляемся от `terraform.tfstate` в `stage/, prod/`.
   - в обоих файлах: `stage/backend.tf, prod/backend.tf` - ключи S3-объекта делаем одинаковыми (в нашем примере `terraform.tfstate`)
   - это приведет к тому, что, напр., создавая окружение stage, мы можем видеть/менять его из prod, и наоборот - что и требовалось, т.к. у нас по условию задачи пока "слипшиеся" naming conventions и единый namespace в едином folder-id.
 - `terraform init` # (и в `stage/` и в `prod/`) т.к. имеем смену бэкенда
 - `terraform apply` #проверяем создание ресурсов - с последующим `terraform destroy`
 - проверяем: в `stage/, prod/` не появляются `terraform.tfstate`; в бакете `state-remote-backend` - появляется.
 - попытка одновременного apply неуспешна (два env, один tfstate).



 > самостоятельное задание с **: вернуть provisioner для развертывания `app` instance

 - возвращаем `files/* ` в tf-код; имеем проблему:
   - до расщепления на `app,db`:
   - listener `db` слушал localhost; после - необходимо прослушивать внешний адрес
   - до расщепления на `app,db`:
   - `app` делал коннект к localhost; после - необходим коннект с внешней mongodb
 - решаем:
   - `app`: переменную окружения `DATABASE_URL` передаем при запуске сервиса `puma` (`files/puma.service`)
   - `db`: listener базы mongodb управляется ключом `bindIp: X.X.X.X`; меняем значение c `172.0.0.1` на ip-адрес app-сервера (можно было бы поменять на значение "слушать всех" = `0.0.0.0`, но почему бы не сделать секюрней.) - изменение делаем `sed`-ом в inline remote-exec провижинере, в `modules/db/main.tf`.





# лекция 8: дз "terraform-1. Практика IaC с использованием Terraform"

 > проверяем пре-реквизиты

 - список образов должен содержать reddit-base-XXXXXXXXXX
```
yc compute image list
+----------------------+------------------------+-------------+----------------------+--------+
|          ID          |          NAME          |   FAMILY    |     PRODUCT IDS      | STATUS |
+----------------------+------------------------+-------------+----------------------+--------+
| xxxxxxxxxxxxxxxxxxxx | reddit-full-XXXXXXXXXX | reddit-full | xxxxxxxxxxxxxxxxxxxx | READY  |
| xxxxxxxxxxxxxxxxxxxx | reddit-base-XXXXXXXXXX | reddit-base | xxxxxxxxxxxxxxxxxxxx | READY  |
| xxxxxxxxxxxxxxxxxxxx | reddit-base-XXXXXXXXXX | reddit-base | xxxxxxxxxxxxxxxxxxxx | READY  |
| xxxxxxxxxxxxxxxxxxxx | reddit-full-XXXXXXXXXX | reddit-full | xxxxxxxxxxxxxxxxxxxx | READY  |
+----------------------+------------------------+-------------+----------------------+--------+
```
 - в нашем случае, 2 образа подойдут; packer выберет более новый из них. 
 - при желании 'освежить' образ (или отсутствии reddit-base-XXXXXXXXXX), собираем новый образ:
   - `packer/variables.json` создаем и редактируем, используя `cp packer/variables.json.example packer/variables.json` (подробней в ветке `packer-base`)
   -  то же, с парой `packer/key.json.example packer/key.json` (подробней в ветке `packer-base`)
   - `cd packer/ && packer build -var-file=./variables.json ./ubuntu16.json`
 - устанавливаем terraform, версия ~> 0.12.0.
```
terraform -v
Terraform v0.12.30
```
 - mkdir terraform && cd terraform
 - секцию provider yandex заполняем сначала hardcoded значениями:
```
provider "yandex" {
  token     = "<OAuth или статический ключ сервисного аккаунта>"
  cloud_id  = "<идентификатор облака>"
  folder_id = "<идентификатор каталога>"
  zone      = "ru-central1-a"
}
```
 - узнаем нужные id для подстановки:
 - `yc config list`
```
token: XXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
cloud-id: xxxxxxxxxxxxxxxxxxxx
folder-id: xxxxxxxxxxxxxxxxxxxx
```
 - `terraform init`
 - убеждаемся в выводе init'а, что версия провайдера yandex соответствует затребованной в дз:
```
...
provider.yandex: version = "~> 0.35"
Terraform has been successfully initialized!
```

 > создаем `resource "yandex_compute_instance"`

 - image_id, subnet_id - согласно инструкции, пока hardcoded.
   - image_id: выбираем нужный из колонки ID вывода `yc compute image list`
   - subnet_id: значение колонки ID нужной строки вывода `yc vpc subnet list` (в моем примере - нужная строка с ZONE="ru-central1-a")
 - `terraform apply`
 - подключаемся к vm
   - `terraform show | grep nat_ip_address`
   - `ssh -i ~/.ssh/ubuntu ubuntu@<найденный_ip_address>`
 >> коннект неуспешен, фиксим передачей ssh public key в инстанс
   - добавляем в `main.tf`, внутри секции `resource "yandex_compute_instance" "app"`:
```
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/ubuntu.pub")}"
  }
```
   - `terraform destroy`
   - `terraform apply`
 - подключаемся к vm: коннект успешен

 - в `outputs.tf` добавляем `output "external_ip_address_app"`
 - `terraform refresh`
```
Outputs:
external_ip_address_app = NN.NN.NN.NN
```
 - в `main.tf` добавляем провиженеры: "file" для puma.service и "remote-exec" для запуска скрипта установки и настройки приложения.
   - подключение провижинеров: секция 
```
connection {
  type = "ssh"
  host = yandex_compute_instance.app.network_interface.0.nat_ip_address
  user = "ubuntu"
  agent = false
  private_key = file("~/.ssh/ubuntu")
}
```
 - `terraform taint yandex_compute_instance.app`
 - `terraform apply`
```
...
Outputs:
external_ip_address_app = NN.NN.NN.NN
```
 - проверяем работу приложения в браузере `http://<external_ip_address_app>:9292`
 - параметризуем переменные: переносим hardcoded vars из `main.tf` в `variables.tf`
   - `cloud_id, folder_id, zone, public_key_path`
   - создаем пару `terraform.tfvars` & `terraform.tfvars.example`; готовим *.example для коммита в git - удаляем psi, не портя неконфиденциальную инфу
```
token            = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
cloud_id         = "xxxxxxxxxxxxxxxxxxxx"
folder_id        = "xxxxxxxxxxxxxxxxxxxx"
zone             = "ru-central1-a" 
...
```
 - `terraform destroy`
 - `terraform apply`
 - проверяем работоспособность приложения 
   - без браузера можно проверить только наличие листенера `nc -vzw1 <external_ip_address_app> 9292`
   - более полную проверку: `curl`; выборочно проверяем контент; для примера берем ф-цию `/login`:
```
curl http://<external_ip_address_app>:9292/login 2>/dev/null | grep -i input 
<input class='form-control' id='username' name='username' placeholder='Your username'>
<input class='form-control' id='password' name='password' placeholder='Your password'>
<input class='btn btn-primary' type='submit' value='Log in'>
```

 > самостоятельные задания

 >> Определите input переменную для приватного ключа...  подключения для провижинеров (connection)

```
variable private_key_path {
  description = "Path to the private key used for ssh access"
}
```

 >> Определите input переменную для задания зоны в ресурсе "yandex_compute_instance" "app". У нее <b>должно</b> быть значение по умолчанию

```
variable zone {
  description = "zone"
  default     = "ru-central1-a"
}

```

 >> Отформатируйте все конфигурационные файлы используя команду `terraform fmt`

 - `terraform fmt`

 >> ...  файл `terraform.tfvars.example`

 - после `git clone`: 
   - `cp <file>.example <file>`
   - редактируем <file> согласно инструкции

 > задание с *

 >> создать балансировщик в `lb.tf`

 - `resource "yandex_lb_target_group"` - группа хостов-таргетов для балансировщика;
   - сначала добавляем балансировщику единственный vm-инстанс
 - `resource "yandex_lb_network_load_balancer"`
 - добавляем в output переменные адрес балансировщика: `output "external_ip_address_lb"`
 - `terraform apply`
 - проверяем работу:
   - `nc -vzw1 <external_ip_address_app> 9292` - в обход балансировщика
   - `nc -vzw1 <external_ip_address_lb>  9292` - через балансировщик

 >> добавить в код 2й compute instance; проверить High Availability балансированного приложения (`systemctl stop puma` на 1 из 2х инстансов)

 - git commit id: `7d45a5d lb before count parameterization dry-up`
 - в `main.tf`:
```
resource "yandex_compute_instance" "app2" {
  name = "reddit-app2-tf"
```
 - дублируем код в `app2` из `app` ~45 строк = NOT DRY
 - в `lb.tf` добавляем 2ю секцию `target {...` для app2.

 >> Удалить описание reddit-app2 и параметризовать количество инстансов через count.

 - `main.tf`:
```
resource "yandex_compute_instance" "app" {
  count       = var.app_scale
  name        = "reddit-app-${count.index}-tf"
...
```
 - `lb.tf`: пользуемся конструкциями dynamic & for_each:
```
resource "yandex_lb_target_group" "tgtgrp-reddit" {
  name      = "tgtgrp-reddit"
  region_id = var.lb_target_group_region_id

  dynamic target {
    for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
    content {
      subnet_id = var.subnet_id
      address   = target.value
    }
  }
}
...
```
 - `terraform apply`
 - `terraform destroy`


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


