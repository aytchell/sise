# Changelog

All notable changes to this project will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

- ...

## [0.9.0] - 2021-04-04

### Added

* First release of the SSDP library "Sise"
* Implements Application behaviour; thus will automatically start searching
  for devices and services
* Will send out M-Search probes every 20 minutes (interval is configurable)
* Will listen for UDP multicast (Notify-)messages
* Will store found information about devices and services in a way compliant 
  to "UPnP Device Architecture 2.0"
* Clients can fetch information about known devices/services; either all or
  for a specific notification type
* Clients can subscribe for notifications about new, updated or deleted
  devices/services; either all or for a specific notification type
* Clients can unsubscribe
* Documented the API with ExDoc
* Published to hex.pm
