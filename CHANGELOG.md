# Changelog
All notable changes to this project will be documented in this file.
`BlueConicClient` adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [1.1.2] 2025-11-04

### Fixed
 - Fixed issue with plugin classes not registering correctly, specifically listeners.
 - Fixed crash happening when processing listener services.
 - Fixed crash when when processing commands from the SDK service.
 - Added several checks to prevent crashes to plugins and event processing.

## [1.1.1] 2025-11-03

### Fixed
 - Fixed a crash happening when trying to save certain profile properties to the cache.

## [1.1.0] 2025-10-08

### Added
 - Added Scoring listener plugin support.
 - Added Behaviour listener plugin support.
 - Added Interest Ranker 1.0 plugin support.
 - Added Recommendations as Event Dialogue plugin support.
 - Published SDK to ropm.

### Changed
 - Changed the increment value method for the profile to accept Integer values instead of String.

### Fixed
 - Fixed issue with plugins not registering correctly.

## [1.0.0] 2025-06-18

### Added
 - Initial SDK Release containing the following features:
    - Event tracking (PAGE VIEW, VIEW, CONVERSION, CLICK)
    - Profile properties manipulations (add, set, increment, privacy, and objectives)
    - Profile creation/deletion
    - Global Listener plugin
    - Preferred Hour Listener plugin
    - Visit Listener plugin
    - Properties-Based Dialogue plugin
    - Timeline Events
    - Simulator Support