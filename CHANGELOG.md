# Changelog for 0.3.0

### Features
* Add `--ignore` option for ignoring files and directories inside the input folder
* Add `--passthrough-copies` option for copying asset files and directories directly to the output folder
* Add `--layouts` option to change the layouts directory
* Add `--config` option to change the config file name
* Add `--quiet` option for minimal console output
* Add `--debug` option for printing extra information about build process
* Add `--dry-run` option to skip writing to the filesystem
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
* Added page for explaining core concepts (`guides/getting_started/core_concepts.md`)
* Added page explaining content dates (`guides/working_with_templates/content_dates.md`)
* Added page explaining build process (`guides/architecture/build_process.md`)

### Fixes
* Remove mandatory `.html.eex` extension restriction for Layouts and Partials
* Add missing tests for most configuration options of `mix grf.build`
* Fix an issue where the page title could not be changed

### Architecture

* Files are no longer parsed and rendered in the same parallel step.
Instead, they are first parsed into their front matter and content parts and collected
into an `Enum`. This enables compilation of collections of pages, that can be used to iterate
over any group of pages that uses the same front matter `tags`.

## 0.2.0 (2023-03-23)

Partial rewrite of the project.

### Features
* `mix grf.build` now accepts command line arguments to configure multiple parameters
* Use multi-source configuration that is merged at the start of the build process according to a hierarchy (Environment Variables > Command Line Arguments > Application Config > Defaults)
* Added Github action for CI that runs tests and added CI badges to the README file.
* Layed foundation for robust tests for `mix grf.build`

### Documentation
* Added Getting Started guide, rewrote existing introductory docs
* Created doc pages for most of upcoming features, using a doc structure heavily inspired by [11ty](https://www.11ty.dev/docs/).
* Added module docs to core Elixir modules

### Fixes
* Fixed a bug that would raise when no files were generated
* Removed theme related code since it doesn't work yet

### Architecture
* The abstraction that `GriffinSSG` provides for parsing and rendering was changed.
It no longer handles any files and instead handles binary contents.
This makes for a cleaner abstraction without side effects that can be better tested.

## 0.1.0 (2022-06-10)

Genesis version.

### Features
* Multiple configurable options via Application environment
* Add support for `.html.eex` layouts and partials
* Phoenix-like `grf.new` installer