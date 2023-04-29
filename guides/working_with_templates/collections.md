# Collections

### What are collections?

A collection is a mechanism for grouping content pages. One common example of collections are `tags` in a blog,
where aside from the user generated content there is a `/tags` page listing all of the tags
and multiple `/tags/:tag` pages, one for each tag, grouping all of the posts that used that particular tag.

Griffin allows users to define an arbitrary number of collections through the configuration file.
For a movie rating website, the following collections could be defined:

```elixir
# config/config.exs
import Config

config :griffin_ssg,
  collections: %{
    cast: %{...},
    directors: %{...},
    production_companies: %{...},
    year: %{...},
    genres: %{...}
  }
```

After setting a proper configuration for each collection, Griffin would be able to start grouping all of the pages according to the data available in the front matter. Using the example for a movie rating website, the following could be one possible template:

```markdown
# src/movies/the-hateful-eigth.md
---
title: The Hateful Eight
year: 2015
directors: Quentin Tarantino
poster: https://upload.wikimedia.org/wikipedia/en/d/d4/The_Hateful_Eight.jpg
cast:
  - Samuel L. Jackson
  - Kurt Russell
  - Jennifer Jason Leigh
  - Walton Goggins
  - Demián Bichir
  - Tim Roth
  - Michael Madsen
  - Bruce Dern
  - James Parks
  - Channing Tatum
production_companies:
  - The Weinstein Company
  - Shiny Penny
  - FilmColony
  - Double Feature Films
  - Visiona Romantica, Inc.
genres:
  - western
  - mystery
  - thriller
---
The Hateful Eight (sometimes marketed as The H8ful Eight or The Hateful 8) is a
2015 American Western mystery thriller film written and directed by Quentin Tarantino.
[...]
```

After rendering each individual page, Griffin will generate collection pages for each `cast`, `directors`, `production_companies`, `year` and `genres`. Griffin will generate a listing page for all values of each collection as well as a listing page for all pages associated with a given collection value. Using the movie example from above, the following pages would be generated for `genres`:

```text
/genres/
/genres/western/
/genres/comedy/
[...]
```

The `/genres/` page would list and link to each individual genre (e.g. western, comedy, etc.) and the remaining pages would list all content pages associated with each genre.

### Configuring a collection

Collections can be defined in the configuration file of your application under the `collections` configuration key. Each collection's definition is a name (`"string"` or `:atom`) and a map with its configuration parameters:

```elixir
# config/config.exs
import Config

config :griffin_ssg,
  collections: %{
    "albums": %{
      permalink: "/movie/genres",
      list_layout: "list_genres",
      show_layout: "show_genre"
    }
  }
```

Collections accept the following configuration parameters:

* `permalink` - the path where the collection is written. Defaults to `/<collection_name>`.
* `list_layout` - the layout used to list all values for the collection (e.g. all movie genres)
* `show_layout` - the layout used to list all pages associated with a given value (e.g. all western movies)

### Collection list layout

The collection list layout (`list_layout`) is the layout used to list all of the values of a single collection. When rendering this layout, Griffin injects the following variables:

* `@collection_name`, containing the name of the collection (e.g. `"genres"`)
* `@collection_values`, containing a mapping of all pages associated with each collection value:
```elixir
%{
    "western" => [%{url: "/movie1/"}, %{url: "/movie2/"}],
    "comedy" => [%{url: "/movie1/"}]
}
```

Here's an example of a basic list layout built for listing `genres`:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>All Movie Genres</title>
  </head>
  <body>
    <h1>All Movie Genres</h1>
    <ul>
    <%= for {genre, _pages} <- @collection_values do %>
      <li><a href="/<%= collection_name %>/<%= genre %>/"><%= genre %></a></li>
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

> #### Collection show layout is optional {: .info}
>
> If you don't wish to have pages for each collection value (e.g. `/genres/western`) you can design your own
> custom `list_layout`, since Griffin injects all of the collection information (including the mappings from
> values to pages) into this layout.