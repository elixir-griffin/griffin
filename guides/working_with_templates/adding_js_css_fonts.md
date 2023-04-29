# Adding JS, CSS and Fonts
Currently there are two ways in which you can add assets to a Griffin project.

### 1. Copying files using `passthrough-copies`

In your configuration file, you can add a list of files or directories to be copied over to the output directory using the `passthrough_copies` configuration key:

```elixir
# config/config.exs
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

> #### Passthrough-copies works with relative paths {: .info}
>
> Passthrough copies allows you to copy files from an assets folder to the output directory using relative paths.
> If you have an `assets` folder in the root of your project and you want to copy it using passthrough copies,
> Griffin will copy all the subfolders and files to `<output_dir>/assets`.

### 2. Using Hooks

As part of your configuration, you can write a hook function that copies all of the asset files into a directory inside the output folder.
This can be done in your configuration file, as usual:

```elixir
# config/config.exs
config :griffin_ssg,
  hooks: %{
    before: [
      fn _ ->
        # Note: this function would also work as an `after` hook.
        File.mkdir_p!("_site/assets")
        File.cp_r!("assets/vendor", "_site/assets/vendor")
        File.cp_r!("assets/img", "_site/assets")
      end
    ]
  }
```