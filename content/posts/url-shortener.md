---
title: "How shortener feature works"
date: 2020-05-26T13:24:02+03:00
categories: ["development"]
description: "Arthur Bordenyuk is going to explain how to implement url shortener"
---

I have to make a system which can give us short version of URL and a way to track clicks.

This gist is about how I solved the first part of problem: as short as possible URL.

First things first. If we talk about system which handle URLs then we should have a table in database.

Example table of URLs:

<table>
  <tr>
    <th>ID</th>
    <th>URL</th>
  </tr>
  <tr>
    <td>1</td>
    <td>https://example.com/</td>
  </tr>
  <tr>
    <td>2</td>
    <td>https://reddit.com/</td>
  </tr>
  <tr>
    <td colspan="2">…</td>
  </tr>
  <tr>
    <td>174579021</td>
    <td>https://random.cat/</td>
  </tr>
</table>

My solution is to convert urls ID into base-n number system. This way allows to leave the database table as it is.

For example if we convert last url ID 174579021 to base 16 we will get A67DD4D. But if we convert the same ID to base 64 with custom chars (from javascript example below) we will get 9OxpC.

Now I can implement simple action `/:convertedID`, convert ID back to decimal and search the ID through primary key.

Benefits:

- DB table remains the same
- User sees pseudo-random (because of converted primary key) short link
- No one cannot search through other links until they know char set

Shortener implementation:

{{< highlight javascript >}}
function shortener() {
  const chars = '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz'.split('');
  const count = chars.length;

  function encode(num) {
    if ( num === 0 ) {
      return "";
    } else if ( num > 0 ) {
      return encode(parseInt(num / count, 10)) + chars[num % count];
    }
  }

  function decode(str) {
    return str.split('').reduce((num, val) => {
      return num * count + chars.indexOf(val);
    }, 0);
  }

	return {
  	encode,
    decode
  };
}

export { shortener };
{{< /highlight >}}

Shortener example:

{{< highlight javascript >}}
import { shortener } from "./shorten.js";

const { encode, decode } = shortener();

encode(1233); // => 'IG'
decode(encode(1233)); // => 1233

encode(112233); // => 'QOd'
decode(encode(112233)); // => 112233

encode(1000000000); // => 'vagc-'
decode(encode(1000000000)); // => 1000000000
{{< /highlight >}}
