# Change log

## master (unreleased)

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
