---
title: "Миграция Laravel сессий из БД в Редис"
date: 2020-06-13T13:43:12+03:00
categories: ["development"]
description: "Сессии в базе — плохая идея. Решил вопрос одной командой и оставил её в блоге, чтобы не забыть как это делается"
og_image: "/images/laravel-migrate-session-database-to-redis/og_image.png"
twitter_og_image: "/images/laravel-migrate-session-database-to-redis/twitter_og_image.png"
---

Обычный, казалось бы, день начался с сообщений Датадога. Увеличилось среднее время ответа нашего приложения. Покопавшись логах я понял, что дело в базе и таблице сессий. Только когда нагрузка растет вспоминаешь, что работать с сессиями в базе плохая идея.

Мы не хотели терять активных пользователей и решили найти способ, как всё починить и оставить людей в их аккаунтах.

Готово решения я найти не смог. Штош, проблемы изобрели, теперь их стоит решить.

## Собираем информацию

Покопавшись во внутренностях работы стандартного модуля сессии я нашел пару интересных штук.

### Как закодированы сессии в базе и Редисе?

![](/images/laravel-migrate-session-database-to-redis/laravel-db-redis.jpg)

Когда из БД извлекаем сессию, делаем base64_decode

{{< highlight php5 "linenos=table" >}}
<?php // \Illuminate\Session\DatabaseSessionHandler

public function read($sessionId)
{
    $session = (object) $this->getQuery()->find($sessionId);
    // ...
    if (isset($session->payload)) {
        // ...
        return base64_decode($session->payload);
    }

    return '';
}
{{< / highlight >}}

А когда из cache based — делаем unserialize

{{< highlight php5 "linenos=table" >}}
<?php // \Illuminate\Session\CacheBasedSessionHandler

public function read($sessionId)
{
    return $this->cache->get($sessionId, '');
}
{{< / highlight >}}

{{< highlight php5 "linenos=table" >}}
<?php // \Illuminate\Cache\DatabaseStore

public function get($key)
{
    $prefixed = $this->prefix.$key;
    // ...
    return $this->unserialize($cache->value);
}
{{< / highlight >}}

### Как хранятся сессии в Редисе?

Теперь надо понять в каком виде сессии хранятся в Редисе. Пришлось локально поставить Редис как драйвер сессий. У каждой сессии свой ключ в формате `laravel:%session_id%`. А то что значение этого ключа — сериализованный ПХП пэйлод, мы узнали чуть раньше при погружении в кишки Ларавела.

План вышел таким. Даже не знаю чего я ожидал :)

- Выделить под сессии базу в Редисе, чтобы изолировать данные
- Перенести сессии из БД в Редис с учетом кодирования
- Поменять драйвер

## Реализуем миграцию 
### Выделяем под сессии базу в Редисе

Имя базы в Редисе — это целое число от 1 до 16. Я этого не знал и бахнул 99. Пришлось погуглить почему же оно не работает :)

{{< highlight php5 "linenos=table" >}}
<?php // config/databases.php

'redis' => [
  // ...
  'sessions' => [
    'host' => env('REDIS_HOST', '127.0.0.1'),
    'password' => env('REDIS_PASSWORD', null),
    'port' => env('REDIS_PORT', 6379),
    'database' => 13,
  ],
]
{{< / highlight >}}

Проверяем как надо менять драйвер и соединение.

{{< highlight php5 "linenos=table" >}}
<?php // config/session.php

'driver' => env('SESSION_DRIVER', 'file'),
// ...
'connection' => env('SESSION_CONNECTION', null),
{{< / highlight >}}

### Переносим сессии из БД в Редис

Команда по миграции вышла небольшой, но делает команда несколько вещей:

- Декодирует base64 сессии из БД
- Сериализует сессии стандартным ПХП serialize
- Формирует команды на добавления новых ключей в Редисе

В Редис команда не пишет, она читает из БД и выводит много SET-ов. Не забудь подрубить команду в консольном Кернеле.

{{< highlight php5 "linenos=table" >}}
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class SessionDatabaseToRedis extends Command
{
    protected $signature = 'sessions:migrate_database_to_redis';
    protected $description = 'Переносит сессии из базы в редис, лайк э про';
    
    public function handle()
    {
        DB::table('sessions')->chunkById(1000, function($sessions) {
            foreach ($sessions as $session) {
                $sessionID = $session->id;
                $sessionData = serialize(base64_decode($session->payload));

                echo "*3\r\n$3\r\nSET\r\n$" . (strlen($sessionID) + 8) . "\r\nlaravel:" . $sessionID . "\r\n$" . strlen($sessionData) . "\r\n" . $sessionData . "\r\n";
            }
        });

        return 0;
    }
}
{{< / highlight >}}

Наконец-то мигрируем! Правда надо вспомнить номер базы, которую выделили в Редисе под сессии. В моём примере это 13.

Запускаем царскую команду и кайфуем:

{{< highlight bash >}}
$ php artisan sessions:migrate_database_to_redis | redis-cli -n 13 --pipe
{{< / highlight >}}

Команда выводит SET-ы, мы их подсовываем Редису с выбранной правильной базой.

### Меняем драйвер

Настраиваем переменные окружения и чистим кеш.

{{< highlight bash >}}
# .env
SESSION_DRIVER=redis
SESSION_CONNECTION=sessions
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
{{< / highlight >}}

{{< highlight bash >}}
$ php artisan cache:clear && php artisan config:cache
{{< / highlight >}}

## Вместо итогов

Немного покопавшись во внутреннем устройстве Laravel мы не потеряли сессии миллионов пользователей и снизили нагрузку на базу данных.

Челлендж выполнен, команда спит спокойно, а пользователи продолжают пользоваться продуктом.
