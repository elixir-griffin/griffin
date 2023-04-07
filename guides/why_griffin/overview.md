# Griffin and Competitors
Griffin is an Elixir [static site generator](https://www.cloudflare.com/learning/performance/static-site-generator/). There are many static site generators in use today, with highlight for **[11ty][11ty]** (JavaScript), **[hugo][hugo]** (Golang) and **[jekyll][jekyll]** (Ruby), which inspired the creation of Griffin.

Griffin's goal is to become a relevant Elixir static site generation tool.

### Why Griffin?

* Griffin is [**fast.**](https://github.com/elixir-griffin/benchmarks)
It leverages Elixir and the BEAM to take advantage of all of your CPU-cores to generate pages quickly, up to <1 ms per page.

* Griffin was made to **feel familiar to Elixir developers.**
It uses the same `mix` based installer as [Phoenix][phoenix], which will make
Elixir web developers feel right at home.

* Griffin uses **independent template languages.**
Despite being an Elixir tool, content is written in Markdown with YAML
front matter to allow easier migrations to or from Griffin.

* Griffin is **simple to use.**
We lower the barrier to entry by using sensible defaults
and minimizing the amount of configuration needed to set up a Griffin website.

* Griffin is **built by the community.**
This is a new project that is still in active development.
Feel free to engage with us by [starring the project on Github][griffin-github],
contributing a pull-request or helping answer questions,
making sure to follow our [code of conduct][code-of-conduct].

### What about all the other Elixir tools?

Griffin is not the only tool of its kind written in Elixir. In fact, there are quite a few site generators written in Elixir, with some of the more relevant alternatives being [nimble_publisher](https://hexdocs.pm/nimble_publisher/NimblePublisher.html), [Still](https://hexdocs.pm/still/getting_started.html) and [Serum](https://dalgona.github.io/Serum/docs/index.html). All of these tools are worthy and each has a different take on supported formats, templating languages and installation methods. Griffin has its own opinionated take, which consists of:

* Best in-class documentation.
* [`Mix`](https://hexdocs.pm/mix/1.14/Mix.html) based installation and run scripts to make it familiar to [Phoenix][phoenix] users.
* Ease of use through intuitive design choices and sensible defaults.
* Only using portable, well supported formats like Markdown for content and YAML for front matter.
* Only supporting [`EEx`](https://hexdocs.pm/eex/EEx.html) for layouts.
* Offering no support for themes, users bring their own scripts, assets and styles.

These are the design choices that guide the development of Griffin and that make it unique from the other existing tools. If you read this far, keep going! Next up, read [Quick Start](quick_start.html)

[phoenix]: https://hexdocs.pm/phoenix/
[11ty]: https://www.11ty.dev/
[hugo]: https://gohugo.io/
[jekyll]: https://jekyllrb.com/
[griffin-github]: https://github.com/elixir-griffin/griffin
[code-of-conduct]: https://github.com/elixir-griffin/griffin/blob/main/CODE_OF_CONDUCT.md