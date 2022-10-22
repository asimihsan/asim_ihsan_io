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

## Threat model

When two computers talk over a network using an in-order reliable byte stream
protocol like the Transmission Control Protocol (TCP), TCP forms a logical
end-to-end connection, yet the data may flow through many other routers and
devices. For example, consider two laptops talking to each other via a wifi
router on a local network:

![TCP packets flowing end-to-end](01-tcp-packets-flowing.svg)

When laptop 1 talks to laptop 2, the actual data flows down a network stack and
is sent through the air as electromagnetic waves to the WiFi router. The WiFi
router interprets the WiFi data and forwards this again as electromagnetic waves
to laptop 2. The data travels up laptop 2's network stack, which interprets it
as TCP data. However, it is simpler and still accurate to think of a "logical"
TCP connection existing directly between laptop 1 and laptop 2.

In practice, when two computers talk over the Internet there are many more
devices involved in the network path, yet still a single end-to-end logical TCP
connection. This presents a problem from a security point of view. How do you
keep the TCP connection "secure" whilst also flinging the packets across tens of
devices you don't trust?

Concretely, let's focus on defining a secure connection from laptop 1 to
laptop 2 as:

- **Confidentiality - now**: only laptop 2 knows what data laptop 1 sends, the WiFi
  router in this example cannot see the data.
- **Confidentiality - forward secrecy**: Even if an adversary records all data
  and cracks some "key" that secures the data, on cracking the key the adversary
  cannot decrypt data sent in the past.
- **Integrity**: Laptop 2 is confident that data is not modified accidentally or
  deliberately in transit.
- **Authentication**: Laptop 2 knows that data it receives is from laptop 1, and
  laptop 1 knows that it is talking to laptop 2.
- What problem is TLS solving
- Show network stack, TCP <-> TCP end-to-end, TLS on top, HTTP on top of TLS
- Confidentiality, integrity, authentication
- Confidentiality is current session and all previous sessions (forward secrecy)

## TLS 1.3 asymmetric key-pairs vs. PSKs

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
