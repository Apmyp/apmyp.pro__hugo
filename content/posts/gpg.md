---
date: 2021-05-26T11:38:49+03:00
title: "Как сделать коммиты зелененькими в Гитхабе"
categories: ["development"]
description: "Пара GPG ключей поможет в этом"
og_image: "/images/gpg/og_image.png"
twitter_og_image: "/images/gpg/twitter_og_image.png"
---

GPG — это софт для создания электронных цифровых подписей. С помощью ассиметричной пары ключей мы можем зашифровать любое сообщение. Публичными ключами можно обмениваться, а приватные надо держать под защитой. Стандартная схема.

И вот если поделится публичным ключом с Гитхабом и подписывать свои коммиты, то они в интерфейсе будут зелеными, будут Verified.

![](/images/gpg/github-screenshot.png)

## Как сгенерить пару GPG ключей
Оставлю основные команды. Это не инструкция, а шпаргалка. Действуй на свой страх и риск :)

Посмотреть на все локальные ключи

{{< highlight go >}}
$ gpg --list-keys
{{< /highlight >}}

Сгенерить ключ

{{< highlight go >}}
$ gpg --full-generate-key
{{< /highlight >}}

Редактировать ключ

{{< highlight go >}}
$ gpg --edit-key your-email-goes-here@gmail.com
{{< /highlight >}}

### Режим редактирования 
Это своя маленькая консоль со своими правилами.

Список частей ключа

{{< highlight go >}}
gpg> list
{{< /highlight >}}

Выбрать часть ключа

{{< highlight go >}}
gpg> key 0
{{< /highlight >}}

Изменить срок жизни части ключа

{{< highlight go >}}
gpg> expire
{{< /highlight >}}

Когда наигрались в этой консоли, надо все сохранить
{{< highlight go >}}
gpg> save
{{< /highlight >}}

### Копируем ключ для Гитхаба
Наконец можно и сам ключ скопировать

{{< highlight go >}}
$ gpg --export -a your-email-goes-here@gmail.com | pbcopy
{{< /highlight >}}

Вы великолепны!

## Автоматическая подпись
Короче, шоб не вспоминать как это и зачем это, можно настроить клиент Гита таким образом, чтобы он сам все подписывал

Редактируем файл ~/.gitconfig
```
[user]
  name = Arthur Bordenyuk
  email = your-email-goes-here@gmail.com
  signingkey = your-email-goes-here@gmail.com

[commit]
  gpgsign = true

[tag]
  gpgSign = true

```

## Макос
Иногда в Макосе стандартная хренатень тупит и ее надо рестартить. Вот моя секретная команда, которая спасает

{{< highlight go >}}
$ killall gpg-agent && gpg-agent --daemon --use-standard-socket --pinentry-program /usr/local/bin/pinentry
{{< /highlight >}}
