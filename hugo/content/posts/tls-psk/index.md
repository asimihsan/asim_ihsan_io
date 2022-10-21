---
title: "TLS 1.3 PSK mode - theory and practice"
date: 2022-10-18T00:00:00-07:00
aliases:
  - /posts/tls-13-psk/
  - /tls-13-psk/
draft: true
summary: |
  Transport Layer Security (TLS) is an application-layer protocol that sits on
  top of e.g. the Transmission Control Protocol (TCP) and provides a secure
  channel. TLS usually uses asymmetric key-pairs, but instead can use
  symmetric keys i.e. pre-shared keys (PSKs) instead, shared in advance. In
  this article I discuss the trade-offs with using PSKs, what the protocol
  differences are, TLS 1.3 0-RTT setup, and simple code with Wireshark
  debugging to try this out.
objectives: |
    By the end of this article you will be able to:

    -   Understand what TLS 1.3 PSK+DHE is.
    -   Use the OpenSSL command-line tool and Wireshark to explore TLS 1.3
        PSK+DHE.
    -   Use stunnel to deploy an end-to-end TLS 1.3 PSK+DHE proxy tunnel.
    -   Use Rust to deploy an end-to-end TLS 1.3 PSK+DHE proxy tunnel.

tags:
- tls
- security
- wireshark
---

## Introduction

Foo

{{< newsletter_signup >}}

## Prior art, references, and other resources

Bar

## Future work and areas for improvement

## References

## Appendix
