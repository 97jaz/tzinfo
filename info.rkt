#lang info

(define collection 'multi)
(define deps (list "base"
                   "cldr-core"
                   "rackunit-lib"
                   (list "tzdata" '#:platform 'windows)))
(define build-deps '("racket-doc" "scribble-lib"))
