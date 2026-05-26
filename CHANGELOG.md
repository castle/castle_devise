# Changelog

## [Unreleased][main]

## [0.6.0] - 2026-05-25
- Add support for Rails 8.1
- Add support for Devise 5
- Allow `castle-rb` 9.x (constraint widened to `>= 7.2, < 10.0`); verified
  against the upcoming 9.0 release — castle_devise uses only the
  `#risk` / `#filter` / `#log` Client APIs and the `Castle::Error` /
  `InvalidParametersError` / `InvalidRequestTokenError` classes, all of
  which remain in 9.0.
- Add Ruby 3.3, 3.4, and 4.0 to the CI matrix
- Bump minimum required Ruby version to 3.2
- Replace deprecated `ActiveSupport::Configurable` with plain Ruby attribute accessors (drops the Rails 8.2 deprecation warning)
- Drop `appraisal` development dependency in favor of hand-maintained `gemfiles/*.gemfile`
- Bump development Gemfile to Rails 8.1, Devise 5, sqlite3 ~> 2.1, Bundler 2.7.x

## [0.5.0] - 2025-06-17
- Throw a warning instead of an error for the `$login.failed` event when an exception is raised
- Security fixes and dependency updates

## [0.4.3] - 2023-07-11
- Fix an issue where we would send a `login.failed` event on any attempt of accessing a protected resource, not only when the user failed to log in specifically

## [0.4.2] - 2023-07-10
- Change `params` to contain the email address sent by the user for the `/v1/filter` endpoint

## [0.4.1] - 2022-12-13
- Introduced new configuration options for `castle_sdk_facade_class` and `castle_client`

## [0.4.0] - 2022-05-17
-  Send $login $failed events to /v1/filter

## [0.3.0] - 2021-08-30

- Switch c.js to 2.0 version, Update c.js related helpers

## [0.2.0] - 2021-08-12

- Add Log action for $profile_update event with $succeeded and $failed statuses during reset password process
- Add Risk action for $profile_update event with $attempted status and Log action for $profile_update event with $succeeded and $failed statuses
- Add Log action for $password_reset_request event with $succeeded and $failed statuses
- Run specs in multiple ruby and rails versions.

## [0.1.0] - 2021-07-08

- Initial release

[main]: https://github.com/castle/castle_devise/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/castle/castle_devise/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/castle/castle_devise/compare/v0.4.3...v0.5.0
[0.4.3]: https://github.com/castle/castle_devise/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/castle/castle_devise/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/castle/castle_devise/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/castle/castle_devise/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/castle/castle_devise/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/castle/castle_devise/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/castle/castle_devise/releases/tag/v0.1.0
