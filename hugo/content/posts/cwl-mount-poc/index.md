---
title: "Mounting AWS CloudWatch logs as a file system - proof of concept"
date: 2021-12-05T16:11:36-07:00
aliases:
  - /posts/cwl-mount-poc/
  - /cwl-mount-poc/
draft: true
summary: |
    [cwl-mount](https://github.com/asimihsan/cwl-mount) lets you mount AWS CloudWatch logs as a file system. In
    this article I talk about why this is an interesting problem worth solving, how I reached a proof-of-concept stage for a useful tool, and challenges I encountered
    as a Rust newbie in creating useful Rust library APIs.
objectives: |
    By the end of this article you will be able to:

    -   Understand why mounting AWS CloudWatch logs as a file system is helpful.
    -   Understand at a high level what the Filesystem in Userspace (FUSE) interface is.
    -   Understand a Rust newbie's perspective on struggling to write Rust library APIs.
    -   Know what the next steps are for `cwl-mount`

tags:
- aws
- rust
- fuse
---

## Introduction

Foo

{{< newsletter_signup >}}

## Prior art, references, and other resources

Bar

## Future work and areas for improvement

