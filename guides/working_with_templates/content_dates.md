# Content Dates

### Setting a Content Date in front matter
Add a `date` variable to your front matter to override the default date (last modified date) and customize how the file is sorted in a collection.

```yaml
---
date: 2023-04-25
---
```

Griffin expects the date value to be a valid [ISO 8601][iso8601] date.

### Fallback value

When parsing content files, Griffin will attempt to read from the `date` front matter variable and convert it to a [ISO 8601][iso8601] date. If this conversion fails or the variable is undefined in the front matter, Griffin will instead use the file's last modified date (`ctime` in [File.Stat](https://hexdocs.pm/elixir/1.12/File.Stat.html))

[iso8601]: https://en.wikipedia.org/wiki/ISO_8601