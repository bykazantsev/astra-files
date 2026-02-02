#!/bin/bash

RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
CYAN='\033[1;96m'
PURPLE='\033[1;95m'
BLUE='\033[1;94m'
RESET='\033[0m'
BOLD='\033[1m'

LINE="══════════════════════════════════════════════════════════════════════════"
LINE_SHORT="════════════════════════════════════════"

ERRORS_OCCURRED=0

print_header() {
    clear
    echo -e "${PURPLE}${LINE}${RESET}"
    echo -e "${CYAN}${BOLD}        НАСТРОЙКА УЧЕБНОГО КОМПЬЮТЕРА LINUX           ${RESET}"
    echo -e "${CYAN}${BOLD}        Автоматическая настройка системы            ${RESET}"
    echo -e "${PURPLE}${LINE}${RESET}\n"
}

print_section() {
    echo -e "\n${YELLOW}${BOLD}╔ ${LINE_SHORT}╗${RESET}"
    echo -e "${YELLOW}${BOLD}║ $1 ║${RESET}"
    echo -e "${YELLOW}${BOLD}╚ ${LINE_SHORT}╝${RESET}\n"
}

ask_yesno() {
    while true; do
        echo -e -n "${YELLOW}$1 (y/n): ${RESET}"
        read -r yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo -e "${RED}Ответьте y (да) или n (нет)${RESET}";;
        esac
    done
}

ask_number() {
    while true; do
        echo -e -n "${YELLOW}$1: ${RESET}"
        read -r num
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge "$2" ] && [ "$num" -le "$3" ]; then
            return "$num"
        else
            echo -e "${RED}Введите число от $2 до $3${RESET}"
        fi
    done
}

ask_text() {
    local prompt="$1"
    echo -e "${YELLOW}$prompt${RESET}"
    echo -n "> "
    read -r text
    echo "$text"
}

log_message() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

execute_command() {
    local cmd="$1"
    local description="$2"
    
    echo -e "${BLUE}$description...${RESET}"
    log_message "Начало: $description"
    log_message "Команда: $cmd"
    
    eval "$cmd" >> "$LOG_FILE" 2>&1
    local status=$?
    
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}✓ $description завершено${RESET}"
        log_message "Успешно: $description"
    else
        echo -e "${RED}✗ Ошибка при $description${RESET}"
        log_message "Ошибка при $description (код: $status)"
        ERRORS_OCCURRED=1
    fi


    return $status
}

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}${BOLD}ОШИБКА: Скрипт должен запускаться с правами root${RESET}"
    echo -e "Запустите: ${CYAN}sudo bash $0${RESET}"
    exit 1
fi

LOG_FILE="/var/log/school-setup-$(date +%Y%m%d-%H%M%S).log"
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

log_message "=== НАЧАЛО НАСТРОЙКИ КОМПЬЮТЕРА ==="
log_message "Время начала: $(date)"
log_message "Пользователь: $(whoami)"
log_message "Система: $(uname -a)"

print_header
echo -e "${GREEN}Начинаю настройку учебного компьютера...${RESET}"
echo -e "${YELLOW}Все действия будут записаны в лог: ${CYAN}$LOG_FILE${RESET}\n"

###############################################################################
# ШАГ 1: ОБНОВЛЕНИЕ СИСТЕМЫ
###############################################################################
print_section "ШАГ 1: ОБНОВЛЕНИЕ СИСТЕМЫ"

if ask_yesno "Обновить систему (apt-get dist-upgrade)?"; then
    log_message "Пользователь выбрал обновление системы"

    execute_command "apt-get update -y" "Обновление списка пакетов"
    execute_command "apt-get full-upgrade -y" "Обновление установленных пакеты"
    execute_command "apt-get autoremove -y" "Удаляем ненужные зависимости"
    execute_command "apt-get autoclean" "Очищаем кэш старых пакетов"
else
    log_message "Пользователь отказался от обновления системы"
    echo -e "${YELLOW}Обновление пропущено${RESET}"
fi

###############################################################################
# ШАГ 2: ВЫБОР ПАКЕТОВ ДЛЯ УСТАНОВКИ
###############################################################################
print_section "ШАГ 2: ВЫБОР ПАКЕТОВ ДЛЯ УСТАНОВКИ"

PACKAGES_TO_INSTALL=""
INSTALLED_CATEGORIES=()

echo -e "${GREEN}✓ Базовые утилиты устанавливаются автоматически${RESET}"
PACKAGES_TO_INSTALL="git curl wget htop nano tree unzip "
INSTALLED_CATEGORIES+=("Базовые утилиты")
log_message "Автоматически выбраны базовые утилиты"

while true; do
    echo -e "${CYAN}${BOLD}╔ ${LINE_SHORT}╗${RESET}"
    echo -e "${CYAN}${BOLD}║ ВЫБЕРИТЕ КАТЕГОРИИ ПАКЕТОВ                  ║${RESET}"
    echo -e "${CYAN}${BOLD}╚ ${LINE_SHORT}╝${RESET}"
    
    echo -e "${BLUE} 1. Языки программирования (Python, Кумир, pascal, c, c++)${RESET}"
    echo -e "${BLUE} 2. Визуальное программирование (Scratch)${RESET}"
    echo -e "${BLUE} 3. Инструменты для работы с Windows приложениями (Wine и его дополнения)${RESET}"
    echo -e "${BLUE} 4. MyTestX (система тестирования)${RESET}"
    echo -e "${BLUE} 5. Удалённый доступ (SSH)${RESET}"
    echo -e "${BLUE} 0. Завершить выбор${RESET}"
    
    echo -e -n "\n${YELLOW}Выбор (0-5): ${RESET}"
    read -r choice
    
    case $choice in
        1)
            if ask_yesno "Установить языки программирования?"; then
                PACKAGES_TO_INSTALL+="python3 python3-pip python3-venv gcc g++ fp-compiler "
                INSTALLED_CATEGORIES+=("Языки программирования")
                log_message "Выбраны языки программирования"
            fi
            ;;
        2)
            if ask_yesno "Установить Scratch (визуальное программирование)?"; then
                PACKAGES_TO_INSTALL+="scratch scratch3 "
                INSTALLED_CATEGORIES+=("Scratch")
                log_message "Выбран Scratch"
            fi
            ;;
        3)
            if ask_yesno "Установить Wine для работы с Windows приложениями?"; then
                PACKAGES_TO_INSTALL+="wine wine32 winetricks "
                INSTALLED_CATEGORIES+=("Wine")
                log_message "Выбран Wine"
            fi
            ;;
        4)
            if ask_yesno "Установить MyTestX (система тестирования)?"; then
                INSTALLED_CATEGORIES+=("MyTestX")
                log_message "Выбран MyTestX"
            fi
            ;;
        5)
            if ask_yesno "Установить SSH для удалённого доступа?"; then
                PACKAGES_TO_INSTALL+="openssh-server openssh-client "
                INSTALLED_CATEGORIES+=("SSH")
                log_message "Выбран SSH"
            fi
            ;;
        0)
            log_message "Завершен выбор пакетов. Выбрано категорий: ${#INSTALLED_CATEGORIES[@]}"
            break
            ;;
        *)
            echo -e "${RED}Неверный выбор. Введите число от 0 до 5${RESET}"
            log_message "Неверный ввод при выборе пакетов: $choice"
            ;;
    esac
    
    echo ""
done

# Установка выбранных пакетов
if [ -n "$PACKAGES_TO_INSTALL" ]; then
    echo -e "\n${BLUE}Устанавливаю пакеты:${RESET}"
    echo -e "${CYAN}$PACKAGES_TO_INSTALL${RESET}"
    log_message "Начинаю установку пакетов: $PACKAGES_TO_INSTALL"
    
    execute_command "apt-get install -y $PACKAGES_TO_INSTALL" "Установка выбранных пакетов"
    
    # Установка Python библиотек, если выбрано программирование
    if [[ " ${INSTALLED_CATEGORIES[@]} " =~ "Языки программирования" ]]; then
        log_message "Устанавливаю Python библиотеки"
        execute_command "pip3 install numpy matplotlib pandas pygame jupyter requests flask django" "Установка Python библиотек"
    fi
else
    log_message "Дополнительные пакеты для установки не выбраны"
fi

###############################################################################
# ШАГ 2.1: УСТАНОВКА КУМИРА
###############################################################################
if [[ " ${INSTALLED_CATEGORIES[@]} " =~ "Языки программирования" ]]; then
    print_section "ШАГ 2.1: УСТАНОВКА КУМИРА"
    
    execute_command "apt install -y libqt4-svg" "Установка зависимостей"

    echo -e "${BLUE}Скачиваю и устанавливаю Кумир...${RESET}"
    log_message "Начинаю установку Кумира"
    
    KUMIR_URL="https://www.niisi.ru/kumir/Kumir2X-1462.tar.gz"
    KUMIR_DIR="/opt/kumir"
    
    # Создаем директорию для Кумира
    execute_command "mkdir -p $KUMIR_DIR" "Создание директории для Кумира"
    
    # Скачиваем Кумир
    echo -e "${BLUE}Скачиваю Кумир...${RESET}"
    execute_command "wget -O /tmp/kumir.tar.gz $KUMIR_URL" "Загрузка Кумира"
    
    # Распаковываем
    echo -e "${BLUE}Распаковываю...${RESET}"
    execute_command "tar -xzf /tmp/kumir.tar.gz -C $KUMIR_DIR --strip-components=1" "Распаковка Кумира"
    
    # Создаем ярлык
    echo -e "${BLUE}Создаю ярлык на рабочем столе...${RESET}"
    DESKTOP_DIR="/home/$(logname)/Desktop"
    if [ -d "$DESKTOP_DIR" ]; then
        cat > "$DESKTOP_DIR/Kumir.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Кумир
Comment=Среда программирования Кумир
Exec=$KUMIR_DIR/kumir2
Icon=$KUMIR_DIR/icons/kumir.svg
Terminal=false
Categories=Development;Education;
EOF
        execute_command "chmod +x $DESKTOP_DIR/Kumir.desktop" "Создание ярлыка Кумира"
    fi
    
    # Добавляем в PATH
    echo 'export PATH=$PATH:/opt/kumir' >> /etc/profile.d/kumir.sh
    chmod +x /etc/profile.d/kumir.sh
    
    echo -e "${GREEN}✓ Кумир установлен в $KUMIR_DIR${RESET}"
    log_message "Кумир успешно установлен"
fi

###############################################################################
# ШАГ 2.2: НАСТРОЙКА WINE
###############################################################################
if [[ " ${INSTALLED_CATEGORIES[@]} " =~ "Wine" ]]; then
    print_section "ШАГ 2.2: НАСТРОЙКА WINE"
    
    echo -e "${BLUE}Настраиваю Wine...${RESET}"
    log_message "Начинаю настройку Wine"
    
    # Настраиваем Wine для 32-битных приложений
    echo -e "${BLUE}Настраиваю архитектуру Wine...${RESET}"
    execute_command "winecfg -v winxp &>/dev/null &" "Настройка Wine (фоном)"
    
    # Устанавливаем шрифты
    echo -e "${BLUE}Устанавливаю шрифты для Wine...${RESET}"
    execute_command "winetricks corefonts" "Установка шрифтов"
    
    # Создаем ярлык для winecfg
    DESKTOP_DIR="/home/$(logname)/Desktop"
    if [ -d "$DESKTOP_DIR" ]; then
        cat > "$DESKTOP_DIR/Wine-Config.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Настройка Wine
Comment=Настройка совместимости с Windows
Exec=winecfg
Icon=wine
Terminal=false
Categories=System;
EOF
        execute_command "chmod +x $DESKTOP_DIR/Wine-Config.desktop" "Создание ярлыка Wine"
    fi
    
    echo -e "${GREEN}✓ Wine настроен${RESET}"
    echo -e "${YELLOW}Для запуска Windows программ используйте команду: wine program.exe${RESET}"
    log_message "Wine настроен"
fi

###############################################################################
# ШАГ 2.3: УСТАНОВКА MYTESTX
###############################################################################
if [[ " ${INSTALLED_CATEGORIES[@]} " =~ "MyTestX" ]]; then
    print_section "ШАГ 2.3: УСТАНОВКА MYTESTX"
    
    echo -e "${BLUE}Устанавливаю MyTestX...${RESET}"
    log_message "Начинаю установку MyTestX"
    
    # Проверяем, установлен ли Wine (если нет - устанавливаем)
    if ! command -v wine &> /dev/null; then
        echo -e "${YELLOW}Wine не установлен. Устанавливаю для работы MyTestX...${RESET}"
        execute_command "apt-get install -y wine wine32" "Установка Wine для MyTestX"
    fi
    
    # Скачиваем MyTestX (пример URL, нужно проверить актуальность)
    MYTEST_URL="https://mytest.klyaksa.net/htm/download/mytester_pro.zip"
    MYTEST_DIR="/opt/mytest"
    
    execute_command "mkdir -p $MYTEST_DIR" "Создание директории для MyTestX"
    
    echo -e "${BLUE}Скачиваю MyTestX...${RESET}"
    execute_command "wget -O /tmp/mytest.zip $MYTEST_URL" "Скачивание MyTestX"
    
    echo -e "${BLUE}Распаковываю...${RESET}"
    execute_command "unzip -q /tmp/mytest.zip -d $MYTEST_DIR" "Распаковка MyTestX"
    
    # Создаем ярлык для запуска через Wine
    DESKTOP_DIR="/home/$(logname)/Desktop"
    if [ -d "$DESKTOP_DIR" ]; then
        cat > "$DESKTOP_DIR/MyTestX.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=MyTestX
Comment=Система тестирования
Exec=wine $MYTEST_DIR/MyTestStudent.exe
Icon=wine
Terminal=false
Categories=Education;
EOF
        execute_command "chmod +x $DESKTOP_DIR/MyTestX.desktop" "Создание ярлыка MyTestX"
    fi
    
    echo -e "${GREEN}✓ MyTestX установлен в $MYTEST_DIR${RESET}"
    echo -e "${YELLOW}Запуск: На рабочем столе ярлык MyTestX${RESET}"
    log_message "MyTestX установлен"
fi

###############################################################################
# ШАГ 2.4: НАСТРОЙКА SSH
###############################################################################
if [[ " ${INSTALLED_CATEGORIES[@]} " =~ "SSH" ]]; then
    print_section "ШАГ 2.4: НАСТРОЙКА SSH"
    
    if ask_yesno "Настроить SSH сервер?"; then
        echo -e "${BLUE}Настраиваю SSH...${RESET}"
        log_message "Начинаю настройку SSH"
        
        # Резервная копия конфигурации
        execute_command "cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup" "Создание резервной копии SSH конфигурации"
        
        # Безопасные настройки
        echo -e "${BLUE}Применяю безопасные настройки SSH...${RESET}"
        
        # Используем временный файл для изменений
        SSH_TEMP="/tmp/sshd_config.temp"
        cp /etc/ssh/sshd_config "$SSH_TEMP"
        
        # Применяем изменения
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' "$SSH_TEMP"
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' "$SSH_TEMP"
        sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' "$SSH_TEMP"
        sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' "$SSH_TEMP"
        sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' "$SSH_TEMP"
        sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 2/' "$SSH_TEMP"
        
        # Запрещаем пустые пароли
        echo "PermitEmptyPasswords no" >> "$SSH_TEMP"
        
        # Меняем порт (опционально)
        if ask_yesno "Изменить стандартный порт SSH (22)?"; then
            read -p "Введите новый порт (1024-65535): " SSH_PORT
            if [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && [ "$SSH_PORT" -ge 1024 ] && [ "$SSH_PORT" -le 65535 ]; then
                sed -i "s/#Port 22/Port $SSH_PORT/" "$SSH_TEMP"
                echo -e "${BLUE}Порт SSH изменен на $SSH_PORT${RESET}"
                log_message "Порт SSH изменен на $SSH_PORT"
                
                # Настраиваем firewall для нового порта
                if command -v ufw &> /dev/null; then
                    ufw allow "$SSH_PORT/tcp" >> "$LOG_FILE" 2>&1
                fi
            else
                echo -e "${RED}Неверный порт. Используется стандартный порт 22${RESET}"
                log_message "Неверный порт SSH указан, используется порт 22"
            fi
        fi
        
        # Копируем обратно
        cp "$SSH_TEMP" /etc/ssh/sshd_config
        rm -f "$SSH_TEMP"
        
        log_message "Безопасные настройки SSH применены"
        
        # Перезапускаем SSH
        echo -e "${BLUE}Проверяю конфигурацию SSH...${RESET}"
        echo -e "${BLUE}Исправляю права на SSH ключи...${RESET}"
        chmod 600 /etc/ssh/ssh_host_* 2>/dev/null || true
        sshd -t >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            execute_command "systemctl restart sshd" "Перезапуск SSH службы"
            execute_command "systemctl enable sshd" "Включение автозапуска SSH"
        else
            echo -e "${RED}Ошибка в конфигурации SSH. Восстанавливаю backup...${RESET}"
            log_message "Ошибка проверки SSH конфигурации, восстанавливаю backup"
            cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
            execute_command "systemctl restart sshd" "Перезапуск SSH службы (после восстановления)"
        fi
        
        # Показываем информацию для подключения
        IP_ADDRESS=$(hostname -I | awk '{print $1}')
        SSH_PORT=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}' || echo "22")
        
        echo -e "${GREEN}✓ SSH настроен${RESET}"
        log_message "SSH настроен"
        
        echo -e "\n${YELLOW}Информация для подключения:${RESET}"
        echo -e "  Адрес: ${CYAN}$IP_ADDRESS${RESET}"
        echo -e "  Порт: ${CYAN}$SSH_PORT${RESET}"
        echo -e "  Команда для подключения: ${CYAN}ssh $(logname)@$IP_ADDRESS -p $SSH_PORT${RESET}"
        
        # Включаем SSH в firewall если он активен
        if systemctl is-active --quiet ufw; then
            echo -e "${BLUE}Добавляю SSH в firewall...${RESET}"
            if [ "$SSH_PORT" != "22" ]; then
                ufw allow "$SSH_PORT/tcp" >> "$LOG_FILE" 2>&1
            else
                ufw allow ssh >> "$LOG_FILE" 2>&1
            fi
        fi
    else
        log_message "Настройка SSH пропущена"
    fi
fi

###############################################################################
# ШАГ 3: НАСТРОЙКА СЕТИ И WIFI
###############################################################################
print_section "ШАГ 3: НАСТРОЙКА СЕТИ И WIFI"

if ask_yesno "Настроить WiFi подключение?"; then
    log_message "Начинаю настройку WiFi"
    
    echo -e "${BLUE}Текущие сетевые интерфейсы:${RESET}"
    ip link show | grep -E "^[0-9]+:" | awk -F: '{print $2}' | tr -d ' '
    
    # Получаем имя WiFi интерфейса
    WIFI_INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}' | head -1)
    
    if [ -z "$WIFI_INTERFACE" ]; then
        echo -e "${YELLOW}WiFi интерфейс не найден${RESET}"
        log_message "WiFi интерфейс не найден автоматически"
        echo -e "${BLUE}Доступные интерфейсы:${RESET}"
        ip link show | grep -E "^[0-9]+:" | awk -F: '{print $2}' | tr -d ' '
        WIFI_INTERFACE=$(ask_text "Введите имя интерфейса WiFi (например wlan0)")
    else
        echo -e "${GREEN}Найден WiFi интерфейс: $WIFI_INTERFACE${RESET}"
        log_message "Найден WiFi интерфейс: $WIFI_INTERFACE"
    fi
    
    # Запрашиваем данные WiFi
    echo -e "\n${BLUE}Настройка WiFi:${RESET}"
    SSID=$(ask_text "Имя WiFi сети" | sed 's/[()]//g')

    if [ -z "$SSID" ]; then
        echo -e "${RED}Имя WiFi сети не может быть пустым${RESET}"
        log_message "Пользователь ввел пустое имя WiFi сети"
        return
    fi
    
    # Спрашиваем пароль (скрытый ввод)
    echo -e -n "${YELLOW}Пароль WiFi сети: ${RESET}"
    read -s WIFI_PASSWORD
    echo
    log_message "Пароль WiFi: [скрыт]"
    
    # Настраиваем NetworkManager
    echo -e "${BLUE}Настраиваю NetworkManager...${RESET}"
    
    # Создаем конфигурацию WiFi
    NM_FILE="/etc/NetworkManager/system-connections/$SSID.nmconnection"
    cat > "$NM_FILE" << EOF
[connection]
id=$SSID
uuid=$(uuidgen)
type=wifi
interface-name=$WIFI_INTERFACE

[wifi]
mode=infrastructure
ssid=$SSID

[wifi-security]
key-mgmt=wpa-psk
psk=$WIFI_PASSWORD

[ipv4]
method=auto

[ipv6]
addr-gen-mode=stable-privacy
method=auto
EOF
    
    execute_command "chmod 600 $NM_FILE" "Установка прав на файл WiFi конфигурации"
    
    # Перезапускаем NetworkManager
    execute_command "systemctl restart NetworkManager" "Перезапуск NetworkManager"
    
    # Подключаемся к сети
    echo -e "${BLUE}Подключаюсь к WiFi сети...${RESET}"
    nmcli connection up "$SSID" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ WiFi подключен${RESET}"
        log_message "Успешное подключение к WiFi: $SSID"
    else
        echo -e "${YELLOW}⚠ Не удалось подключиться автоматически${RESET}"
        log_message "Предупреждение: не удалось автоматически подключиться к WiFi"
    fi
    
    echo -e "${GREEN}✓ WiFi настроен${RESET}"
else
    log_message "Настройка WiFi пропущена"
fi

# Настройка статического IP (опционально)
if ask_yesno "Настроить статический IP адрес?"; then
    log_message "Начинаю настройку статического IP"
    
    echo -e "${BLUE}Настройка статического IP:${RESET}"
    
    INTERFACE=$(ask_text "Введите имя интерфейса (например eth0)")
    IP_ADDRESS=$(ask_text "Введите IP адрес (например 192.168.1.100)")
    GATEWAY=$(ask_text "Введите шлюз (например 192.168.1.1)")
    DNS=$(ask_text "Введите DNS сервер (например 8.8.8.8)")
    
    log_message "Настройка статического IP для $INTERFACE: $IP_ADDRESS, шлюз: $GATEWAY, DNS: $DNS"
    
    # Создаем конфигурацию
    NETPLAN_FILE="/etc/netplan/01-network-config.yaml"
    cat > "$NETPLAN_FILE" << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - $IP_ADDRESS/24
      gateway4: $GATEWAY
      nameservers:
        addresses: [$DNS]
EOF
    
    execute_command "netplan apply" "Применение сетевых настроек"
    echo -e "${GREEN}✓ Статический IP настроен${RESET}"
    log_message "Статический IP настроен для $INTERFACE"
else
    log_message "Настройка статического IP пропущена"
fi

###############################################################################
# ШАГ 4: ПОДКЛЮЧЕНИЕ К SAMBA-СЕРВЕРУ
###############################################################################
print_section "ШАГ 4: ПОДКЛЮЧЕНИЕ К SAMBA-СЕРВЕРУ"

if ask_yesno "Настроить подключение к Samba-серверу в сети?"; then
    log_message "Начинаю настройку подключения к Samba-серверу"
    
    echo -e "${BLUE}Устанавливаю клиентские утилиты Samba...${RESET}"
    execute_command "apt-get install -y cifs-utils samba-client" "Установка клиента Samba"
    
    # Спрашиваем параметры подключения
    echo -e "${YELLOW}Введите параметры подключения к Samba-серверу:${RESET}"
    
    # Имя сервера
    read -p "Имя или IP-адрес Samba-сервера: " SAMBA_SERVER
    if [ -z "$SAMBA_SERVER" ]; then
        SAMBA_SERVER="192.168.1.100"
        echo -e "${YELLOW}Используется адрес по умолчанию: $SAMBA_SERVER${RESET}"
    fi
    
    # Имя общего ресурса
    read -p "Имя общего ресурса (шары) на сервере: " SHARE_NAME
    if [ -z "$SHARE_NAME" ]; then
        SHARE_NAME="public"
        echo -e "${YELLOW}Используется ресурс по умолчанию: $SHARE_NAME${RESET}"
    fi
    
    # Имя пользователя
    read -p "Имя пользователя для доступа: " SAMBA_USER
    if [ -z "$SAMBA_USER" ]; then
        SAMBA_USER="guest"
        echo -e "${YELLOW}Используется пользователь по умолчанию: $SAMBA_USER${RESET}"
    fi
    
    # Пароль
    read -sp "Пароль для доступа (оставьте пустым для гостевого доступа): " SAMBA_PASS
    echo
    
    # Имя точки монтирования
    read -p "Локальная папка для монтирования [/mnt/samba]: " MOUNT_POINT
    if [ -z "$MOUNT_POINT" ]; then
        MOUNT_POINT="/mnt/samba"
    fi
    
    # Создаем папку для монтирования
    echo -e "${BLUE}Создаю точку монтирования...${RESET}"
    execute_command "mkdir -p $MOUNT_POINT" "Создание точки монтирования"
    
    # Создаем файл с учетными данными (если нужно)
    if [ -n "$SAMBA_PASS" ] && [ "$SAMBA_USER" != "guest" ]; then
        echo -e "${BLUE}Создаю файл с учетными данными...${RESET}"
        CREDENTIALS_FILE="/etc/samba/credentials"
        execute_command "mkdir -p /etc/samba" "Создание директории для учетных данных"
        
        cat > "$CREDENTIALS_FILE" << EOF
username=$SAMBA_USER
password=$SAMBA_PASS
EOF
        execute_command "chmod 600 $CREDENTIALS_FILE" "Защита файла с учетными данными"
        log_message "Файл с учетными данными создан: $CREDENTIALS_FILE"
    fi
    
    # Пробуем подключиться
    echo -e "${BLUE}Пробую подключиться к Samba-серверу...${RESET}"
    
    # Сначала проверяем доступность
    log_message "Проверка доступности Samba-сервера: $SAMBA_SERVER"
    if ping -c 2 $SAMBA_SERVER >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Сервер доступен${RESET}"
        log_message "Samba-сервер доступен: $SAMBA_SERVER"
    else
        echo -e "${RED}✗ Сервер недоступен${RESET}"
        log_message "Внимание: Samba-сервер недоступен: $SAMBA_SERVER"
    fi
    
    # Пробуем посмотреть доступные ресурсы
    echo -e "${BLUE}Ищу доступные ресурсы на сервере...${RESET}"
    log_message "Поиск доступных ресурсов на $SAMBA_SERVER"
    
    if [ "$SAMBA_USER" = "guest" ] || [ -z "$SAMBA_PASS" ]; then
        smbclient -L $SAMBA_SERVER -N >> "$LOG_FILE" 2>&1
    else
        smbclient -L $SAMBA_SERVER -U $SAMBA_USER%$SAMBA_PASS >> "$LOG_FILE" 2>&1
    fi
    
    # Настраиваем автоподключение в fstab
    echo -e "${BLUE}Настраиваю автоматическое подключение...${RESET}"
    
    # Удаляем старую запись для этой точки монтирования (если есть)
    grep -v " $MOUNT_POINT " /etc/fstab > /tmp/fstab.tmp && mv /tmp/fstab.tmp /etc/fstab
    
    # Добавляем новую запись
    FSTAB_ENTRY="//$SAMBA_SERVER/$SHARE_NAME $MOUNT_POINT cifs "
    
    if [ -n "$CREDENTIALS_FILE" ] && [ -f "$CREDENTIALS_FILE" ]; then
        FSTAB_ENTRY+="credentials=$CREDENTIALS_FILE,uid=$(id -u),gid=$(id -g),iocharset=utf8,file_mode=0777,dir_mode=0777 0 0"
    else
        FSTAB_ENTRY+="guest,uid=$(id -u),gid=$(id -g),iocharset=utf8,file_mode=0777,dir_mode=0777 0 0"
    fi
    
    echo "$FSTAB_ENTRY" >> /etc/fstab
    log_message "Добавлена запись в fstab: $FSTAB_ENTRY"
    
    # Пробуем монтировать
    echo -e "${BLUE}Пробую смонтировать ресурс...${RESET}"
    if mount $MOUNT_POINT 2>> "$LOG_FILE"; then
        echo -e "${GREEN}✓ Ресурс успешно смонтирован${RESET}"
        log_message "Samba-ресурс успешно смонтирован: //$SAMBA_SERVER/$SHARE_NAME -> $MOUNT_POINT"
        
        # Показываем информацию о монтировании
        echo -e "\n${YELLOW}Информация о подключении:${RESET}"
        df -h $MOUNT_POINT
    else
        echo -e "${RED}✗ Не удалось смонтировать ресурс${RESET}"
        log_message "Ошибка монтирования Samba-ресурса"
        echo -e "${YELLOW}Проверьте логи: ${LOG_FILE}${RESET}"
    fi
    
    # Создаем удобные ярлыки
    echo -e "${BLUE}Создаю ярлыки для быстрого доступа...${RESET}"
    
    # Создаем ссылку на рабочем столе
    DESKTOP_DIR="/home/$CURRENT_USER/Desktop"
    if [ -d "$DESKTOP_DIR" ]; then
        cat > "$DESKTOP_DIR/Samba-Share.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Link
Name=Samba Share
Comment=Подключенный Samba ресурс
URL=file://$MOUNT_POINT
Icon=folder-remote
EOF
        execute_command "chmod +x $DESKTOP_DIR/Samba-Share.desktop" "Создание ярлыка на рабочем столе"
    fi
    
    # Создаем скрипт для переподключения
    cat > /usr/local/bin/remount-samba.sh << EOF
#!/bin/bash
echo "Переподключение Samba-ресурса..."
umount $MOUNT_POINT 2>/dev/null
mount $MOUNT_POINT
if [ \$? -eq 0 ]; then
    echo "Ресурс успешно переподключен"
    ls $MOUNT_POINT
else
    echo "Ошибка переподключения"
fi
EOF
    
    execute_command "chmod +x /usr/local/bin/remount-samba.sh" "Создание скрипта переподключения"
    
    echo -e "\n${GREEN}✓ Настройка подключения к Samba завершена${RESET}"
    log_message "Настройка подключения к Samba завершена"
    
    echo -e "\n${YELLOW}Информация о подключении:${RESET}"
    echo -e "  Сервер: ${CYAN}$SAMBA_SERVER${RESET}"
    echo -e "  Ресурс: ${CYAN}$SHARE_NAME${RESET}"
    echo -e "  Пользователь: ${CYAN}$SAMBA_USER${RESET}"
    echo -e "  Локальная папка: ${CYAN}$MOUNT_POINT${RESET}"
    echo -e "  Ярлык: ${CYAN}~/Desktop/Samba-Share.desktop${RESET}"
    echo -e "  Команда переподключения: ${CYAN}remount-samba.sh${RESET}"
    
    # Записываем данные в лог (без пароля)
    log_message "Подключение к Samba: сервер=$SAMBA_SERVER, ресурс=$SHARE_NAME, пользователь=$SAMBA_USER, точка_монтирования=$MOUNT_POINT"
else
    log_message "Настройка подключения к Samba пропущена"
fi

###############################################################################
# ШАГ 5: НАСТРОЙКА БЕЗОПАСНОСТИ И МЕЖСЕТЕВОГО ЭКРАНА
###############################################################################
print_section "ШАГ 5: НАСТРОЙКА БЕЗОПАСНОСТИ"

# Межсетевой экран
if ask_yesno "Настроить межсетевой экран (ufw)?"; then
    log_message "Начинаю настройку межсетевого экрана"
    
    echo -e "${BLUE}Устанавливаю и настраиваю UFW...${RESET}"
    execute_command "apt-get install -y ufw" "Установка UFW"
    
    # Базовые правила
    echo -e "${BLUE}Настраиваю правила firewall...${RESET}"
    ufw default deny incoming >> "$LOG_FILE" 2>&1
    ufw default allow outgoing >> "$LOG_FILE" 2>&1
    
    # Разрешаем основные службы
    ufw allow ssh >> "$LOG_FILE" 2>&1
    ufw allow http >> "$LOG_FILE" 2>&1
    ufw allow https >> "$LOG_FILE" 2>&1
    ufw allow 445/tcp >> "$LOG_FILE" 2>&1  # Samba
    ufw allow 137:138/udp >> "$LOG_FILE" 2>&1  # NetBIOS
    ufw allow 139/tcp >> "$LOG_FILE" 2>&1  # SMB
    
    log_message "Правила UFW настроены"
    
    # Включаем firewall
    echo -e "${BLUE}Включаю firewall...${RESET}"
    ufw --force enable >> "$LOG_FILE" 2>&1
    
    echo -e "${GREEN}✓ Межсетевой экран настроен${RESET}"
    log_message "Межсетевой экран UFW включен"
    
    # Показываем статус
    echo -e "\n${BLUE}Статус firewall:${RESET}"
    ufw status verbose
else
    log_message "Настройка межсетевого экрана пропущена"
fi

# Настройка безопасности SSH
if ask_yesno "Настроить безопасность SSH?"; then
    log_message "Начинаю настройку безопасности SSH"
    
    echo -e "${BLUE}Настраиваю SSH...${RESET}"
    
    # Резервная копия конфигурации
    execute_command "cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup" "Создание резервной копии SSH конфигурации"
    
    # Безопасные настройки
    echo -e "${BLUE}Применяю безопасные настройки SSH...${RESET}"
    
    # Используем временный файл для изменений
    SSH_TEMP="/tmp/sshd_config.temp"
    cp /etc/ssh/sshd_config "$SSH_TEMP"
    
    # Применяем изменения
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' "$SSH_TEMP"
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' "$SSH_TEMP"
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' "$SSH_TEMP"
    sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' "$SSH_TEMP"
    sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' "$SSH_TEMP"
    sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 2/' "$SSH_TEMP"
    
    # Запрещаем пустые пароли
    echo "PermitEmptyPasswords no" >> "$SSH_TEMP"
    
    # Копируем обратно
    cp "$SSH_TEMP" /etc/ssh/sshd_config
    rm -f "$SSH_TEMP"
    
    log_message "Безопасные настройки SSH применены"
    
    # Перезапускаем SSH
echo -e "${BLUE}Проверяю конфигурацию SSH...${RESET}"
echo -e "${BLUE}Исправляю права на SSH ключи...${RESET}"
chmod 600 /etc/ssh/ssh_host_* 2>/dev/null || true
sshd -t >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    execute_command "systemctl restart sshd" "Перезапуск SSH службы"
else
    echo -e "${RED}Ошибка в конфигурации SSH. Восстанавливаю backup...${RESET}"
    log_message "Ошибка проверки SSH конфигурации, восстанавливаю backup"
    cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
    execute_command "systemctl restart sshd" "Перезапуск SSH службы (после восстановления)"
fi
    
    echo -e "${GREEN}✓ SSH защищен${RESET}"
    log_message "Безопасность SSH настроена"
    
    echo -e "${YELLOW}Вход по root отключен. Используйте обычных пользователей.${RESET}"
else
    log_message "Настройка безопасности SSH пропущена"
fi

###############################################################################
# ШАГ 6: ОГРАНИЧЕНИЯ ДЛЯ ПОЛЬЗОВАТЕЛЕЙ
###############################################################################
print_section "ШАГ 6: ОГРАНИЧЕНИЯ ДЛЯ УЧЕНИКОВ"

if ask_yesno "Установить ограничения для учеников?"; then
    log_message "Начинаю установку ограничений для учеников"
    
    echo -e "${BLUE}Создаю группы пользователей...${RESET}"
    execute_command "groupadd uchenik 2>/dev/null || true" "Создание группы uchenik"
    
    # 1. Запрещаем удаление системных программ
    echo -e "${BLUE}Настраиваю права на установку/удаление программ...${RESET}"
    
    # Создаем правило для sudoers
    SUDOERS_FILE="/etc/sudoers.d/uchenik-restrictions"
    cat > "$SUDOERS_FILE" << 'EOF'
# Запреты для учеников
%uchenik !/usr/bin/apt
%uchenik !/usr/bin/apt-get
%uchenik !/usr/bin/dpkg
%uchenik !/usr/bin/snap
%uchenik !/usr/bin/flatpak
%uchenik !/usr/bin/pip
%uchenik !/usr/bin/pip3
EOF
    
    execute_command "chmod 440 $SUDOERS_FILE" "Установка прав файла ограничений sudoers"
    log_message "Созданы ограничения sudoers для учеников"
    
    # 2. Запрещаем изменение сетевых настроек
    echo -e "${BLUE}Запрещаю изменение сетевых настроек...${RESET}"
    
    POLKIT_FILE="/etc/polkit-1/localauthority/50-local.d/network-uchenik.pkla"
    cat > "$POLKIT_FILE" << EOF
[NetworkManager permissions]
Identity=unix-group:uchenik
Action=org.freedesktop.NetworkManager.settings.modify.system
ResultAny=no
ResultInactive=no
ResultActive=no

[NetworkManager wifi permissions]
Identity=unix-group:uchenik
Action=org.freedesktop.NetworkManager.enable-disable-wifi
ResultAny=no
ResultInactive=no
ResultActive=no
EOF
    
    log_message "Созданы ограничения NetworkManager для учеников"
    
    # 3. Запрещаем просмотр паролей WiFi
    echo -e "${BLUE}Запрещаю просмотр паролей WiFi...${RESET}"
    chmod 600 /etc/NetworkManager/system-connections/* 2>/dev/null || true
    log_message "Установлены права на файлы WiFi конфигураций"
    
    # 4. Запрещаем изменение обоев рабочего стола
    echo -e "${BLUE}Запрещаю изменение обоев...${RESET}"
    sudo astra-admin /usr/bin/fly-admin-theme
    sudo chmod 750 /usr/bin/fly-admin-theme
    
    # Создаем стандартные обои
    echo -e "${BLUE}Создаю стандартные обои...${RESET}"
    WALLPAPER_DIR="/usr/share/backgrounds"
    execute_command "mkdir -p $WALLPAPER_DIR" "Создание директории для обоев"
    
    # Создаем простые обои
    WALLPAPER_FILE="$WALLPAPER_DIR/school-default.jpg"
    
    if command -v convert &> /dev/null; then
        convert -size 1920x1080 xc:"#1E3F66" \
            -fill white -pointsize 72 -draw "text 200,300 'ШКОЛЬНЫЙ КОМПЬЮТЕР'" \
            -pointsize 36 -draw "text 200,400 'Только для учебных целей'" \
            -pointsize 24 -draw "text 200,500 'Изменение настроек запрещено'" \
            "$WALLPAPER_FILE" >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Обои созданы${RESET}"
            log_message "Обои созданы с помощью ImageMagick"
        else
            echo -e "${YELLOW}⚠ Не удалось создать обои с ImageMagick${RESET}"
            log_message "Ошибка при создании обоев с ImageMagick"
            # Создаем текстовый файл как запасной вариант
            echo "ШКОЛЬНЫЙ КОМПЬЮТЕР - Только для учебных целей" > "$WALLPAPER_DIR/school-wallpaper.txt"
        fi
    else
        echo -e "${YELLOW}ImageMagick не установлен. Создаю текстовый файл...${RESET}"
        echo "ШКОЛЬНЫЙ КОМПЬЮТЕР" > "$WALLPAPER_DIR/school-wallpaper.txt"
        echo "Только для учебных целей" >> "$WALLPAPER_DIR/school-wallpaper.txt"
        echo "Изменение настроек запрещено" >> "$WALLPAPER_DIR/school-wallpaper.txt"
        log_message "Создан текстовый файл обоев (ImageMagick недоступен)"
    fi
    
    # 5. Ограничиваем доступ к системным файлам
    echo -e "${BLUE}Ограничиваю доступ к системным файлам...${RESET}"
    
    # Устанавливаем ACL если не установлены
    if ! command -v setfacl &> /dev/null; then
        execute_command "apt-get install -y acl" "Установка ACL"
    fi
    
    # Применяем ограничения
    setfacl -R -m g:uchenik:r-x /etc 2>> "$LOG_FILE" || true
    setfacl -R -m g:uchenik:r-x /usr 2>> "$LOG_FILE" || true
    setfacl -R -m g:uchenik:r-x /bin 2>> "$LOG_FILE" || true
    setfacl -R -m g:uchenik:r-x /sbin 2>> "$LOG_FILE" || true
    
    log_message "Ограничения доступа к системным файлам установлены"
        
    echo -e "${GREEN}✓ Ограничения установлены${RESET}"
    log_message "Все ограничения для учеников установлены"
    
    echo -e "\n${YELLOW}Установленные ограничения:${RESET}"
    echo -e "  ${GREEN}•${RESET} Запрет установки/удаления программ"
    echo -e "  ${GREEN}•${RESET} Запрет изменения сетевых настроек"
    echo -e "  ${GREEN}•${RESET} Запрет просмотра паролей WiFi"
    echo -e "  ${GREEN}•${RESET} Запрет изменения обоев"
    echo -e "  ${GREEN}•${RESET} Ограничен доступ к системным файлам"
    echo -e "  ${GREEN}•${RESET} Созданы стандартные обои"
else
    log_message "Установка ограничений для учеников пропущена"
fi

###############################################################################
# ЗАВЕРШЕНИЕ
###############################################################################
print_header
print_section "НАСТРОЙКА ЗАВЕРШЕНА"

# Записываем итоги в лог
log_message "=== ИТОГИ НАСТРОЙКИ ==="
log_message "Установлено категорий пакетов: ${#INSTALLED_CATEGORIES[@]}"
for category in "${INSTALLED_CATEGORIES[@]}"; do
    log_message "  - $category"
done
log_message "=== КОНЕЦ НАСТРОЙКИ ==="

echo -e "${GREEN}${BOLD}✓ Все выбранные настройки применены!${RESET}\n"

if [ ${#INSTALLED_CATEGORIES[@]} -gt 0 ]; then
    echo -e "${CYAN}${BOLD}Установленные категории:${RESET}"
    for category in "${INSTALLED_CATEGORIES[@]}"; do
        echo -e "  ${GREEN}•${RESET} $category"
    done
fi

echo -e "\n${YELLOW}${BOLD}Сводка:${RESET}"
echo -e "  ${BLUE}Полный лог настройки:${RESET} $LOG_FILE"
echo -e "  ${BLUE}Просмотр лога:${RESET} sudo cat $LOG_FILE"
echo -e "  ${BLUE}Последние 20 строк лога:${RESET} sudo tail -20 $LOG_FILE"
echo -e "  ${BLUE}Samba общие папки:${RESET} /samba/"
echo -e "  ${BLUE}Ограничения для учеников:${RESET} установлены"
echo -e "  ${BLUE}Межсетевой экран:${RESET} активен"
echo -e "  ${BLUE}Сеть WiFi:${RESET} настроена"

# Показываем последние строки лога для проверки
echo -e "\n${BLUE}Последние строки лога:${RESET}"
tail -5 "$LOG_FILE" | while IFS= read -r line; do
    echo -e "  ${CYAN}$line${RESET}"
done

echo -e "\n${PURPLE}${LINE}${RESET}"
if ask_yesno "Перезагрузить компьютер для применения всех изменений?"; then
    log_message "Пользователь выбрал перезагрузку"
    echo -e "${GREEN}Перезагружаюсь через 5 секунд...${RESET}"
    echo -e "${YELLOW}Для отмены нажмите Ctrl+C${RESET}"
    sleep 5
    log_message "Выполняется перезагрузка системы"
    reboot
else
    log_message "Пользователь отказался от перезагрузки"
    echo -e "${YELLOW}Для применения всех изменений выполните:${RESET}"
    echo -e "${CYAN}  sudo reboot${RESET}"
fi

if [ $ERRORS_OCCURRED -eq 1 ]; then
    echo -e "\n${RED}ВНИМАНИЕ: Во время настройки произошли ошибки!${RESET}"
    echo -e "Проверьте лог для деталей: ${CYAN}tail -50 $LOG_FILE${RESET}"
fi

echo -e "\n${GREEN}Настройка завершена!${RESET}"
echo -e "${YELLOW}Не забудьте проверить лог для деталей: ${CYAN}cat $LOG_FILE${RESET}"
