---
episodeNumber: {{ len (where (readDir "content/episodes") "Name" "!=" "_index.md") }}
episodeSeason: 1
title: ""
date: {{ .Date }}
audioUrl: ""
duration: "00:00:00"
fileSize: 0
description: ""
draft: true
---

## Show Notes

Заметки эпизода.
