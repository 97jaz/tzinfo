#lang info

(define collection 'multi)
(define deps (list "base"
                   "rackunit-lib"
                   (list "tzdata" '#:platform 'windows)))
(define build-deps '("racket-doc" "scribble-lib"))
