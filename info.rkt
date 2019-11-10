#lang info

(define collection 'multi)
(define version "0.4")
(define deps (list "base"
                   "cldr-core"
                   "rackunit-lib"
                   (list "tzdata" '#:platform 'windows '#:version "0.4")))
(define update-implies (list "tzdata"))
(define build-deps '("racket-doc" "scribble-lib"))
