---
title: "Formal modeling as a design tool"
date: 2022-01-18T20:14:00-07:00
aliases:
  - /posts/formal-modeling-as-a-design-tool/
  - /formal-modeling-as-a-design-tool/
draft: true
summary: |
    [Alloy](https://alloytools.org/) is a language and analyzer for formal software modeling. As a way of starting to learn Alloy I model a toy design that I know to be broken: Python pip's legacy dependency resolution algorithm.
objectives: |
    By the end of this article you will be able to:

    -   Use Alloy to model and analyze a software design over time.
    -   Analyze Python pip's legacy dependency resolution algorithm and how it is broken.
    -   Explore a software design iteratively using formal modeling.

tags:
- alloy
- formalmodel
- pip
- dependency
---

## Introduction

Foo

You can follow along by [downloading Alloy](https://alloytools.org/download.html) if you'd
like.

{{< newsletter_signup >}}

## Prior art, references, and other resources

[Formal Software Design with Alloy 6](https://haslab.github.io/formal-software-design/) is
a work-in-progress book documenting the most recent release of Alloy, [Alloy
6](https://alloytools.org/alloy6.html). I learned a lot following the guide, and this is a
great starting point for learning about Alloy.

I knew that I wanted to model a simplified version of pip's legacy dependency resolution
algorithm and started reading [Formally Specifying a Package
Manager](https://www.hillelwayne.com/post/nix/). This article inspired me to get started.

## What are packages?

{{< highlight alloy >}}
sig Package {}
{{< / highlight >}}

## Future work and areas for improvement

