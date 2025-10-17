#!/bin/bash

# Скрипт автоматической установки CRM на Ubuntu сервер
# Использование: bash <(curl -fsSL https://raw.githubusercontent.com/xfce0/server-setup/main/web-install.sh)

set -e  # Остановить выполнение при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

# Проверка что скрипт запущен на Ubuntu
if [ ! -f /etc/lsb-release ]; then
    print_error "Этот скрипт предназначен для Ubuntu"
    exit 1
fi

print_header "🚀 Установка CRM системы на Ubuntu"

# 1. Обновление системы
print_header "📦 Обновление системы"
sudo apt update
sudo apt upgrade -y

# 2. Установка базовых зависимостей
print_header "📚 Установка базовых зависимостей"
sudo apt install -y curl wget git build-essential

# 3. Установка NVM и Node.js 22.18.0
print_header "📦 Установка Node.js v22.18.0"
if [ ! -d "$HOME/.nvm" ]; then
    print_message "Установка NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
fi

# Активация NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Установка Node.js
print_message "Установка Node.js 22.18.0..."
nvm install 22.18.0
nvm use 22.18.0
nvm alias default 22.18.0

print_message "Node.js версия: $(node --version)"
print_message "NPM версия: $(npm --version)"

# 4. Установка Docker
print_header "🐳 Установка Docker"
if ! command -v docker &> /dev/null; then
    print_message "Установка Docker..."
    sudo apt install -y docker.io docker-compose
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    print_message "Docker установлен"
else
    print_message "Docker уже установлен"
fi

# 5. Клонирование репозитория
print_header "📥 Клонирование репозитория CRM"
cd ~
if [ -d "crm-nik" ]; then
    print_warning "Директория crm-nik уже существует. Обновляю репозиторий..."
    cd crm-nik/atomic-crm
    git pull
else
    print_message "Клонирую репозиторий..."
    git clone https://github.com/xfce0/crm-nik.git
    cd crm-nik/atomic-crm
fi

# 6. Установка глобальных зависимостей
print_header "🌐 Установка глобальных пакетов"
npm install -g supabase pm2

# 7. Проверка Docker прав
print_message "Проверка прав Docker..."
if ! docker ps &> /dev/null; then
    print_warning "Необходимо перелогиниться для применения прав Docker"
    print_warning "После перелогина выполните:"
    echo -e "${YELLOW}cd ~/crm-nik/atomic-crm && supabase start${NC}"
fi

# 8. Запуск Supabase
print_header "🗄️ Запуск Supabase"
print_message "Запуск локального Supabase..."
if docker ps &> /dev/null; then
    supabase start

    # Сохранить конфигурацию
    print_message "Сохранение конфигурации Supabase..."
    SUPABASE_URL=$(supabase status | grep "API URL" | awk '{print $3}')
    SUPABASE_ANON_KEY=$(supabase status | grep "anon key" | awk '{print $3}')

    # Создать .env файл
    cat > .env << EOF
VITE_SUPABASE_URL=$SUPABASE_URL
VITE_SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
EOF

    print_message "Конфигурация сохранена в .env"
else
    print_warning "Не удалось запустить Supabase (нет прав Docker)"
    print_warning "Перелогинтесь и выполните: cd ~/crm-nik/atomic-crm && supabase start"
fi

# 9. Установка зависимостей проекта
print_header "📦 Установка зависимостей проекта"
npm install

# 10. Сборка проекта
print_header "🔨 Сборка проекта"
npm run build

# 11. Настройка PM2
print_header "⚙️ Настройка автозапуска"
pm2 delete crm 2>/dev/null || true  # Удалить старый процесс если есть

# Определить какую команду запускать
if [ -f ".env" ]; then
    print_message "Запуск в режиме разработки..."
    pm2 start "npm run dev -- --host" --name crm
else
    print_warning "Файл .env не найден. Необходимо настроить Supabase вручную"
    print_message "Запуск собранной версии..."
    npm install -g serve
    pm2 start "serve -s dist -l 3000" --name crm
fi

pm2 save
pm2 startup | tail -1 | bash

# 12. Установка Nginx (опционально)
print_header "🌐 Настройка Nginx (опционально)"
read -p "Хотите установить Nginx? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt install -y nginx

    # Создать конфигурацию Nginx
    sudo tee /etc/nginx/sites-available/crm > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:5173;  # Для режима разработки
        # proxy_pass http://localhost:3000;  # Для production (serve)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

    sudo ln -sf /etc/nginx/sites-available/crm /etc/nginx/sites-enabled/crm
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo nginx -t && sudo systemctl restart nginx
    sudo systemctl enable nginx

    print_message "Nginx настроен и запущен"
fi

# 13. Финальная информация
print_header "✅ Установка завершена!"
echo ""
print_message "CRM система установлена и запущена!"
echo ""
echo -e "${GREEN}Информация о запущенных сервисах:${NC}"
echo ""

if [ -f ".env" ]; then
    supabase status
fi

echo ""
echo -e "${GREEN}PM2 процессы:${NC}"
pm2 list

echo ""
echo -e "${BLUE}Полезные команды:${NC}"
echo -e "  ${YELLOW}pm2 logs crm${NC}         - Просмотр логов"
echo -e "  ${YELLOW}pm2 restart crm${NC}      - Перезапуск приложения"
echo -e "  ${YELLOW}pm2 stop crm${NC}         - Остановка приложения"
echo -e "  ${YELLOW}pm2 monit${NC}            - Мониторинг в реальном времени"
echo -e "  ${YELLOW}supabase status${NC}      - Статус Supabase"
echo -e "  ${YELLOW}supabase stop${NC}        - Остановка Supabase"
echo ""
echo -e "${GREEN}Приложение доступно по адресу:${NC}"

# Определить IP адрес сервера
SERVER_IP=$(hostname -I | awk '{print $1}')
if command -v nginx &> /dev/null && systemctl is-active --quiet nginx; then
    echo -e "  ${BLUE}http://$SERVER_IP${NC}"
    echo -e "  ${BLUE}http://localhost${NC} (если на локальной машине)"
else
    echo -e "  ${BLUE}http://$SERVER_IP:5173${NC} (режим разработки)"
    echo -e "  ${BLUE}http://localhost:5173${NC} (если на локальной машине)"
fi

echo ""
echo -e "${GREEN}Supabase Dashboard:${NC}"
if [ -f ".env" ]; then
    echo -e "  ${BLUE}http://localhost:54323${NC}"
fi

echo ""
print_warning "ВАЖНО: Если Docker не запустился, выполните:"
echo -e "  ${YELLOW}1. Выйдите из сессии: exit${NC}"
echo -e "  ${YELLOW}2. Войдите снова: ssh user@server${NC}"
echo -e "  ${YELLOW}3. Перейдите в проект: cd ~/crm-nik/atomic-crm${NC}"
echo -e "  ${YELLOW}4. Запустите Supabase: supabase start${NC}"
echo -e "  ${YELLOW}5. Перезапустите PM2: pm2 restart crm${NC}"

echo ""
print_header "🎉 Готово! Удачи!"
