# Build Process

Griffin's `mix grf.build` task consists of a build process involving 9 separate but simple stages.
This document details each stage of the build process.

## 1. Call `before` hooks

Griffin has built in support for hooks, which are arbitrary functions that can be called `before` or `after` all of the other build stages.
Adding a hook can be done via `Application.put_env/4` or via the configuration file:

```elixir
import Config

config :griffin_ssg,
  hooks: %{
    before: [
      fn {directories, _run_mode, _output_mode} ->
        # compile assets, assumes esbuild is a dependency of the project
        Mix.Task.run("esbuild default #{directories.data} --bundle --minify --outdir=src/assets/")
      end
    ]
  }
```

> #### Hooks are called every time the build process is called {: .info}
>
> Hook functions are called at the start of each stand-alone build, but it may be called multiple times if using the `--watch` command line option and file changes are detected.

## 2. Import global data

This step consists of searching a specific directory for data (defaults to `data`).
Data pulled in from files this directory will be globally available for all templates and layouts to use.
Griffin expects each file to be an Elixir script (`.exs`) where the last expression in the file is a map.

As an example, let's assume that we're writing a `metadata.exs` file with the following contents:

```elixir
%{
  author: %{
    email: "geralt@example.com",
    name: "Geralt of Rivia",
    url: "https://example.com/about-me/"
  },
  description: "I am a legendary witcher from the School of the Wolf",
  language: "en",
  title: "My awesome Griffin website",
  url: "https://example.com/"
}
```

This data will then be accessible via the `@metadata` variable in templates.
For example, a layout could reference the author name in a layout:

```html
<p><%= @metadata.author.name %></p>
```

Griffin chooses the variable name to inject in templates from the filename of the data file.
In the previous example, if the filename was `site.exs`, the contents of the file would be available under the `@site` template variable.

> #### Variables may be overriden {: .warning}
>
> Before generating a page, Griffin merges all available data for a template and this process may override some variables.
> Global data has the lowest priority in the merge process. See [Data Cascade](/data_cascade.html) for more information.

## 3. Copy passthrough files

Passthrough files are files that live in a particular directory that should simply be copied to the output path without processing.
This feature can be used via the `--passthrough-copies` command line option, or via the configuration file:

```elixir
import Config

config :griffin_ssg,
  passthrough_copies: ["assets/**/*.js", "**/*.{png,jpeg}"]
```

The configuration above will copy all PNG and JPEG images along with all Javascript files inside the `assets` directory.
A file that lives in the `<project_root>/assets` will be copied to `<output_dir>/assets`.

## 4. Compile layouts

Layouts are `EEx` templates that by default live in the `lib/layouts` directory.
This stage of the build process consists on fetching all layouts and partials, compiling them into Elixir AST and storing them in [`:ets`](https://elixirschool.com/en/lessons/storage/ets).

## 5. Parse files

This stage consists of calculating the list of files that will generate HTML pages and then parsing them into a `{front_matter, content}` pair.
Some metadata is added to the front matter, like the URL of the file and the output path.

Note that the parsed files are kept in memory and are not written to disk (yet).

## 6. Compile collections

Using a list of parsed files from the previous stage, goes over the list of files and compiles a list of collections, storing information about which
page is part of each collection.

As an example, in a blog website declaring a `tags` collection, Griffin will group all pages by their front matter value of `tags`.
Multiple collections can be declared, enabling websites that group content by `author`, `year`, `genre`, etc.

Here is an example configuration declaring `tags` as a collection:

```elixir
import Config

config :griffin_ssg,
  collections: %{
    tags: %{
      list_layout: "list_tags",
      show_layout: "show_tags"
    }
  }
```

## 7. Render files

This is the stage where the parsed files are actually rendered and written to disk. At this point, Griffin merges all of the available data for a template according to the [Data Cascade](/data_cascade.html).

If Griffin is running with the `--dry-run` command line option, no files will be written.

## 8. Render collection pages

This stage generates multiple pages according to the number of declared collections. For a website that only declares a `tags` collection, the following pages could be generated:

```text
/tags/
/tags/tag1/
/tags/tag2/
...
```

Using this example, Griffin will use the layout referenced in the `list_layout` configuration key to render the `/tags/` page and the layout from the `show_layout` configuration key to render each of the `/tags/<tag>` pages. The configuration for both layouts can be set in the configuration file:

```elixir
config :griffin_ssg,
  collections: %{
    tags: %{
      list_layout: "list_tags",
      show_layout: "show_tags"
    }
  }
```

### Collection list layout

The collection list layout (`list_layout`) is the layout used to list all of the values of a single collection. When rendering this layout, Griffin injects the following variables:

* `@collection_name`, containing the name of the collection (e.g. `:tags`)
* `@collection_values`, containing a mapping of all pages associated with each collection value:
```elixir
%{
    "tag1" => [%{url: "/page1/"}, %{url: "/page2/"}],
    "tag2" => [%{url: "/page2/"}]
}
```

Here's an example of a basic list layout built for listing `tags`:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Tags</title>
  </head>
  <body>
    <h1>All Tags</h1>
    <ul>
    <%= for {tag, _pages} <- @collection_values do %>
      <li><a href="/<%= collection_name %>/<%= tag %>/"><%= tag %></a></li>
    <% end %>
    </ul>
  </body>
</html>
```

### Collection show layout

The collection show layout (`show_layout`) is the layout used to list content pages associated with a single collection value. When rendering this layout, Griffin injects the following variables:
* `@collection_name`, containing the name of the collection (e.g. `:tags`)
* `@collection_value`, containing the name of the collection value (e.g. `"tag1"`)
* `@collection_value_pages`, containing a list of maps (e.g. `[%{url: "/page1/"}]`),
where each map contains page information such as URL, title, description, date, input and output paths. Of these attributes, title and description can be `nil` if they are not set in the page's front matter.

Here's an example of a basic show layout built for listing all pages with a given `tag`:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Pages tagged <%= @collection_value %></title>
  </head>
  <body>
    <h1>Pages tagged `<%= @collection_value %>`</h1>
    <ul>
    <%= for page <- @collection_value_pages do %>
      <li><a href="<%= page.data.url %>"><%= page.data.title %></a></li>
    <% end %>
    </ul>
  </body>
</html>
```

No collections pages will be written to disk if Griffin is running with the `--dry-run` command line option.

## 9. Call `after` hooks

Similarly to the `before` hooks, Griffin supports hooks that are called after the build process is complete. Hooks can be defined via application environment or via configuration file:

```elixir
config :griffin_ssg,
  hooks: %{
    after: [
      fn {directories, results, _run_mode, _output_mode} ->
        # results contains a list of generated HTML files
        Tesla.post(
          "https://example.com/webhooks",
          Jason.encode!(%{"Files Written" => length(results), "success" => true}),
          headers: [{"content-type", "application/json"}]
        )
      end
    ]
  }
```