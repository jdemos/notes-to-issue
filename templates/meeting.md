---
date: <% tp.date.now("YYYY-MM-DD") %>
github_issue: <% (tp.file.folder().split('/').pop().match(/ -\s*(\d+)\s*$/) || [null, ""])[1] %>
published: false
---
## Agenda: <% tp.date.now("MM-DD-YY") %>

1. 
## Notes

- 
## Action items

- [ ]

<% await tp.file.rename(tp.date.now("YYYY-MM-DD")+"-Meeting") %>
