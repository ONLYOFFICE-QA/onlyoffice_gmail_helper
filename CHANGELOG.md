# Change log

## master (unreleased)

### New Features

* Add `ruby-3.2` in CI
* Add `ruby-3.3` to CI
* Add dependabot check for GitHub Actions

### Changes

* Drop support of `ruby-2.7` since it's EOL'ed
* Fix `rubocop-1.65.0` cop `Gemspec/AddRuntimeDependency`

## 0.5.0 (2022-07-27)

### New Features

* Add `yamllint` check in CI

### Fixes

* Fix `markdownlint` failure because of old `nodejs` in CI
* Remove `codeclimate` support since we don't use it any more
* If there is no config fail on initialize level, not on `require` level

### Changes

* Check `dependabot` at 8:00 Moscow time daily
* Changes from `rubocop-rspec` update to 2.9.0
* Fix `rubocop-1.28.1` code issues
* Drop support of `ruby-2.6` since it's EOL'ed

## 0.4.0 (2022-01-14)

### New Features

* Add `ruby-3.1` in CI

### Fixes

* Fix compatibility with `ruby-3.1` by adding bundled gems

### Changes

* Remove `ruby-2.5` from CI since it's EOLed

## 0.3.0 (2021-11-16)

### New Features

* Add new spec tests

### Fixes

* `get_body_message_by_title` correct return if no html body

### Changes

* Remove unused `get_body_message_by_title_from_mail` method
* Remove unused `get_current_date` method
* Remove unused `archive_inbox` method
* Remove unused `get_body_by_subject_email` method
* Remove unused `get_unread_mails_with_tags` method
* Remove unused `get_labels` method
* Remove unused `send_mail_test_result` method
* Remove unused `mark_all_unread` method
* Remove unused `delete_from_sender` method
* Remove unused `mail_inbox_count` method
* Remove unused `mail_in_label_with_date` method
* Remove unused `reply_mail` method
* Remove unused `delete_all_message_contains` method
* Remove unused `delete_message_with_portal_address` method
* Remove unused `check_unread_messages_for_message` method
* Remove unused `get_unread_messages` method
* Remove unused `wait_until_unread_message` method
* Remove unused `refresh` method
* Remove unused `Object#to_imap_date` method
* Remove patch for ruby bug 14750
* Require `mfa` for releasing gem

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
