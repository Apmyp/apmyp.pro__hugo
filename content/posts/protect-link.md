---
title: "Защити свои ссылки и пользователей"
date: 2018-12-15T13:24:02+03:00
categories: ["development"]
description: "Добавь рел и спи спокойно"
---

Надо выработать новую привычку. Добавлять ко внешним ссылкам не только target=_blank, но и rel=noopener noreferrer. Так внешние сайты не смогут сделать плохо.

```
<a 
  href="https://external.link"
  target="_blank"
  rel="noopener noreferrer"
>
Внешняя ссылка
</a>
```

Подробнее  
{{< l "Почему опасно не добавляет правильный rel?" "https://github.com/iammerrick/unvalidated-redirects-example" >}}