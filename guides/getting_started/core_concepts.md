# Core Concepts

### Templates
A template is a content file written in [Markdown](https://daringfireball.net/projects/markdown/basics).
This is where you'll write most of your content. Here's an example file:

```markdown
# People in space

## How many people are in space at this very moment?
The answer is 10. Here are the ten brave souls:

* Kayla Barron
* Matthias Maurer
* Thomas Marshburn
* Raja Chari
* Oleg Artemyev
* Denis Matveev
* Sergey Korsakov
* Ye Guangfu
* Wang Yaping
* Zhai Zhigang
```

When building your website, Griffin takes files such as this and generates web pages from them using the [earmark](https://hex.pm/packages/earmark) library.

### Front Matter
Front Matter is an **optional** header section written in [YAML](https://yaml.org/) that allow setting variables for a given page.
It is defined within two triple-dash (`---`) lines at the start of the template.
Here's how we could add Front Matter to the previous template:

```markdown
---
date: 2023-04-05T21:51:54Z
draft: false
---
# People in space

## How many people are in space at this very moment?
The answer is 10. Here are the ten brave souls:
[...]
```

You can use Front Matter variables inside templates using [Embedded Elixir](https://hexdocs.pm/eex/EEx.html) (EEx) like so:

```elixir
<%= @date %>
```

Front Matter is also used to configure multiple aspects of a page's output, such as the layout to render, the URL of the page, etc.

### Layouts

Layouts are templates that wrap around your content.
They allow a clean separation between the structure and content of your website.
One layout may be used by many content pages, thus avoiding repetition of common snippets of code (e.g. navigation, footer).

Layouts are typically [`.eex`](https://hexdocs.pm/eex/EEx.html) files and by default should live in the `lib/layouts` directory of your project.

#### Usage

Write your HTML template to a file such as `lib/layouts/base.html.eex`, here's some example content:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title><%= @title %></title>
    <link rel="stylesheet" href="/css/style.css">
  </head>
  <body>
    <nav>
      <a href="/">Home</a>
      <a href="/blog/">Blog</a>
    </nav>
    <h1><%= @title %></h1>
    <section>
      <%= @content %>
    </section>
    <footer>
      &copy; <%= @author %>
    </footer>
  </body>
</html>
```

When this layout is rendered, both `title` and `author` will come from the front matter of the template being rendered.
The value of the `content` variable will be the rendered output of the page being wrapped.

In your content pages, you'll need to specify in the front matter what layout to use:

```markdown
---
title: Four score and seven years ago
author: Abe Lincoln
layout: base
---

The sixth sick sheik's sixth sheep's sick.
```

The rendered output of this page will be:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Four score and seven years ago</title>
    <link rel="stylesheet" href="/css/style.css">
  </head>
  <body>
    <nav>
      <a href="/">Home</a>
      <a href="/blog/">Blog</a>
    </nav>
    <h1>Four score and seven years ago</h1>
    <section>
      The sixth sick sheik's sixth sheep's sick.
    </section>
    <footer>
      &copy; Abe Lincoln
    </footer>
  </body>
</html>
```

#### Layouts can be nested
Layouts can be nested by adding a Front Matter section and setting the `layout` variable:

```html
---
layout: base
---
<p>I am a nested layout</p>
<%= @content %>
```

Nesting layouts can be useful to reduce duplication of code. You can build a top level layout called `base`, which defines your core HTML with CSS and JS imports, and other, much simpler layouts for individual pages like `home`, `blog` or `about`.

> #### Limit {: .tip}
>
> Griffin allows a maximum nesting level of 10 for layouts.

### Partials

Partials are layouts that cannot render `content` but are useful to extract common snippets of code. Partials typically live in the `lib/layouts/partials` directory.

In the previous example, you could extract the navigation snippet into a `lib/layouts/partials/navigation.html.eex` like so:

```html
<nav>
  <a href="/">Home</a>
  <a href="/blog/">Blog</a>
</nav>
```

Layouts can include partials using the `partials` variable.

If both the navigation and footer snippets were extracted to their own files, the template from the previous example would look like this:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title><%= @title %></title>
    <link rel="stylesheet" href="/css/style.css">
  </head>
  <body>
    <%= @partials.navigation %>
    <h1><%= @title %></h1>
    <section>
      <%= @content %>
    </section>
    <%= @partials.footer %>
  </body>
</html>
```

Partials, like layouts, can reference front matter variables.

### Directory Structure

A Griffin project for a blog might look like this:

```shell
.
├── _site
├── assets
│   ├── css
│   │   ├── app.min.css
│   │   └── tailwind.min.css
│   ├── img
│   │   ├── one-monitor.jpeg
│   │   └── six-monitors.png
│   └── js
│       ├── app.min.js
│       └── jquery.min.css
├── config
│   └── config.exs
├── lib
│   └── layouts
│       ├── base.html.eex
│       ├── home.html.eex
│       └── partials
│           ├── header.html.eex
│           └── footer.html.eex
├── src
│   ├── about.md
│   ├── blog.md
│   ├── blog
│   │   ├── 2019-04-06-why-one-monitor-just-isnt-enough.md
│   │   ├── 2020-04-06-two-monitors-is-good-but-three-is-better.md
│   │   └── 2021-04-06-i-broke-my-desk-using-six-monitors-a-short-story.md
│   └── index.md
├── mix.exs
└── mix.lock
```

Griffin can be configured to copy asset files via the `passthrough_copies`. You can use the following command to build the website:

```
    $ mix grf.build --passthrough-copies=assets
```

This is what the output directory (`_site`) would look like:

```shell
.
├── about.html
│   └── index.html
├── assets # all subdirectories copied
├── blog
│   ├── index.html
│   ├── 2019-04-06-why-one-monitor-just-isnt-enough
│   │   └── index.html
│   ├── 2020-04-06-two-monitors-is-good-but-three-is-better
│   │   └── index.html
│   └── 2021-04-06-i-broke-my-desk-using-six-monitors-a-short-story
│       └── index.html
└── index.html
```

### Griffin directories

By default these are the directories that are relevant for Griffin projects:

| Directory     | Description                                                                                                                                                                                                                                                                                                     |
|---------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `_site`       | The output directory where Griffin writes generated files to. After building your website, you can copy the contents of this directory into a hosting service like [Netlify](https://app.netlify.com/drop/), [GitHub Pages](https://pages.github.com/), [Cloudflare Pages](https://pages.cloudflare.com/), etc. |
| `config`      | The configuration directory, usually containing a single `config.exs` file. These configuration files can add custom plugins, shortcodes, define pre/post-build hooks and more.                                                                                                                                 |
| `lib/layouts` | The layouts directory. Usually contains EEx layouts and a optional `partials` subdirectory containing partial layouts.                                                                                                                                                                                          |
| `src`         | The input directory. Griffin will read all Markdown templates inside this directory and generate pages from them if they are not marked as a draft in the front matter.                                                                                                                                         |