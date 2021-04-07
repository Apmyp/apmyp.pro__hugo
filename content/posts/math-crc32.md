---
date: 2021-04-07T12:10:49+03:00
title: "Как зафиксировать выбор математически?"
categories: ["development"]
description: "CRC спасает интернет. Опять"
og_image: "/images/math-crc32/og_image.png"
twitter_og_image: "/images/math-crc32/twitter_og_image.png"
---

Когда у пользователя нет аватарки, часто рисуют цветной кругляш и вписывают туда инициалы пользователя. Есть красивый способ подбирать цвет фона для такой аватарки, почти математически, по имени пользователя.

Или вот, хочется закодить систему АБ тестов. Как понять попадает ли пользователь в этот АБ тест или нет?

Можно выбрать случайный цвет для аватарки из палитры и записать этот цвет в базу. А для АБ тестов, просто распределить пользователей по группам попал / не попал и отразить это распределение в таблице пользователей. Но есть способ красивей! Понадобится немного математики, компьютер сайенса и знаний работы сетей (на самом деле можно все скопировать).



<div class="paragraph-with-factoid">
<p>
Нужно понять что такое циклический избыточный код или  CRC. Это функция нахождения контрольной суммы. Обычно используется для проверки целостности данных. Ну типа, потерялся какой-то байтик, так эта математическая магия его угадывает. Так компенсируются микро-потери при передачи данных по сети.
</p>
<div class="factoid">
{{< l "Cyclic redundancy check" "https://ru.wikipedia.org/wiki/%D0%A6%D0%B8%D0%BA%D0%BB%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%B8%D0%B9_%D0%B8%D0%B7%D0%B1%D1%8B%D1%82%D0%BE%D1%87%D0%BD%D1%8B%D0%B9_%D0%BA%D0%BE%D0%B4" >}} на Википедии
</div>
</div>


## Цвет фона для аватарки

<div class="paragraph-with-factoid">
<p>
Нас интересует возвращаемое значение этой функции — 
это число! Мы можем превратить любую строку в понятное число. Вот маленький пример, чтобы было понятно вот прям щас. И есть интерактивный примерчик на Кодпене с комментариями.
</p>
<div class="factoid">
{{< l "Пример на Кодпене" "https://codepen.io/apmyp/pen/QWdqbzp" >}} — про цвет аватарки
</div>
</div>

{{< highlight javascript >}}
const username = "Arthur Bordenyuk";
const colors = ['tomato', 'orangered', 'sandybrown', 'darkolivegreen', 'navy', 'rebeccapurple', 'cadetblue'];
  
// Считаем полином от строки и берем от него модуль
const positiveCrc32 = Math.abs(crc32.str(username));

// Пока имя пользователя и массив цветов не изменились, индекс будет постоянным
const computedIndex = positiveCrc32 % colors.length;

return colors[computedIndex];
{{< /highlight >}}

## Достоин ли пользователь этого АБ теста

<div class="paragraph-with-factoid">
<p>
Похожим образом будет работать и пример с АБ тестами. Надо все входные значения перевести в числа и начать математическую жесть. Полный пример так же на Кодпене.
</p>
<div class="factoid">
{{< l "Пример на Кодпене" "https://codepen.io/apmyp/pen/VwPMvMe" >}} — про попадание пользователя в конкретный АБ тест
</div>
</div>

{{< highlight javascript >}}
const splitTestName = "someTestName";
const accountId = 1300;
const DISTRIBUTION_FACTOR = 10007;
const PERCENTAGE_ENABLED = 0.5;

const salt = Math.abs(crc32.str(splitTestName));

return (salt + accountId) % DISTRIBUTION_FACTOR < DISTRIBUTION_FACTOR * PERCENTAGE_ENABLED;
{{< /highlight >}}

Вот так математика спасла чью-то маленькую базу данных.

Цём