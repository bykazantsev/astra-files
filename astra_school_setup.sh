#!/bin/bash

# Скрипт настройки Astra Linux 1.8 (Educational/SE)

# --- Настройки безопасности ---
# Прерывать выполнение при серьезных ошибках конфигурации, но не установки пакетов
set -u 

# --- Цвета для вывода ---
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
RESET='\033[0m'

LOG_FILE="/var/log/astra-setup-$(date +%Y%m%d).log"
CONFIG_FILE="./setup.conf"
INTERACTIVE=true

# --- Проверка Root ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Запустите скрипт с правами root (sudo)${RESET}"
    exit 1
fi

# --- Загрузка конфига ---
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${BLUE}Найден файл конфигурации $CONFIG_FILE. Применяю настройки...${RESET}"
    source "$CONFIG_FILE"
    INTERACTIVE=false
else
    echo -e "${YELLOW}Конфиг не найден. Включаю интерактивный режим.${RESET}"
fi

# --- Функции ---

log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

# Функция вопроса (спрашивает только если INTERACTIVE=true, иначе берет дефолт)
ask_var() {
    local var_name=$1
    local prompt=$2
    local default_value=$3
    
    # Если переменная уже задана (из конфига), не спрашиваем
    if [ -n "${!var_name:-}" ]; then
        return
    fi

    if [ "$INTERACTIVE" = true ]; then
        echo -e -n "${YELLOW}$prompt [y/n] (по умолч. $default_value): ${RESET}"
        read -r answer
        if [[ "$answer" =~ ^[Yy] ]]; then
            eval "$var_name=true"
        elif [[ "$answer" =~ ^[Nn] ]]; then
            eval "$var_name=false"
        else
            eval "$var_name=$default_value"
        fi
    else
        # Если не интерактив и переменная пуста — ставим дефолт
        eval "$var_name=$default_value"
    fi
}

ask_text() {
    local var_name=$1
    local prompt=$2
    
    if [ -n "${!var_name:-}" ]; then return; fi

    if [ "$INTERACTIVE" = true ]; then
        echo -e -n "${YELLOW}$prompt: ${RESET}"
        read -r val
        eval "$var_name=\"$val\""
    fi
}

run_cmd() {
    echo -e "${BLUE}➜ $1...${RESET}"
    log "START: $1"
    if eval "$2" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}OK${RESET}"
        log "SUCCESS: $1"
    else
        echo -e "${RED}FAIL${RESET}"
        log "ERROR: $1"
    fi
}

# --- НАЧАЛО РАБОТЫ ---

clear
echo -e "${BLUE}=== НАСТРОЙКА ASTRA LINUX 1.8 ===${RESET}"
log "Запуск скрипта настройки"

# 1. ОБНОВЛЕНИЕ
ask_var "DO_UPDATE" "Обновить систему (рекомендуется)?" "true"
if [ "$DO_UPDATE" = true ]; then
    run_cmd "Обновление списков пакетов" "apt-get update"
    run_cmd "Обновление системы" "apt-get dist-upgrade -y"
fi

# 2. УСТАНОВКА СОФТА
echo -e "\n${BLUE}--- Установка ПО ---${RESET}"

ask_var "INSTALL_DEV" "Установить языки (Python, C++, Pascal)?" "true"
if [ "$INSTALL_DEV" = true ]; then
    # В Astra 1.8/Debian 12 ставим python библиотеки через apt, а не pip!
    PKGS="build-essential g++ fp-compiler python3 python3-venv python3-numpy python3-pandas python3-matplotlib python3-pygame"
    run_cmd "Установка средств разработки" "apt-get install -y $PKGS"
fi

ask_var "INSTALL_SCRATCH" "Установить Scratch?" "true"
if [ "$INSTALL_SCRATCH" = true ]; then
    # Пробуем штатный, если нет - предупреждаем
    run_cmd "Установка Scratch" "apt-get install -y scratch scratch3 || echo 'Scratch не найден в репозиториях'"
fi

ask_var "INSTALL_WINE" "Установить Wine (для MyTestX и др.)?" "true"
if [ "$INSTALL_WINE" = true ]; then
    echo -e "${BLUE}Настройка 32-битной архитектуры для Wine...${RESET}"
    dpkg --add-architecture i386
    apt-get update >> "$LOG_FILE" 2>&1
    run_cmd "Установка Wine" "apt-get install -y wine wine32 winetricks"
fi

ask_var "INSTALL_KUMIR" "Установить Кумир?" "true"
if [ "$INSTALL_KUMIR" = true ]; then
    KUMIR_PATH="/opt/kumir"
    if [ ! -d "$KUMIR_PATH" ]; then
        run_cmd "Подготовка зависимостей Кумир" "apt-get install -y libqt5svg5 libqt5xml5"
        echo -e "${BLUE}Скачивание Кумир...${RESET}"
        wget -q -O /tmp/kumir.tar.gz "https://www.niisi.ru/kumir/Kumir2X-1462.tar.gz"
        
        if [ -s /tmp/kumir.tar.gz ]; then
            mkdir -p "$KUMIR_PATH"
            tar -xzf /tmp/kumir.tar.gz -C "$KUMIR_PATH" --strip-components=1
            
            # Ярлык
            cat > "/usr/share/applications/kumir.desktop" << EOF
[Desktop Entry]
Name=Кумир
Exec=$KUMIR_PATH/kumir2
Icon=utilities-terminal
Type=Application
Categories=Education;Development;
EOF
            chmod +x /usr/share/applications/kumir.desktop
            echo -e "${GREEN}Кумир установлен${RESET}"
        else
            echo -e "${RED}Ошибка скачивания Кумира (сайт недоступен?)${RESET}"
        fi
    fi
fi

ask_var "INSTALL_MYTEST" "Установить MyTestX (через Wine)?" "true"
if [ "$INSTALL_MYTEST" = true ]; then
    MYTEST_DIR="/opt/mytest"
    mkdir -p "$MYTEST_DIR"
    wget -q -O /tmp/mytest.zip "http://mytest.klyaksa.net/htm/download/mytester_pro.zip"
    if [ -s /tmp/mytest.zip ]; then
        unzip -o -q /tmp/mytest.zip -d "$MYTEST_DIR"
        
        # Ярлык
        cat > "/usr/share/applications/mytestx.desktop" << EOF
[Desktop Entry]
Name=MyTestX
Exec=wine "$MYTEST_DIR/MyTestStudent.exe"
Icon=wine
Type=Application
Categories=Education;
EOF
        chmod +x /usr/share/applications/mytestx.desktop
        echo -e "${GREEN}MyTestX установлен${RESET}"
    else
         echo -e "${RED}Ошибка скачивания MyTestX${RESET}"
    fi
fi

# 3. НАСТРОЙКА СЕТИ (WIFI)
echo -e "\n${BLUE}--- Настройка сети ---${RESET}"
ask_var "SETUP_WIFI" "Настроить WiFi?" "false"

if [ "$SETUP_WIFI" = true ]; then
    if [ -z "${WIFI_SSID:-}" ]; then
        nmcli dev wifi list
        ask_text "WIFI_SSID" "Введите имя сети (SSID)"
        ask_text "WIFI_PASS" "Введите пароль"
    fi
    
    if [ -n "$WIFI_SSID" ]; then
        echo -e "${BLUE}Подключение к $WIFI_SSID...${RESET}"
        if nmcli dev wifi connect "$WIFI_SSID" password "$WIFI_PASS"; then
            echo -e "${GREEN}Подключено!${RESET}"
        else
            echo -e "${RED}Ошибка подключения${RESET}"
        fi
    fi
fi

# 4. SAMBA (ОБЩАЯ ПАПКА)
echo -e "\n${BLUE}--- Общая папка ---${RESET}"
ask_var "SETUP_SAMBA" "Подключить сетевую папку?" "false"

if [ "$SETUP_SAMBA" = true ]; then
    run_cmd "Установка CIFS" "apt-get install -y cifs-utils"
    
    ask_text "SMB_SERVER" "IP сервера"
    ask_text "SMB_SHARE" "Имя ресурса"
    ask_text "SMB_USER" "Пользователь (guest если нет)"
    
    MOUNT="/mnt/school_share"
    mkdir -p "$MOUNT"
    
    # Проверка fstab
    if ! grep -q "$MOUNT" /etc/fstab; then
        if [ "$SMB_USER" == "guest" ]; then
            echo "//$SMB_SERVER/$SMB_SHARE $MOUNT cifs guest,vers=2.0,uid=1000,iocharset=utf8 0 0" >> /etc/fstab
        else
            ask_text "SMB_PASS" "Пароль Samba"
            mkdir -p /etc/samba
            echo "username=$SMB_USER" > /etc/samba/school.creds
            echo "password=$SMB_PASS" >> /etc/samba/school.creds
            chmod 600 /etc/samba/school.creds
            echo "//$SMB_SERVER/$SMB_SHARE $MOUNT cifs credentials=/etc/samba/school.creds,vers=2.0,uid=1000,iocharset=utf8 0 0" >> /etc/fstab
        fi
        echo -e "${GREEN}Запись добавлена в fstab${RESET}"
        mount -a
        
        # Ярлык на рабочий стол для всех пользователей
        # В Astra Linux Desktop часто лежит в /usr/share/templates или создается в /etc/skel/Desktop
        SKEL_DESKTOP="/etc/skel/Desktop"
        mkdir -p "$SKEL_DESKTOP"
        ln -sf "$MOUNT" "$SKEL_DESKTOP/Общая_папка"
        
        # И для текущего пользователя (если запускаем через sudo, реальный юзер в SUDO_USER)
        if [ -n "${SUDO_USER:-}" ]; then
             USER_DESKTOP="/home/$SUDO_USER/Desktop"
             [ -d "/home/$SUDO_USER/Рабочий стол" ] && USER_DESKTOP="/home/$SUDO_USER/Рабочий стол"
             ln -sf "$MOUNT" "$USER_DESKTOP/Общая_папка"
             chown -h "$SUDO_USER":"$SUDO_USER" "$USER_DESKTOP/Общая_папка"
        fi
    fi
fi

# 5. ОГРАНИЧЕНИЯ
echo -e "\n${BLUE}--- Безопасность ---${RESET}"
ask_var "APPLY_RESTRICTIONS" "Применить ограничения (нет sudo, блокировка сети)?" "true"

if [ "$APPLY_RESTRICTIONS" = true ]; then
    # Группа учеников
    groupadd -f uchenik
    
    # Sudoers (запрет)
    cat > "/etc/sudoers.d/school-restrictions" << EOF
%uchenik ALL=(ALL) !ALL
EOF
    chmod 440 "/etc/sudoers.d/school-restrictions"
    echo -e "${GREEN}Sudo заблокирован для группы uchenik${RESET}"
    
    # Блокировка изменения сети
    POLKIT_DIR="/etc/polkit-1/localauthority/50-local.d"
    mkdir -p "$POLKIT_DIR"
    cat > "$POLKIT_DIR/10-block-network.pkla" << EOF
[Block Network Config]
Identity=unix-group:uchenik
Action=org.freedesktop.NetworkManager.*
ResultAny=no
ResultInactive=no
ResultActive=no
EOF
    echo -e "${GREEN}Настройки сети заблокированы для группы uchenik${RESET}"
    
    echo -e "${YELLOW}ВАЖНО: Добавьте пользователей в группу uchenik:${RESET}"
    echo -e "sudo usermod -aG uchenik <username>"
fi

echo -e "\n${GREEN}=== НАСТРОЙКА ЗАВЕРШЕНА ===${RESET}"
echo -e "Лог сохранен в $LOG_FILE"
