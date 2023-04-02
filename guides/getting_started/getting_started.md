# Getting Started
Griffin requires Elixir version 1.14 or higher.

You can check if you have Elixir installed by running `iex --version` from a terminal. If the command is not found, you will need to [download and install Elixir](https://elixir-lang.org/install.html) before moving on.

<!-- TODO record screencast building a simple website and put it here -->

## 1. Create a new Elixir project

Create a new project using `mix new`:

```console
mix new blog
```

Now move into that directory with the `cd` command:

```console
cd blog
```

## 2. Add Griffin as a dependency

Edit the `mix.exs` file to include `griffin_ssg` as part of your dependencies:

```elixir
  defp deps do
    [
      # add the following line
      # to your list of dependencies
      {:griffin_ssg, "~> 0.3"},
    ]
  end
```

### Fetch and install Griffin

Run `mix deps.get` to fetch and install Griffin.

## 3. Run Griffin

Let's use one of Griffin's scripts to test that the installation is working:

```console
mix grf.build
```

Here's what the terminal might look like after you've run this command:

```console
~/blog $ mix grf.build
Wrote 0 files in 0.03 seconds (v0.2.0)
```

If you see `(v0.2.0)` that means you're running the latest version of Griffin. Note that Griffin didn't process any files -- this was expected, since we've not added templates yet.

## 4. Create some templates
A *template* is a content file written in a format such as Markdown, HTML or Liquid, which Griffin transforms into one or more pages when building our website.

Let's create a couple of templates with the following commands:

```console
echo '<!doctype html><title>My Cool Blog</title><p>Hello!</p>' > index.html
```

```console
echo '# Hello From Griffin' > README.md
```

You can create these template files manually with any editor you like, just make sure to save them in your project folder and to use the right file extensions.
Now that we have an HTML and a Markdown template, let's run Griffin again:

```console
mix grf.build
```

The output may look like this:
```console
~/blog $ mix grf.build
Writing _site/README/index.html from ./README.md (earmark)
Writing _site/index.html from ./index.html (earmark)
Wrote 2 files in 0.06 seconds (v0.2.0)
```

We’ve compiled our two content templates in the current directory into the output folder (`_site` is the default).

## 5. See the results
Let's use a different Griffin script to spin up a local HTTP server:

```console
mix grf.server
```

Open `http://localhost:4000/` or `http://localhost:4000/README/` in your favorite web browser to see your Griffin site live! At the moment you still need to re-run `mix grf.build` every time you make changes to the templates, but we'll add a hot-reloading feature in an upcoming version.