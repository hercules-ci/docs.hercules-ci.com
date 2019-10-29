Official Hercules CI Documentation site source.

https://docs.hercules-ci.com/


# Install and build (non-authoritative)

    ./build

# Add a repo

Needs Hercules CI authz.

 - Add in antora-playbook.yml

 - Generate build hook from the [settings page](https://app.netlify.com/sites/hercules-docs/settings/deploys)
    - Build hook name: _name of the repo_
    - Branch to build: always `master` because this is about the docs.hercules-ci.com repo
    - Copy the generated url

 - Add the build hook to the github repo settings
    - `github.com/<owner>/<repo>/settings/hooks`
    - Payload URL: _as copied_
    - Content type: `application/json`
    - Secret: _empty_
    - Just the push event: _ticked_

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
