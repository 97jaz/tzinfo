#lang racket/base

(require rackunit
         tzinfo/private/os/windows)

;; https://github.com/97jaz/cldr-core/issues/1
;; I've also verified that every windows zone has an entry
;; where _territory = "001".
(check-equal? (windows->tzid "W. Australia Standard Time")
              "Australia/Perth")
