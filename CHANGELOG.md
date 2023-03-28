# Changelog for 0.3.0

### Features
    * Allow ignoring files and directories inside the input folder
    * Allow copying asset files and directories directly to the output folder (passthrough copy)
    * Implemented filters to print content in a more presentable way
    * Implemented Shortcodes for reusable function components
    * Allow source files to specify a Permalink that overrides the default output path
    * Allow configuring the layouts directory via application config and CLI option
    * Add support for hooks `before` and `after` Griffin generates output

### Documentation
    * Added documentation for `mix grf.build` along with all supported options

### Fixes
    * Remove mandatory `.html.eex` restriction for Layouts and Partials
    * Added tests for every configuration option of `mix grf.build`, they serve as examples on how to use it
    * Fix an issue where the title of pages would be hardcoded to "Griffin"

## 0.2.0 (2023-03-23)

Partial rewrite of the project.

### Features
    * `mix grf.build` now accepts command line arguments to configure multiple parameters
    * Use multi-source configuration that is merged at the start of the build process according to a hierarchy (Environment Variables > Command Line Arguments > Application Config > Defaults)
    * Rewritten `GriffinSSG` module that handles strings instead of files, with proper docs
    * Added Github action for CI that runs tests and added CI badges to the README file.
    * Layed foundation for robust tests for `mix grf.build`

### Documentation
    * Added Getting Started guide, rewrote existing introductory docs
    * Created doc pages for most of upcoming features, using a doc structure heavily inspired by [11ty](https://www.11ty.dev/docs/).
    * Added module docs to core Elixir modules

### Fixes
    * Fixed a bug that would raise when no files were generated
    * Removed theme related code since it doesn't work yet

## 0.1.0 (2022-06-10)

Genesis version.

### Features
    * Multiple configurable options via Application environment
    * Add support for `.html.eex` layouts and partials
    * Phoenix-like `grf.new` installer