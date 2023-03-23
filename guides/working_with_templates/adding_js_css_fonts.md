# Adding JS, CSS and Fonts

### Copying files using passthrough

In your `config.exs` file, you can add a list of files or directories to be copied over to the output directory using the `passthrough_copies` configuration key:

```elixir
config :griffin_ssg,
  passthrough_copies: ["styles.css", "bundle.js"]
```

Then in your HTML you can reference these files:

```html
<html>
  <head>
    <link rel="stylesheet" href="/bundle.css">
    <script src="/bundle.js"></script>
  </head>
  <!-- rest of the page -->
</html>
```