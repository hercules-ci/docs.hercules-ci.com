Official Hercules CI Documentation site source.

https://docs.hercules-ci.com/


# Install and build (non-authoritative)

    ./build

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

 - When editing files from the frontend wizards in `snippets`, use links
   that open in a new window (`^`) e.g. `https://hercules-ci.com/dashboard[dashboard^]`.

   The wizards are currently stateful and we don't want to lose their state by navigating.

 - File naming:

   TODO when setting up antora
