# NGINX.Unit
Подробные инструкции по установке по адресу: https://unit.nginx.org/installation/

1. Скачиваем ключ

```bash
   $ sudo curl --output /usr/share/keyrings/nginx-keyring.gpg  \
      https://unit.nginx.org/keys/nginx-keyring.gpg
```

2. Создаём файл `/etc/apt/sources.list.d/unit.list` со следующим содержимым:

```bash
   deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ jammy unit
   deb-src [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ jammy unit
```

3. Устанавливаем NGINX.Unit:

```bash
   sudo apt update
   sudo apt install unit unit-dev unit-python3.10
   sudo systemctl restart unit
```
