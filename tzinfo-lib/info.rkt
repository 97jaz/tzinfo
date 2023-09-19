#lang info

(define collection "tzinfo")
(define version "0.6")
(define deps '("base"
               "cldr-core"
               ["tzdata" #:platform windows #:version "0.5"]))
(define update-implies '("tzdata"))
