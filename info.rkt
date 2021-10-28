#lang info

(define collection 'multi)
(define version "0.5")
(define deps (list (list "base" '#:version "7.5.0.7")
                   "cldr-core"
                   "rackunit-lib"
                   (list "tzdata" '#:platform 'windows '#:version "0.5")))
(define update-implies (list "tzdata"))
(define build-deps '("racket-doc" "scribble-lib"))
