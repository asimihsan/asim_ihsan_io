---
title: "[DRAFT] Random Permutations With Constant Space"
date: 2020-03-13T17:24:19-07:00
draft: true
katex: false
mathjax: true
summary: |
    You want to iterate over a random ordering of items without storing or needing to lookup already-used items.
    We can borrow an algorithm from cryptography called the Feistel Network to generate random permutations in constant
    space and time. Applications include generating unique gift card codes or credit card numbers for your customers
    without exposing already-generated codes/numbers, and efficiently implementing the fizzlefade effect from
    Wolfenstein 3D.

    Topics: algorithms, randomness, cryptography
---

{{< banner_info >}}This is a draft post, still writing it{{< /banner_info >}}

## Learning objectives

By the end of this article you will be able to:

-   Understand what a Feistel Network is.
-   Use Feistel Networks to generate random permutations on small domains.

## Introduction

A **permutation** is a specific order of a set of items. For example, the set could be the numbers $\{1, 2, 3, 4, 5\}$
in any order. One particular permutation of the set is $[5, 4, 3, 2, 1]$ A permutation does not repeat items (whereas a
combination does repeat items). Sometimes we would like to generate a **random permutation**. Consider these three
examples:

1. You are writing a card game and want to **shuffle** the cards before dealing them out. There are 52 cards in a deck
   so the set of items is $\{1, 2, \dots, 52\}$.

2. You are an online merchant and want to **generate gift card numbers** for customers, for example 14-digit gift card
   numbers. The set of all possible numbers contains $10^{14} \approx 2^{47}$ numbers but we still want to be certain we
   don't give out the same gift card number to multiple customers. We'd like to generate gift card numbers without
   looking up a database of existing gift card numbers. Gift card numbers must be assigned as randomly as possible, or
   else an attacker who obtains a big block of gift card numbers could guess older/newer numbers and steal them. How
   guessable a gift card number is should be configurable.

3. You are create a retro computer game and want to incorporate the [**fizzlefade
   effect**](http://fabiensanglard.net/fizzlefade/index.php), where you fill in the screen with red pixels, one pixel at
   a time, until the screen is completely red. You want the effect to be perfect and never attempt to fill in a pixel
   more than once! Modern screen resolutions can be 3840 x 2160 pixels, i.e. approximately $8.3 * 10^6 \approx 2^{23}$
   pixels.

For the first card example we can merely create an in-memory array of 52 numbers, shuffle them using the [Fisher-Yates
algorithm](https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle) in $\mathcal{O}(n)$ time and $\mathcal{O}(n)$
space, then start dealing out cards. This is easy because of how small a deck of cards is. However, attempting the same
with our gift card example, where each gift card is represented by a 64-bit integer (8 bytes per gift card number),
would require $2^{47}$ numbers $*$ $8 = 2^{3}$ bytes per number $\approx$ 1.1 petabytes! Computers today can contain
that much RAM but what a waste of memory and time!

## Problem

Given an unordered set of items, we would like to iterate over random permutations of those items in:

- $\mathcal{O}(1)$ space, i.e. do not increase the amount of space needed with the size of the set of items, and
- $\mathcal{O}(1)$ time, i.e. take a constant amount of time to generate a permutation that does not increase with the
size of the set of items.

An attacker who is able to ask for many consecutive random permutations (e.g. gift card codes) should not be able to
easily guess older and newer gift card codes. The output of our solution should seem indistinguishable from
randomness.

{{< newsletter_signup >}}

## Solution

A **Feistel network** is an algorithm that can permute an input integer in its domain. Concretely, given an n-bit integer with input domain $\[0, 2^n\)$, a Feistel network promises to map that input to another output integer in the same domain, such that the mapping is **bijective**. Each input maps to one and only one output, and vice-versa (each output maps to one and only one input). This is the definition of a **permutation**. See the [Appendix "Demonstration that a Feistel Network permutes an input integer"]({{< relref "#demonstration-that-a-feistel-network-permutes-an-input-integer" >}}).

TODO

[https://github.com/asimihsan/permutation-iterator-rs](https://github.com/asimihsan/permutation-iterator-rs)


## Other solutions

## Prior art, references, and other resources

## Future work and areas for improvement

## Appendix

<a>

### Demonstration that a Feistel Network permutes an input integer

Recall that the XOR operator $\oplus$ applied to two binary digits returns 1 if they are different, 0 if they are not. Hence by definition for any input integer $A$, $A \oplus A = 0$.

Hence consider some input integer $P$ and split it into two pieces $A$ and $B$, where $P = A \mathbin\Vert B$ ($A$ and $B$ concatenated together give P). $A$ and $B$ can have any non-zero lengths.

Let's demonstrate a 2-round Feistel network. This applies the Feistel round function twice. At the end we swap the parts.

$$
\begin{array}{lll}
\textrm{Encryption, at the start:} \\\\\\\\
L_0 &=& A, \\\\
R_0 &=& B \\\\\\\\
\textrm{After the first round:} \\\\\\\\
L_1 &=& R_0, \\\\
R_1 &=& L_0 \oplus f\(R_0, K_0\) \\\\\\\\
\textrm{After the second round:} \\\\\\\\
L_2 &=& R_1, \\\\
R_2 &=& L_1 \oplus f\(R_1, K_1\) \\\\\\\\
\textrm{After the rounds are done, swap to produce result C} \\\\\\\\
C &=& R_2 \mathbin\Vert L_2
\end{array}
$$

Given output $C$, apply the process in reverse, ensuring that the Feistel functions and round keys are applied in reverse.

$$
\begin{array}{rcl}
\textrm{Decryption, at the start:} \\\\\\\\
T_0 &=& R_2\\\\
U_0 &=& L_2 \\\\\\\\
\textrm{After the first round:} \\\\\\\\
T_1 &=& U_0 \\\\
U_1 &=& T_0 \oplus f\(U_0, K_1\) \\\\\\\\
\textrm{After the second round:} \\\\\\\\
T_2 &=& U_1 \\\\
U_2 &=& T_1 \oplus f\(U_1, K_0\) \\\\\\\\
\textrm{After the rounds are done, swap to produce result Q:} \\\\\\\\
Q &=& U_2 \mathbin\Vert T_2 \\\\\\\\
\end{array}
$$

Now we simplify $Q$ (the encrypted-then-decrypted value) and demonstrate it is equal to $M$ (the original input).

$$
\begin{array}{rcl}
Q &=& \overbrace{T_1 \oplus f\(U_1, K_0\)}^{U_2} \mathbin\Vert \overbrace{U_1}^{T_2} \\\\
  &=& U_0 \oplus f\(T_0 \oplus f\(U_0, K_1\), K_0\) \mathbin\Vert T_0 \oplus f\(U_0, K_1\) \\\\
  &=& L_2 \oplus f\(R_2 \oplus f\(L_2, K_1\), K_0\) \mathbin\Vert R_2 \oplus f\(L_2, K_1\) \\\\
  &=& R_1 \oplus f\(L_1 \oplus \overbrace{f\(R_1, K_1\) \oplus f\(R_1, K_1\)}^{0}, K_0\) \mathbin\Vert L_1 \oplus \overbrace{f\(R_1, K_1\) \oplus f\(R_1, K_1\)}^{0} \\\\
  &=& R_1 \oplus f\(\overbrace{L_1 \oplus 0}^{L_1}, K_0\) \mathbin\Vert \overbrace{L_1 \oplus 0}^{L_1} \\\\
  &=& R_1 \oplus f\(L_1, K_0\) \mathbin\Vert L_1 \\\\
  &=& L_0 \oplus \overbrace{f\(R_0, K_0\) \oplus f\(R_0, K_0\)}^{0} \mathbin\Vert R_0 \\\\
  &=& L_0 \mathbin\Vert R_0 \\\\
  &=& A \mathbin\Vert B \\\\
  &=& P\qquad_{\square}
\end{array}
$$

This applies to any number of Feistel rounds.
