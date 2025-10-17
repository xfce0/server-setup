# Server Setup Scripts

Скрипты для автоматической установки и настройки сервера.

## 🚀 Быстрая установка CRM

Для автоматической установки CRM системы на Ubuntu сервер выполните:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/xfce0/server-setup/main/web-install.sh)
```

### Что делает скрипт:

1. ✅ Обновляет систему Ubuntu
2. ✅ Устанавливает Node.js v22.18.0 через NVM
3. ✅ Устанавливает Docker и Docker Compose
4. ✅ Клонирует репозиторий CRM
5. ✅ Запускает локальный Supabase
6. ✅ Устанавливает зависимости проекта
7. ✅ Собирает проект
8. ✅ Настраивает PM2 для автозапуска
9. ✅ (Опционально) Настраивает Nginx

### Требования:

- Ubuntu 20.04 или выше
- Права sudo
- Интернет соединение

### После установки:

Приложение будет доступно по адресу:
- С Nginx: `http://your-server-ip`
- Без Nginx: `http://your-server-ip:5173`

Supabase Dashboard: `http://localhost:54323`

### Полезные команды:

```bash
pm2 logs crm         # Просмотр логов
pm2 restart crm      # Перезапуск приложения
pm2 stop crm         # Остановка приложения
pm2 monit            # Мониторинг
supabase status      # Статус Supabase
```

### Обновление приложения:

```bash
cd ~/crm-nik/atomic-crm
git pull
npm install
npm run build
pm2 restart crm
```

## 📝 Ручная установка

Если хотите установить вручную, следуйте инструкциям в [документации](https://github.com/xfce0/crm-nik).

## 🐛 Проблемы

Если после установки Docker не работает:

1. Выйдите из SSH сессии: `exit`
2. Войдите снова: `ssh user@server`
3. Перейдите в проект: `cd ~/crm-nik/atomic-crm`
4. Запустите Supabase: `supabase start`
5. Перезапустите PM2: `pm2 restart crm`

## 📄 Лицензия

MIT
