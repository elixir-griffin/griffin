# Plugins
## Creating a plugin for Griffin
A plugin for Griffin is just an Elixir module. In order to share it with others, we will need to build it into a [hex package](https://hex.pm/docs/publish).

### Publishing a Griffin Plugin
In order to keep the Hex namespace as clean as possible, we recommend that you publish any Griffin plugins under the name `grf_plugin_[NAME]`.