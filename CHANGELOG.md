# Change log

## master (unreleased)

### Changes

* Remove unused `get_body_message_by_title_from_mail` method
* Remove unused `get_current_date` method
* Remove unused `archive_inbox` method
* Remove unused `get_body_by_subject_email` method
* Remove unused `get_unread_mails_with_tags` method
* Remove unused `get_labels` method

## 0.2.0 (2021-01-19)

### New Features

* Check `markdownlint` in CI
* Check `rubocop` in CI
* Check that 100% code is documented in CI
* Add `dependabot` config
* Add `rake` task to release gem

### Changes

* Use GitHub Actions instead of TravisCI
* Drop support of rubies older than 2.5
* Cleanup gemfile
* Freeze all dependencies in Gemfile.lock
* Remove support of `codecov`
* Add missing documentation
* Move repo to `ONLYOFFICE-QA` org

### Fixes

* Fix tests for working locally

## 0.1.0

* Initial release
