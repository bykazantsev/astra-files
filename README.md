# Astra Linux 1.8 – Автоматическая настройка

Скрипт для быстрой настройки образовательной/SE версии **Astra Linux 1.8** под школьную среду.

[![GitHub issues](https://img.shields.io/github/issues/bykazantsev/astra-files)](https://github.com/bykazantsev/astra-files/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/bykazantsev/astra-files)](https://github.com/bykazantsev/astra-files/pulls)

## ✨ Что делает скрипт

- 🔄 **Обновление системы** (apt-get update + dist-upgrade)
- 🛠️ **Установка ПО для обучения**:
  - Python 3 + библиотеки (numpy, pandas, matplotlib, pygame)
  - C++ (g++), Pascal (fp-compiler)
  - Scratch (штатный пакет)
  - **Wine** (32-бит + winetricks) для MyTestX
  - **Кумир 2X** (автоматическая установка)
  - **MyTestX** (через Wine)
- 📶 **WiFi** – подключение к школьной сети
- 📁 **Samba** – монтирование общей папки + ярлыки
- 🔒 **Безопасность** – блокировка sudo и сети для учеников

## 🚀 Быстрый старт

```bash
# 1. Скачайте скрипт
wget https://raw.githubusercontent.com/bykazantsev/astra-files/main/astra_school_setup.sh

# 2. Дайте права
chmod +x astra_school_setup.sh

# 3. Запустите (создастся интерактивный режим)
sudo ./astra_school_setup.sh
```

## ⚙️ Конфигурация

Создайте файл `setup.conf`:

```bash
# Основные настройки
DO_UPDATE=true
INSTALL_DEV=true
INSTALL_SCRATCH=true
INSTALL_WINE=true
INSTALL_KUMIR=true  
INSTALL_MYTEST=true

# WiFi (если SETUP_WIFI=true)
SETUP_WIFI=false
WIFI_SSID="School_WiFi"
WIFI_PASS="password123"

# Samba (если SETUP_SAMBA=true)  
SETUP_SAMBA=false
SMB_SERVER="192.168.1.100"
SMB_SHARE="public"
SMB_USER="guest"
SMB_PASS=""

# Ограничения
APPLY_RESTRICTIONS=true
```

Запуск с конфигом:
```bash
sudo ./setup-astra.sh  # автоматически подхватит setup.conf
```

## 📋 Таблица настроек

| Функция | Переменная | По умолчанию | Описание |
|---------|------------|--------------|----------|
| Обновление | `DO_UPDATE` | `true` | apt-get update + dist-upgrade |
| Разработка | `INSTALL_DEV` | `true` | Python/C++/Pascal |
| Scratch | `INSTALL_SCRATCH` | `true` | Официальный пакет |
| Wine | `INSTALL_WINE` | `true` | 32-бит + winetricks |
| Кумир | `INSTALL_KUMIR` | `true` | Автоустановка из tar.gz |
| MyTestX | `INSTALL_MYTEST` | `true` | Через Wine |
| WiFi | `SETUP_WIFI` | `false` | nmcli connect |
| Samba | `SETUP_SAMBA` | `false` | /mnt/school_share |
| Ограничения | `APPLY_RESTRICTIONS` | `true` | no sudo/network для группы `uchenik` |

## 📁 Пути установки программ

```
/opt/kumir/          ← Кумир
/opt/mytest/         ← MyTestX  
/etc/samba/school.creds ← Samba credentials  
/mnt/school_share    ← Общая папка
/usr/share/applications/ ← Ярлыки программ
/var/log/astra-setup-*.log ← Логи
/etc/sudoers.d/school-restrictions ← Блокировка sudo
```

## 🌍 Важная информация

- **Wine** требует 32-битной архитектуры (автоматически добавляется)
- Кумир скачивается с официального сайта niisi.ru
- Лог сохраняется в директории `/var/log/` с названием формата `astra-setup-YYYYMMDD.log`

## 🤝 Вклад в проект

Приветствуются **изменения и предложения** через:

- [🚨 Создать Issue](https://github.com/bykazantsev/astra-files/issues)
- [✨ Pull Request](https://github.com/bykazantsev/astra-files/pulls)

## 📄 Лицензия
Разрешатеся другим лицам использовать, копировать, изменять, публиковать и распространять этот код без ограничений.
[MIT](LICENSE) © bykazantsev

---
```
