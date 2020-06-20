---
title: "[DRAFT] Random Permutations With Constant Space"
date: 2020-03-13T17:24:19-07:00
draft: true
katex: true
summary: |
    You want to iterate over a random ordering of items without storing or needing to lookup already-used items.
    We can borrow an algorithm from cryptography called the Feistel Network to generate random permutations in constant
    space and time. Applications include generating unique gift card codes or credit card numbers for your customers
    without exposing already-generated codes/numbers, and efficiently implementing the fizzlefade effect from
    Wolfenstein 3D.

    Topics: algorithms, randomness, cryptography
---

## This is a draft post, still writing it

## Introduction

A **permutation** is a specific order of a set of items. For example, the set could be the numbers $\{1, 2, 3, 4, 5\}$
in any order. One particular permutation of the set is $[5, 4, 3, 2, 1]$ A permutation does not repeat items (whereas
a combination does repeat items). Sometimes we would like to generate a random permutation. Consider these three
examples:

1. You are writing a card game and want to shuffle the cards before dealing them out. There are 52 cards in a deck so
the set of items is $\{1, 2, \dots, 52\}$.

2. You are an online merchant and want to generate 14-digit gift card numbers for customers. The set of all possible
numbers contains $10^{14} \approx 2^{47}$ numbers but we still want to be certain we don't give out the same gift card
number to multiple customers. We'd like to generate gift card numbers without looking up a database of existing gift
card numbers. Gift card numbers must be assigned as randomly as possible, or else an attacker who obtains a big block of
gift card numbers could guess older/newer numbers and steal them.

3. You are create a retro computer game and want to incorporate the fizzlefade effect [^1], where you fill in the screen
with red pixels, one pixel at a time, until the screen is completely red. You want the effect to be perfect and never
attempt to fill in a pixel more than once! Modern screen resolutions can be 3840 x 2160 pixels, i.e. approximately
$8.3 * 10^6 \approx 2^{23}$ pixels.

For the first card example we can merely create an in-memory array of 52 numbers, shuffle them using the Fisher-Yates
algorithm [^2] in $\mathcal{O}(n)$ time and $\mathcal{O}(n)$ space, then start dealing out cards. This is easy because
of how small a deck of cards is. However, attempting the same with our gift card example, where each gift card is
represented by a 64-bit integer (8 bytes per gift card number), would require $2^{47}$ numbers $*$ $8 = 2^{3}$ bytes per
number $\approx$ 1.1 petabytes! Computers today can contain that much RAM but what a waste of memory and time!

## Problem

Given an unordered set of items, we would like to iterate over random permutations of those items in:

- $\mathcal{O}(1)$ space, i.e. do not increase the amount of space needed with the size of the set of items, and
- $\mathcal{O}(1)$ time, i.e. take a constant amount of time to generate a permutation that does not increase with the
size of the set of items.

An attacker who is able to ask for many consecutive random permutations (e.g. gift card codes) should not be able to
easily guess older and newer gift card codes. The output of our solution should seem indistinguishable from
randomness.

## Solution

TODO

[https://github.com/asimihsan/permutation-iterator-rs](https://github.com/asimihsan/permutation-iterator-rs)

## Other solutions

## Prior art, references, and other resources

## Future work and areas for improvement

See foo

[^1]: Fizzlefade: [http://fabiensanglard.net/fizzlefade/index.php](http://fabiensanglard.net/fizzlefade/index.php)

[^2]: Fisher-Yates shuffle: [https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle](https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle)

[^3]: Consider the following:
$$x=5$$
This is a footnote

[^4]: Foo