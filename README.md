# 🚀 Server Setup Script

Автоматическая настройка нового Linux сервера одной командой.

## ⚡ Быстрая установка

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ВАШ_USERNAME/server-setup/main/web-install.sh)
```

или через wget:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/ВАШ_USERNAME/server-setup/main/web-install.sh)
```

## 📦 Что устанавливается

### Обязательные компоненты:
- ✅ **Обновление системы** - apt update & upgrade
- ✅ **Базовые утилиты** - curl, wget, git, vim, htop, zip, unzip и др.
- ✅ **Python 3** - с pip и venv для виртуальных окружений
- ✅ **Vim** - с удобной конфигурацией для работы

### Опциональные компоненты:
- 🐳 **Docker** и Docker Compose
- 🔥 **UFW Firewall** - базовая настройка файрвола
- 👤 **Создание пользователя** - с sudo правами
- 🕐 **Часовой пояс** - настройка timezone

## 🎯 Особенности

- **Интерактивная установка** - выбирайте что устанавливать
- **Безопасность** - автоматическое создание резервных копий конфигураций
- **Совместимость** - работает на Ubuntu/Debian системах
- **Умная установка** - пропускает уже установленные компоненты

## 📋 Требования

- Ubuntu 20.04+ или Debian 10+
- Доступ к интернету
- Root права или sudo (рекомендуется)

## 🛠️ Ручная установка

Если автоматическая установка не работает:

1. Скачайте скрипт:
```bash
wget https://raw.githubusercontent.com/ВАШ_USERNAME/server-setup/main/web-install.sh
```

2. Сделайте исполняемым:
```bash
chmod +x web-install.sh
```

3. Запустите:
```bash
sudo ./web-install.sh
```

## ⌨️ Vim горячие клавиши

После установки в Vim будут доступны:

| Комбинация | Действие |
|------------|----------|
| **Ctrl+S** | Сохранить файл |
| **Ctrl+Q** | Выйти из Vim |
| **Ctrl+O** | Файловый менеджер |
| **Ctrl+C** | Копировать выделенное |
| **Ctrl+V** | Вставить из буфера |
| **Ctrl+X** | Вырезать выделенное |
| **Ctrl+A** | Выделить всё |
| **Ctrl+Z** | Отменить действие |

## 🔧 После установки

### Python виртуальное окружение:
```bash
python3 -m venv myenv
source myenv/bin/activate
```

### Docker (если установлен):
```bash
docker run hello-world
docker compose version
```

### Файрвол (если активирован):
```bash
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## 📝 Проверка установленных компонентов

```bash
python3 --version
pip3 --version
vim --version
docker --version
git --version
```

## 🆘 Решение проблем

### Если скрипт не запускается:
- Проверьте подключение к интернету
- Убедитесь что у вас Ubuntu/Debian система
- Запустите с правами root: `sudo bash web-install.sh`

### Если Python модули не устанавливаются:
```bash
sudo apt install python3-dev build-essential
```

### Если Docker не работает:
- Перелогиньтесь после установки (для применения прав группы)
- Или выполните: `newgrp docker`

## 📄 Лицензия

Свободное использование

## 🤝 Вклад

Приветствуются pull requests и issues!

---

**Замените `ВАШ_USERNAME` на ваш реальный GitHub username перед загрузкой!**