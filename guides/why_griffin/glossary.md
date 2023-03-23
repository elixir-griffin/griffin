# Glossary

This page provides two lists of terms — one for [Griffin-specific terminology](#griffin-specific-terminology) that may be useful for when building out a project using Griffin, and one for [industry jargon](#industry-terms-and-buzzwords) that may be useful for understanding context.


## Griffin-Specific Terminology

### Template

A content file written in a format such as Markdown, HTML, HEEx or Liquid, which Griffin transforms into one or more pages in the built site. Templates can access [data](#data) exposed through the [data cascade](#data-cascade) with templating syntax.

### Layout

A template which wraps around another template, typically to provide the scaffolding markup for content to sit in.

[Read more about using layouts.](layouts.html)

### Data

Exposed via variables that can be used inside [templates](#template) and [layouts](#layout) using templating syntax. The data for a given template is aggregated through a process called the [data cascade](#data-cascade).

### Data Cascade

Griffin's order of operations for evaluating all [data](#data) for any given [template](#template), and for resolving conflicts that arise. The data cascade follows the principle of colocation, so data defined broadly to apply to many templates will be overruled by data that targets the given template more specifically.

<!-- [Read more about the data cascade.](data_cascade.html) -->

<!-- ### Filter

A function which can be used within templating syntax to transform [data](#data) into a more presentable format. Filters are typically designed to be chained, so that the value returned from one filter is piped into the next filter.

[Read more about filters.](filters.html) -->

<!-- ### Shortcode

A function which can be used within templating syntax to inject content into templates. Shortcodes can take many arguments, and can be thought of as a templating approach to reusable markup.

[Read more about shortcodes.](shortcodes.html) -->

### Collection

An array of [templates](#template), used to group similar content. Collections can be created by using [tags](collections.html#tag-syntax) or by calling the [collections API in the Griffin configuration](collections.html#advanced-custom-filtering-and-sorting).

[Read more about collections.](collections.html)

<!-- ### Pagination

A way to create pages by iterating over data. The same template is applied to each chunk of the paginated data.

[Read more about pagination.](pagination.html) -->

<!-- ### Plugin

A portable, installable Griffin configuration which can add [data](#data), [filters](#filter), [shortcodes](#shortcode), and more to a project's setup.

[Read more about plugins.](plugins.html) -->

## Industry Terms and Buzzwords

Our industry can be particularly bad about inventing words for things that already exist. Hopefully this page will help you navigate the labyrinth.

### Static Sites

A static site is a group of generated HTML files. Content is built into the HTML files rather than using a dynamic back end language to generate the content on-the-fly. A dynamic site can appear static when you add caching rules to make the content stickier. A static site can appear dynamic when you run your build quickly and often.

### Data-Driven

Make components and markup data-driven so that you don’t have a bunch of one-off copy-pasted HTML instances littered throughout your project.

### Zero Config

Zero config means that Griffin can run without any command line parameters or configuration files.

We’ve taken care to setup Griffin so that that running the stock  `grf.build` command uses sensible defaults. Lower the barrier to entry for that first project build to get up and running faster.

### Convention over Configuration Routing

Instead of requiring a centralized configuration file for routing, `Griffin` routes map the file system, unless you override with a `permalink`.

