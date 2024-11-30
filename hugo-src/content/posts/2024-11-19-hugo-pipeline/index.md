---
title: "Blogging with Hugo and Docker"
date: 2024-11-19
tags: ["Hugo", "Docker", "Markdown", "Static Site"]
summary: I decided to use Hugo to build a blog.
tags:
  - code
  - terminal
  - hugo
  - docker
---

Since retiring, I’ve been tracking my projects and pursuits. During my career, I often sought simplicity, working in the terminal, using plain text, and stripping away unnecessary complexity. It feels fitting to bring that philosophy to blogging as well.

I decided to use [Hugo](https://gohugo.io/) to publish my blog. While it’s not the most popular static website generator, it supports Markdown—and that’s perfect for me.

## The Hugo Workflow

The typical workflow for Hugo involves running the tool locally to generate a directory structure. Into this structure, you add your content, themes, and templates. Finally, you run Hugo to render the site. 

However, I didn’t want to check in anything other than my content and instructions for building the site. Here’s how I streamlined this process using Hugo and Docker.

## Minimum Required Structure

I stripped the Hugo-generated content down to just the minimum required structure:

```
├── archetypes
│   └── default.md
├── config.toml
└─── content
    └── posts
```


1. **`config.toml`**: This file defines the base URL and specifies the theme directory, which we’ll populate at build time:
   ```toml
   baseURL = 'https://rhew.org/projects/'
   languageCode = 'en-us'
   title = 'rhew.org: projects'
   theme = 'rhew-org-theme'
   ```
2. **`archetypes/default.md`**: Contains default metadata for new content.

3. **`content/posts`**: This is where the blog content lives.

## Two-Stage Dockerfile

To build and serve the site, I used a two-stage Dockerfile:

1. Stage One:
  - Copies the content.
  - Installs the theme ([Radek Kozieł's Terminal theme](https://github.com/panr/hugo-theme-terminal/)—a fitting choice, of course).
  - Builds the site.

2. Stage Two:
  - Copies the rendered content from stage one.
  - Uses [Caddy](https://caddyserver.com/) to serve the rendered site.
  - You can view the full Dockerfile [here](https://github.com/rhew/rhew.org/blob/main/Dockerfile.rhew.org).

This setup keeps my repository clean and focused on content. It embodies the simplicity I value—minimal distractions and maximum utility.

Happy blogging!


