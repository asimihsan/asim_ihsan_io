---
title: "Modeling terms of service updates using P"
date: 2022-10-12T00:00:00-07:00
aliases:
    - /posts/modeling-tos-updates-in-p/
    - /modeling-tos-updates-in-p/
draft: true
summary: |
    All online services require customers to accept terms of service as a
    condition of creating an account. If we need to support updating these terms
    of conditions, including supporting rollback, this becomes a simple albeit
    delicate distributed systems problem. We use the [P formal modeling
    language](https://p-org.github.io/P/) to clarify and explore the requirements and
    consequences of system design choices.
objectives: |
    By the end of this article you will be able to:

    - Apply P to the simplified problem of checking that customers
      accept any terms of service.
    - Use P to clarify the requirements of a harder problem, checking that
      customers not only accept the newest valid terms of service but that we
      also know that they did so.
    - Explore different solutions to the harder problem interactively using P.
utterances: true

tags:
- formalmodel
- p
- deployments
---

## Introduction

Foobar

{{< newsletter_signup >}}

## Prior art, references, and other resources

Bar

## Future work and areas for improvement
