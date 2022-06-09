# Installation

In order to build a static website with Griffin, we will need a few dependencies installed in our Operating System:

  * the Erlang VM and the Elixir programming language
  * and other optional packages.

Please take a look at this list and make sure to install anything necessary for your system. Having dependencies installed in advance can prevent frustrating problems later on.

## Elixir 1.13 or later

Griffin is written in Elixir, and our application code will also be written in Elixir. To install Elixir, please see the official [Installation Page](https://elixir-lang.org/install.html) for help.

If we have just installed Elixir for the first time, we will need to install the Hex package manager as well. Hex is necessary to get a Griffin website running (by installing dependencies) and to install any extra dependencies we might need along the way.

Here's the command to install Hex (If you have Hex already installed, it will upgrade Hex to the latest version):

```console
$ mix local.hex
```

## Griffin

To check that we are on Elixir 1.13 or later, run:

```console
elixir -v
Erlang/OTP 24 [erts-12.0.1] [source] [64-bit] [smp:16:16] [ds:16:16:10] [async-threads:1] [jit]

Elixir 1.13.2
```

Once we have Elixir, we are ready to install the Griffin application generator:

```console
$ mix archive.install hex grf_new
```

The `grf.new` generator is now available to generate new applications in the next guide, called [Up and Running](up_and_running.html). The flags mentioned below are command line options to the generator; see all available options by calling `mix help grf.new`.

<!-- ## inotify-tools (for Linux users)

Griffin provides a very handy feature called Live Reloading. As you change your views or your assets, it automatically reloads the page in the browser. In order for this functionality to work, you need a filesystem watcher.

macOS and Windows users already have a filesystem watcher, but Linux users must install inotify-tools. Please consult the [inotify-tools wiki](https://github.com/rvoicilas/inotify-tools/wiki) for distribution-specific installation instructions. -->

## Summary

At the end of this section, you must have installed Elixir, Hex, and Griffin. Now that we have everything installed, let's create our first Griffin website and get [up and running](up_and_running.html).