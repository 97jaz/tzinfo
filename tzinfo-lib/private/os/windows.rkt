#lang racket/base

(require file/resource
         cldr/core
         "env.rkt"
         "windows-registry.rkt")

(provide
 windows-tzid-tests
 windows->tzid)

(define (windows-tzid-tests)
  (list tzid-from-env
        tzid-from-registry/vista
        tzid-from-registry/nt
        tzid-from-registry/95))

(define (tzid-from-registry/vista)
  (windows->tzid
   (get-resource KEY (string-append TZINFO-KEY "\\TimeZoneKeyName"))))

(define (tzid-from-registry/nt)
  (windows->tzid
   (tzid-from-registry-list "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones")))

(define (tzid-from-registry/95)
  (windows->tzid
   (tzid-from-registry-list "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Time Zones")))

(define (windows->tzid tz)
  (and tz
       (for*/first ([map-tz (in-list (windows-zones))]
                    [win-tz (in-value (cldr-ref map-tz '(mapZone _other)))]
                    [territory (in-value (cldr-ref map-tz '(mapZone _territory)))]
                    #:when (and (equal? tz win-tz)
                                (equal? territory "001")))
         (cldr-ref map-tz '(mapZone _type)))))

(define (tzid-from-registry-list prefix)
  (define standard (standard-name))
  (define tzs (subresources KEY prefix))

  (for*/first ([tz (in-list tzs)]
               [std (in-value (get-resource KEY (format "~a\\~a\\Std" prefix tz)))]
               #:when (equal? standard std))
    tz))

(define (standard-name)
  (get-resource KEY (string-append TZINFO-KEY "\\StandardName")))


(define KEY "HKEY_LOCAL_MACHINE")
(define TZINFO-KEY "SYSTEM\\CurrentControlSet\\Control\\TimeZoneInformation")
