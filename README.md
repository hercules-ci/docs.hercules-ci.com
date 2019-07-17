Based on [pixyll.com](http://www.pixyll.com) and Semantic UI.

It is configured to be auto-deployed via netlify.


# Install and build (non-authoritative)

    $ nix-build

# Development (non-authoritative)

    $ nix-shell --run "jekyll serve"

# Style Guide

 - The Headings are in Title Case

 - Add explicit anchors to headings, in particular when cross-referencing.
   This helps with preventing broken links.

   ```
   [[some-old-title]][[about-x]]
   = About x
   ```

 - Use snake case for normal titles but verbatim spelling for technical terms.
   Prevent confusion.

   ```
   [[understanding-baseDirectory]]
   = Understanding `baseDirectory`
   ```

 - When editing files from the frontend wizards in `autogenerate`, use links
   that open in a new window (`^`) e.g. `https://hercules-ci.com/dashboard[dashboard^]`.

   The wizards are currently stateful and we don't want to lose their state by navigating.

 - File naming:

   TODO when setting up antora
