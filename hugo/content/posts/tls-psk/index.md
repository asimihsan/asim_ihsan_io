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
  channel. TLS usually uses asymmetric key-pairs, but instead can use symmetric
  keys i.e. pre-shared keys (PSKs) shared in advance. TLS PSK can be more
  efficient by avoiding public-key operations and also more convenient by
  avoiding the need to public key infrastructure (PKI).

  In this article I discuss the trade-offs with using PSKs, what the protocol
  differences are, TLS 1.3 0-RTT setup, and simple code with Wireshark debugging
  to try this out.
objectives: |
  By the end of this article you will be able to:

  - Understand what TLS 1.3 PSK+DHE is.
  - Use the OpenSSL command-line tool and Wireshark to explore TLS 1.3
    PSK+DHE.
  - Use stunnel to create an end-to-end TLS 1.3 PSK+DHE proxy
    tunnel.
  - Use Rust to create an end-to-end TLS 1.3 PSK+DHE proxy tunnel.

tags:
  - tls
  - security
  - wireshark
---

## Introduction

![](tls-sequence.svg)

![](system-design.svg)

{{< newsletter_signup >}}

## Threat model, TLS 1.3 asymmetric key-pairs vs. PSKs

- What problem is TLS solving
- Show network stack, TCP <-> TCP end-to-end, TLS on top, HTTP on top of TLS
- Confidentiality, integrity, authentication
- Confidentiality is current session and all previous sessions (forward secrecy)

## TLS in action with OpenSSL CLI

- `openssl` command line easy to use, just look at the terminal!
- Also great way of verifying interoperability.
- Show some key sections, what means what

## End-to-end encryption in action with stunnel

- stunnel, host to host, what problem it solves

## End-to-end encryption in action with your own code

- Uses Rust but most of the code is actual OpenSSL over FFI
- Show Wireshark, decryption mode
- Show effect of OpenSSL flags

## Open issues and areas for investigation

## References

## Appendix
