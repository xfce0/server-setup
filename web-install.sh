#!/bin/bash

# =====================================
# Server Setup Script
# Автоматическая настройка нового сервера
# =====================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_message() {
    echo -e "${2}${1}${NC}"
}

# Функция для проверки успешности команды
check_status() {
    if [ $? -eq 0 ]; then
        print_message "✓ $1" "$GREEN"
    else
        print_message "✗ $1" "$RED"
        exit 1
    fi
}

# Баннер
clear
echo -e "${CYAN}"
cat << "EOF"
 ____                             ____       _               
/ ___|  ___ _ ____   _____ _ __  / ___|  ___| |_ _   _ _ __  
\___ \ / _ \ '__\ \ / / _ \ '__| \___ \ / _ \ __| | | | '_ \ 
 ___) |  __/ |   \ V /  __/ |     ___) |  __/ |_| |_| | |_) |
|____/ \___|_|    \_/ \___|_|    |____/ \___|\__|\__,_| .__/ 
                                                       |_|    
EOF
echo -e "${NC}"

print_message "=====================================" "$BLUE"
print_message "   Начальная настройка сервера" "$BLUE"
print_message "=====================================" "$BLUE"
echo

# Проверка root прав
if [[ $EUID -ne 0 ]]; then
   print_message "⚠️  Рекомендуется запускать от имени root" "$YELLOW"
   echo "Продолжить без root прав? (некоторые функции могут быть недоступны) (y/n)"
   read -n 1 -r
   echo
   if [[ ! $REPLY =~ ^[Yy]$ ]]; then
       exit 1
   fi
   SUDO="sudo"
else
   SUDO=""
fi

# Определение дистрибутива
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    print_message "❌ Не удалось определить дистрибутив Linux" "$RED"
    exit 1
fi

print_message "📋 Система: $OS $VER" "$CYAN"
echo

# ====================================
# 1. Обновление системы
# ====================================
print_message "1️⃣  Обновление системы..." "$MAGENTA"
print_message "   Обновляю списки пакетов..." "$BLUE"

$SUDO apt update -qq 2>/dev/null
check_status "Списки пакетов обновлены"

print_message "   Обновляю установленные пакеты..." "$BLUE"
$SUDO apt upgrade -y -qq 2>/dev/null
check_status "Пакеты обновлены"

echo

# ====================================
# 2. Установка базовых утилит
# ====================================
print_message "2️⃣  Установка базовых утилит..." "$MAGENTA"

PACKAGES="curl wget git vim htop net-tools zip unzip tar gzip bzip2 xz-utils software-properties-common apt-transport-https ca-certificates gnupg lsb-release build-essential"

for package in $PACKAGES; do
    if dpkg -l | grep -q "^ii  $package "; then
        print_message "   ✓ $package уже установлен" "$GREEN"
    else
        print_message "   📦 Устанавливаю $package..." "$BLUE"
        $SUDO apt install -y -qq $package 2>/dev/null
        check_status "$package установлен"
    fi
done

echo

# ====================================
# 3. Установка Python и pip
# ====================================
print_message "3️⃣  Установка Python..." "$MAGENTA"

# Python3
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | grep -Po '(?<=Python )\d+\.\d+')
    print_message "   ✓ Python $PYTHON_VERSION уже установлен" "$GREEN"
else
    print_message "   📦 Устанавливаю Python3..." "$BLUE"
    $SUDO apt install -y -qq python3 2>/dev/null
    check_status "Python3 установлен"
fi

# pip
if command -v pip3 &> /dev/null; then
    PIP_VERSION=$(pip3 --version 2>&1 | grep -Po '\d+\.\d+' | head -1)
    print_message "   ✓ pip $PIP_VERSION уже установлен" "$GREEN"
else
    print_message "   📦 Устанавливаю pip3..." "$BLUE"
    $SUDO apt install -y -qq python3-pip 2>/dev/null
    check_status "pip3 установлен"
fi

# venv
print_message "   📦 Устанавливаю python3-venv..." "$BLUE"
$SUDO apt install -y -qq python3-venv 2>/dev/null
check_status "python3-venv установлен"

# dev пакеты для компиляции модулей
print_message "   📦 Устанавливаю python3-dev..." "$BLUE"
$SUDO apt install -y -qq python3-dev 2>/dev/null
check_status "python3-dev установлен"

echo

# ====================================
# 4. Настройка Vim
# ====================================
print_message "4️⃣  Настройка Vim..." "$MAGENTA"

# Бэкап существующего .vimrc
if [ -f "$HOME/.vimrc" ]; then
    BACKUP_FILE="$HOME/.vimrc.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$HOME/.vimrc" "$BACKUP_FILE"
    print_message "   📋 Создана резервная копия: $BACKUP_FILE" "$YELLOW"
fi

# Установка конфигурации Vim
print_message "   📝 Устанавливаю конфигурацию Vim..." "$BLUE"

cat > "$HOME/.vimrc" << 'VIMRC_EOF'
" =====================================
" Удобная конфигурация Vim для сервера
" =====================================

" Основные настройки
set nocompatible              " Отключить совместимость с vi
set encoding=utf-8            " UTF-8 по умолчанию
set fileencoding=utf-8
set termencoding=utf-8

" Нумерация строк
set number                    " Показывать номера строк
set norelativenumber         " Отключить относительную нумерацию

" Работа с мышью
set mouse=a                   " Включить поддержку мыши во всех режимах
set ttymouse=sgr              " Поддержка мыши в больших терминалах
set selectmode=mouse          " Выделение мышью

" Отображение
syntax on                     " Подсветка синтаксиса
set title                     " Показывать имя файла в заголовке окна
set ruler                     " Показывать позицию курсора
set showcmd                   " Показывать вводимые команды
set showmode                  " Показывать текущий режим
set laststatus=2              " Всегда показывать статусную строку
set wildmenu                  " Автодополнение команд
set wildmode=list:longest,full

" Красивая статусная строка с информацией о файле
set statusline=
set statusline+=%#PmenuSel#
set statusline+=\ %{mode()}\ 
set statusline+=%#LineNr#
set statusline+=\ %F            " Полный путь к файлу
set statusline+=\ %m             " Модифицирован?
set statusline+=\ %r             " Только для чтения?
set statusline+=%=               " Переход на правую сторону
set statusline+=%#CursorColumn#
set statusline+=\ %Y             " Тип файла
set statusline+=\ [%{&fileencoding?&fileencoding:&encoding}]
set statusline+=\ [%{&fileformat}]
set statusline+=\ %p%%           " Процент в файле
set statusline+=\ %l:%c          " Строка:Колонка
set statusline+=\ 

" Поиск
set hlsearch                  " Подсвечивать результаты поиска
set incsearch                 " Инкрементальный поиск
set ignorecase                " Игнорировать регистр при поиске
set smartcase                 " Умный поиск с учётом регистра

" Отступы и табуляция
set expandtab                 " Пробелы вместо табов
set tabstop=4                 " Размер табуляции
set shiftwidth=4              " Размер отступа
set softtabstop=4
set autoindent                " Автоотступ
set smartindent               " Умные отступы

" Редактирование
set backspace=indent,eol,start " Нормальная работа backspace
set clipboard=unnamed         " Использовать системный буфер обмена
if has('unnamedplus')
    set clipboard+=unnamedplus
endif

" Визуальные подсказки
set cursorline                " Подсветка текущей строки
" set colorcolumn=80          " Вертикальная линия на 80 символе (отключено)
set wrap                      " Перенос длинных строк
set linebreak                 " Перенос по словам

" История и бэкапы
set history=1000              " Большая история команд
set undolevels=1000           " Много уровней отмены
set nobackup                  " Не создавать резервные копии
set noswapfile                " Не создавать swap файлы

" Удобные сочетания клавиш
" Ctrl+C для копирования в визуальном режиме
vnoremap <C-c> "+y
" Ctrl+V для вставки в режиме вставки
inoremap <C-v> <Esc>"+pa
" Ctrl+X для вырезания в визуальном режиме
vnoremap <C-x> "+d
" Delete для удаления выделенного
vnoremap <Del> d
vnoremap <BS> d

" Ctrl+A для выделения всего
nnoremap <C-a> ggVG

" Сохранение через Ctrl+S
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>a

" Выход через Ctrl+Q
nnoremap <C-q> :q<CR>
inoremap <C-q> <Esc>:q<CR>

" Отмена через Ctrl+Z
nnoremap <C-z> u
inoremap <C-z> <Esc>ui

" Повтор через Ctrl+Y
nnoremap <C-y> <C-r>
inoremap <C-y> <Esc><C-r>i

" Навигация между окнами с Ctrl+стрелки
nnoremap <C-Left> <C-w>h
nnoremap <C-Down> <C-w>j
nnoremap <C-Up> <C-w>k
nnoremap <C-Right> <C-w>l

" Более удобная навигация по длинным строкам
nnoremap j gj
nnoremap k gk

" Быстрое перемещение между ошибками
nnoremap <F8> :cnext<CR>
nnoremap <F7> :cprev<CR>

" Очистка подсветки поиска по Esc
nnoremap <Esc> :noh<CR><Esc>

" Автокоманды
augroup vimrc
    autocmd!
    " Возврат на последнюю позицию при открытии файла
    autocmd BufReadPost *
        \ if line("'\"") > 0 && line("'\"") <= line("$") |
        \   exe "normal! g'\"" |
        \ endif
    " Автоматическое удаление пробелов в конце строк при сохранении
    autocmd BufWritePre * :%s/\s\+$//e
augroup END

" Цветовая схема (если доступна)
silent! colorscheme desert
set background=dark

" Включить 256 цветов в терминале
if &term =~ '256color'
    set t_Co=256
endif

" Подсветка лишних пробелов
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

" Файловый браузер netrw
let g:netrw_banner = 0       " Скрыть баннер
let g:netrw_liststyle = 3    " Древовидное отображение
let g:netrw_browse_split = 4 " Открывать в предыдущем окне
let g:netrw_winsize = 20      " Размер окна браузера

" Ctrl+O для переключения файлового браузера
nnoremap <C-o> :Lexplore<CR>

" F3 для переключения режима вставки/замены
set pastetoggle=<F3>

" Улучшенное автодополнение
set completeopt=menu,menuone,noselect

" Показывать непечатаемые символы
set list
set listchars=tab:→\ ,trail:·,extends:›,precedes:‹,nbsp:·

" Плавная прокрутка
set scrolloff=8               " Минимум строк сверху/снизу от курсора
set sidescrolloff=15          " Минимум символов слева/справа

" Сообщения
set shortmess+=c              " Не показывать сообщения о дополнении

" Включить matchit для улучшенного % навигации
runtime macros/matchit.vim
VIMRC_EOF

check_status "Конфигурация Vim установлена"

# Создание директорий Vim
mkdir -p "$HOME/.vim/"{autoload,backup,colors,plugged}
check_status "Директории Vim созданы"

echo

# ====================================
# 5. Настройка часового пояса
# ====================================
print_message "5️⃣  Настройка часового пояса..." "$MAGENTA"

CURRENT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
print_message "   Текущий часовой пояс: $CURRENT_TZ" "$CYAN"

echo "   Хотите изменить часовой пояс? (y/n)"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_message "   Популярные часовые пояса:" "$BLUE"
    echo "     1) UTC"
    echo "     2) Europe/Moscow"
    echo "     3) Europe/London"
    echo "     4) America/New_York"
    echo "     5) Asia/Shanghai"
    echo "     6) Ввести свой"
    
    read -p "   Выберите (1-6): " tz_choice
    
    case $tz_choice in
        1) NEW_TZ="UTC" ;;
        2) NEW_TZ="Europe/Moscow" ;;
        3) NEW_TZ="Europe/London" ;;
        4) NEW_TZ="America/New_York" ;;
        5) NEW_TZ="Asia/Shanghai" ;;
        6) read -p "   Введите часовой пояс (например, Europe/Moscow): " NEW_TZ ;;
        *) NEW_TZ="" ;;
    esac
    
    if [ ! -z "$NEW_TZ" ]; then
        $SUDO timedatectl set-timezone "$NEW_TZ" 2>/dev/null
        check_status "Часовой пояс изменен на $NEW_TZ"
    fi
fi

echo

# ====================================
# 6. Настройка файрвола (опционально)
# ====================================
print_message "6️⃣  Настройка файрвола..." "$MAGENTA"

if command -v ufw &> /dev/null; then
    UFW_STATUS=$($SUDO ufw status | grep -o "^Status: .*" | cut -d' ' -f2)
    if [ "$UFW_STATUS" = "active" ]; then
        print_message "   ✓ UFW уже активен" "$GREEN"
    else
        echo "   Активировать UFW файрвол? (y/n)"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Разрешаем SSH перед включением
            $SUDO ufw allow ssh 2>/dev/null
            check_status "SSH порт открыт"
            
            $SUDO ufw --force enable 2>/dev/null
            check_status "UFW активирован"
            
            print_message "   ℹ️  Не забудьте открыть нужные порты:" "$YELLOW"
            echo "     sudo ufw allow 80/tcp    # HTTP"
            echo "     sudo ufw allow 443/tcp   # HTTPS"
            echo "     sudo ufw allow 3000/tcp  # Custom port"
        fi
    fi
else
    print_message "   ℹ️  UFW не установлен" "$YELLOW"
fi

echo

# ====================================
# 7. Создание пользователя (опционально)
# ====================================
print_message "7️⃣  Настройка пользователей..." "$MAGENTA"

echo "   Создать нового пользователя? (y/n)"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "   Имя пользователя: " NEW_USER
    
    if id "$NEW_USER" &>/dev/null; then
        print_message "   ⚠️  Пользователь $NEW_USER уже существует" "$YELLOW"
    else
        $SUDO adduser --gecos "" "$NEW_USER"
        check_status "Пользователь $NEW_USER создан"
        
        echo "   Добавить пользователя в sudo группу? (y/n)"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            $SUDO usermod -aG sudo "$NEW_USER"
            check_status "$NEW_USER добавлен в sudo группу"
        fi
        
        # Копирование конфигурации Vim для нового пользователя
        $SUDO cp "$HOME/.vimrc" "/home/$NEW_USER/.vimrc"
        $SUDO chown "$NEW_USER:$NEW_USER" "/home/$NEW_USER/.vimrc"
        $SUDO mkdir -p "/home/$NEW_USER/.vim/"{autoload,backup,colors,plugged}
        $SUDO chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER/.vim"
        check_status "Конфигурация Vim скопирована для $NEW_USER"
    fi
fi

echo

# ====================================
# 8. Установка Docker (опционально)
# ====================================
print_message "8️⃣  Docker..." "$MAGENTA"

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | grep -Po '\d+\.\d+\.\d+' | head -1)
    print_message "   ✓ Docker $DOCKER_VERSION уже установлен" "$GREEN"
else
    echo "   Установить Docker? (y/n)"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message "   📦 Устанавливаю Docker..." "$BLUE"
        
        # Установка зависимостей
        $SUDO apt install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release 2>/dev/null
        
        # Добавление GPG ключа Docker
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Добавление репозитория Docker
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Установка Docker
        $SUDO apt update -qq 2>/dev/null
        $SUDO apt install -y -qq docker-ce docker-ce-cli containerd.io 2>/dev/null
        
        # Добавление текущего пользователя в группу docker
        $SUDO usermod -aG docker $USER
        
        check_status "Docker установлен"
        print_message "   ℹ️  Перелогиньтесь для применения прав docker группы" "$YELLOW"
        
        # Docker Compose
        echo "   Установить Docker Compose? (y/n)"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            $SUDO apt install -y -qq docker-compose-plugin 2>/dev/null
            check_status "Docker Compose установлен"
        fi
    fi
fi

echo

# ====================================
# 9. Финальная информация
# ====================================
print_message "=====================================" "$GREEN"
print_message "    ✨ Настройка завершена! ✨" "$GREEN"
print_message "=====================================" "$GREEN"
echo

print_message "📊 Установленные компоненты:" "$CYAN"
echo

# Проверка установленных компонентов
[ -f "$HOME/.vimrc" ] && print_message "   ✓ Vim настроен" "$GREEN"
command -v python3 &>/dev/null && print_message "   ✓ Python $(python3 --version 2>&1 | grep -Po '\d+\.\d+')" "$GREEN"
command -v pip3 &>/dev/null && print_message "   ✓ pip $(pip3 --version 2>&1 | grep -Po '\d+\.\d+' | head -1)" "$GREEN"
command -v git &>/dev/null && print_message "   ✓ Git $(git --version | grep -Po '\d+\.\d+')" "$GREEN"
command -v docker &>/dev/null && print_message "   ✓ Docker $(docker --version | grep -Po '\d+\.\d+\.\d+' | head -1)" "$GREEN"
command -v zip &>/dev/null && print_message "   ✓ zip/unzip" "$GREEN"

echo
print_message "💡 Полезные команды:" "$BLUE"
echo "   vim            - Редактор с новыми настройками"
echo "   Ctrl+O         - Файловый менеджер в Vim"
echo "   python3 -m venv venv - Создать виртуальное окружение"
echo "   htop           - Мониторинг системы"
echo "   sudo ufw status - Статус файрвола"
echo

print_message "🚀 Сервер готов к работе!" "$GREEN"
echo

# Предложение перезагрузки
echo "Рекомендуется перезагрузить сервер. Перезагрузить сейчас? (y/n)"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_message "Перезагрузка через 5 секунд..." "$YELLOW"
    sleep 5
    $SUDO reboot
fi