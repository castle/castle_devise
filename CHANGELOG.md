# Changelog

## [Unreleased][main]

- Throw a warning instead of an error for the `$login.failed` event when an exception is raised

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

[main]: https://github.com/castle/castle_devise/compare/v0.4.3...HEAD
[0.4.3]: https://github.com/castle/castle_devise/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/castle/castle_devise/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/castle/castle_devise/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/castle/castle_devise/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/castle/castle_devise/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/castle/castle_devise/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/castle/castle_devise/releases/tag/v0.1.0
