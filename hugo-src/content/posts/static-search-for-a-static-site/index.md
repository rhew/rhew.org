---
title: "Static Search for a Static Site"
date: 2026-05-18
lastmod: 2026-05-19
summary: "Add Pagefind search to a Hugo site while keeping the final site fully static."
tags:
  - rhew.org
  - code
  - terminal
  - hugo
  - docker
---

I like static sites because they stay out of the way. Write Markdown, render HTML, let Caddy serve files, and avoid waking up a database just to show somebody a recipe for pizza dough.

The catch is that static sites eventually need search. Not "ship logs to a hosted service and add a tracking script" search. Just: type a word, find the post.

For that job, I added [Pagefind](https://pagefind.app/).

It builds a client-side search index from the rendered HTML, so the deployed site stays static.

## The Shape of It

The site already has a terminal prompt in the header:

```text
rhew.org:~/projects$
```

So the search box became part of the prompt instead of another widget on the page. On desktop, it gets focus automatically. On mobile, it does not, because opening a keyboard uninvited is how websites lose privileges in the future regime.

When empty and unfocused, the box shows a subtle `Search` hint. When focused, it is just a reverse-video input with a block cursor. Type "lasagne", press Enter, and there's that recipe I need for the family beach week.

## The Build Step

Pagefind runs after Hugo renders the site. The Docker build installs Pagefind through its Python package, runs Hugo, and then indexes the generated `public/` directory:

```dockerfile
RUN hugo --minify --baseURL "${HUGO_BASEURL}"
RUN /opt/pagefind/bin/python -m pagefind --site public --exclude-selectors "header, footer"
```

The final Caddy image still serves static files. No search daemon, no extra process, no new runtime moving parts.

## The Search Page

I started with Pagefind's default UI, but the final version uses the lower-level `pagefind.js` API. That let me keep the header as the only search input and render results in the same shape as the Hugo index pages: yellow titles, white summaries, and the same article dividers.

That detail matters. Search should feel like part of the site, not a widget that wandered in from another CSS ecosystem.

## Small Things That Matter

A few details made the difference:

- The header input is a plain text box inside a search form, so browsers do not add a native clear button.
- The search hint disappears on focus but typed text stays visible after focus leaves.
- Desktop autofocus is gated on a fine pointer and hover support, so phones do not open the keyboard on page load.
- Pagefind excludes the header and footer from the index, because every result saying "recipes supervillainy and other shenanigans" is not useful intelligence.

The end result is exactly the kind of feature I like: a small capability added at build time, served as static files, and mostly invisible until needed.
