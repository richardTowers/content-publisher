# Content Publisher

A unified publishing application for content on GOV.UK

## Nomenclature

  * Content - Some text ([and related fields][content-schemas]) a user wants to publish
  * Revision - A version of a piece of content in a particular locale
  * Edition - A revision that is in the Publishing API
  * Document - All revisions of a piece of content in a particular locale


## Technical documentation

This is a Ruby on Rails application.

### Dependencies

- [postgresql][] - provides a backing database
- [yarn][] - package manager for JavaScripts
- [imagemagick][] - image manipulation library

### Running the application

```
bowl content-publisher
```

### Running the test suite

```
yarn install
bundle exec rake
```

### Importing Whitehall news documents

To populate your local database with [Whitehall][whitehall-repo] content there
is a task in Whitehall to export data and a task in Content Publisher to
import that output.

To export from Whitehall, you need to have a cloned copy of Whitehall with a
populated database, cd into the whitehall directory and run:

```
bundle exec rake export:news_documents 2>&1 | grep created_at > /tmp/whitehall-export.json
```

This will take a while to run (~30 mins), this can be reduced by limiting the
output with [filters][export-filters]

To import this exported file into Content Publisher, you need to cd into the
content publisher directory and run:

```
bundle exec rake import:whitehall_news INPUT=/tmp/whitehall-export.json
```

## Licence

[MIT License](LICENCE)

[content-schemas]: https://github.com/alphagov/govuk-content-schemas
[postgresql]: https://www.postgresql.org/
[yarn]: https://yarnpkg.com/
[imagemagick]: https://www.imagemagick.org/script/index.php
[whitehall-repo]: https://github.com/alphagov/whitehall
[export-filters]: https://github.com/alphagov/whitehall/blob/master/lib/tasks/export.rake#L153
