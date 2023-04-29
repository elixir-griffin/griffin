# Permalinks

You can customize the default location of templates to the output directory using permalinks.

Here are some examples of how it works by default (assuming your output directory is the default, `_site`):

| Input                    | Output                     | Href              |
|--------------------------|----------------------------|-------------------|
| `index.eex`              | `index.html`               | `/`               |
| `blog.eex`               | `blog/index.html`          | `/blog/`          |
| `blog/somepost.md`       | `blog/somepost/index.html` | `/blog/somepost/` |
| `blog/somepost/index.md` | `blog/somepost/index.html` | `/blog/somepost/` |

#### Cool URIs don't change
If you're migrating to Griffin from some other piece of software which would generate different URIs for your existing content,
you can use `permalink` to make sure that your [Cool URIs don’t change](https://www.w3.org/Provider/Style/URI).

### Changing the output
To remap your template’s output to a different path than the default, use the permalink key in the template’s front matter. If a subdirectory does not exist, it will be created.

```yaml
---
permalink: "some-new-directory/subdirectory/content/index.html"
---
```

A template with this front matter will be written to `_site/some-new-directory/subdirectory/content/index.html`

### Custom output formats
You can change the file extension in the permalink to output to any file type. For example, to generate a JSON search index to be used by popular search libraries:

```eex
---
permalink: "index.json"
---
<%= Jason.encode!(@collections.all) %>
```