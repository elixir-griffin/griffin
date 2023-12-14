# Layouts

Layouts are special templates that can be used to wrap other content.
To denote that a piece of content should be wrapped in a template, use the layout key in your front matter, like so:

```markdown
---
layout: cool_layout
title: My Cool Griffin Blog Post
---
# <%= @title %>
```

This will look for a `cool_layout.eex` EEx file in your *layouts* folder at `lib/layouts/cool_layout.eex`.

Next, we need to create a `cool_layout.eex` file. It can contain any type of text, but here we’re using HTML:

```html
---
title: My Griffin Blog
---
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= @title %></title>
  </head>
  <body>
    <%= @content %>
  </body>
</html>
```

Note that the layout template will populate the `@content` data with the child template’s content.

Layouts can contain their own front matter data! It’ll be merged with the content’s data on render. Content data takes precedence, if conflicting keys arise. Read more about how [Griffin merges data in what we call the Data Cascade](data_cascade.html).

All of this will output the following HTML content to `_site/some-page/index.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Cool Griffin Blog Post</title>
  </head>
  <body>
    <h1>My Cool Griffin Blog Post</h1>
  </body>
</html>
```

### Front matter data in layouts
In [Griffin's Data Cascade](data_cascade.html), front matter data in your template is merged with Layout front matter data! All data is merged ahead of time so that you can mix and match variables in your content and layout templates interchangeably.

Front matter data set in a content template takes priority over layout front matter! The closer to the content, the higher priority the data.

#### Sources of data

When the data is merged in the [Data Cascade](data_cascade.html), the order of priority for sources of data is (from highest priority to lowest):

1. Computed Data
1. Front Matter Data in a Template
1. Template Data Files
1. Directory Data Files
1. Front Matter Data in Layouts
1. Configuration Global Data
1. Global Data Files

### Layout aliasing
In your `config.exs` configuration file, you can a mapping of aliases for layouts using the `layout_aliases` configuration key:

```elixir
config :griffin_ssg,
  layout_aliases: %{post: "cool_layout.eex"}
```