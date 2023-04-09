# Changelog for 0.3.0

### Features
* Add `--ignore` option for ignoring files and directories inside the input folder
* Add `--passthrough-copies` option for copying asset files and directories directly to the output folder
* Add `--layouts` option to change the layouts directory
* Add `--config` option to change the config file name
* Add `--quiet` option for minimal console output
* Add `--debug` option for printing extra information about build process
* Add `--dry-run` option for testing and debugging
* Implemented filters to print content in a more presentable way
* Implemented Shortcodes for reusable function components
* Allow templates to specify Permalinks that override the default output path
* Add support for hooks `before` and `after` Griffin generates output
* Add support for content collections through the `tags` front matter field
* Add support for nested layouts
* Add support for EEx templates inside input directory
* Add support for global assigns inside a project-wide data directory (defaults to `data`)

### Documentation
* Added documentation for `mix grf.build` along with all supported options
* Improved landing documentation page (`guides/why_griffin/overview.md`)
* Add page for explaining core concepts (`guides/getting_started/core_concepts.md`)

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