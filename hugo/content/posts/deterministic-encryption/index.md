---
title: "Deterministic Encryption for Database Primary Keys"
date: 2023-03-24T00:00:00-07:00
aliases:
  - /posts/deterministic-encryption/
  - /deterministic-encryption/
draft: false
summary: |
  Explore the benefits of deterministic encryption for database keys, enhancing security while maintaining unique constraints. This post covers how it functions, compares to traditional methods, and offers practical tips for successful implementation.
objectives: |
    By the end of this article you will be able to:

    - Grasp deterministic encryption concepts for database key management.
    - Compare deterministic vs. traditional encryption methods.
    - Assess security implications when implementing deterministic encryption.
    - Apply best practices for secure implementation in your database
meta_description: >-
  Discover the advantages of deterministic encryption for database keys, maintain security and unique constraints. Learn how it works, differs from traditional methods, and gain valuable insights for effective implementation

summary_image_enabled: true
summary_image: fortress-lock-resize.png
summary_image_title: Diagram illustrating a digital fortress protected by a lock.
utterances: true

tags:
- cryptography
- security
---

## Introduction

Deterministic encryption is a cryptographic technique where a given plaintext
always encrypts to the same ciphertext, making it particularly useful when you
want to compare two encrypted values for equality without having to decrypt them
first. Imagine a user management system where users have either a username, an
email address, or both to log in with, using a corresponding password. In this
system, unique constraints on both the username and email address fields should
be enforced, meaning that duplicate usernames, for example, are not allowed. We
would like to create a unique hash key (i.e. primary key) for each user based on
their username and email address, and store this key in a database.

While usernames may be less sensitive, email addresses are highly sensitive and
should be encrypted before being stored in the database. This begs the question,
at which layer should the email address encryption take place? In this article,
we will delve into the workings of deterministic encryption, evaluate its
security, and compare it with other approaches, all the while exploring best
practices for its implementation in a user management system.

{{< newsletter_signup >}}

## How Symmetric Encryption Typically Works

The primary goal of symmetric encryption is to render data unreadable to
unauthorized users, ensuring that a given input (plaintext) combined with a
secret key consistently produces varying outputs (ciphertexts). This prevents
attackers from inferring the plaintext, especially when encrypting low
cardinality inputs, such as "true" and "false".

Using NaCL secretbox encryption as an example, the inputs include a site key,
plaintext, and nonce. The site key is a shared secret key among system users,
while the plaintext represents the value to be encrypted. The nonce, a unique
random value for each encryption operation, ensures that the same plaintext and
site key generate different ciphertexts.

![NaCL secretbox encryption](nacl-secretbox-encryption.svg)

## How Deterministic Encryption Works

In contrast to traditional encryption, deterministic encryption is a
cryptographic technique where a given plaintext consistently encrypts into the
same ciphertext. Specifically, using NaCL secretbox, a nonce is
deterministically calculated based on the site key and plaintext instead of
being chosen at random.

![NaCL secretbox deterministic
encryption](nacl-secretbox-deterministic-encryption.svg)

Consider a scenario where users log in with their email addresses, which must be
stored as hash keys in a DynamoDB table. By employing deterministic encryption
to encrypt their email addresses at the application layer before storage,
encrypted email addresses can be compared within the database without
decryption.

This raises the question of why one should use encryption at the application
layer when services like DynamoDB already offer encryption-at-rest. The
following section addresses this.

## Security Evaluation & Threat Model

In our user management system example, evaluating the security of deterministic
encryption requires establishing a threat model. We'll focus on protecting
users' email addresses in case of a database leak or unauthorized access, while
assuming a lower risk of the site key, used for encryption, being leaked or
compromised.

This assumption arises from the fact that databases, as primary repositories of
sensitive data, are frequently targeted by attackers. In contrast, the site key
may be better protected through strict access controls, making it less visible
to outside threats. A well-protected site key, potentially employing hardware
security modules (HSMs) or other secure key management solutions, has a lower
likelihood of being compromised than a database, which could be breached via
vectors such as database backups or out-of-band accesses.

Inadequately secured database backups pose a risk for data leaks. Attackers
accessing these backups could obtain sensitive information, including stored
email addresses. However, with deterministic encryption, email addresses remain
encrypted even when backups are accessed, rendering the data useless without the
corresponding site key.

Unauthorized database access can also occur via out-of-band access, such as
through the AWS console. Malicious insiders or compromised accounts with console
access may view or modify stored data. In these cases, deterministic encryption
applied at the application layer helps protect email addresses from exposure or
tampering, as they remain encrypted in the database.

It's worth noting the importance of email addresses as unique constraints on
users. An attacker viewing all encrypted email addresses, having high
cardinality and not reused, cannot infer the plaintext email addresses due to
their unique nature.

## Best Practices and Tips for Implementing Deterministic Encryption

When implementing deterministic encryption, key management is crucial. Utilizing
secure services like AWS Secrets Manager can help protect the site key,
preventing easy access for attackers. If site key protection is compromised, the
security benefits of deterministic encryption may be lost. Complement this
protection with strong authentication and authorization mechanisms, enforcing
proper access control and safeguarding the data against unauthorized access.

Regular security audits and vulnerability assessments play an essential role in
maintaining a robust security posture. Periodically examine system components
and architecture to identify potential risks and compliance issues, allowing
timely mitigation and ensuring effectiveness of the deterministic encryption
implementation.

Finally, deterministic encryption should be part of a comprehensive, holistic
security strategy with layered defenses. Recognize its limitations and integrate
additional security measures like digital signatures, audit logs, and intrusion
detection systems as needed. Building a robust security ecosystem, in addition
to applying deterministic encryption, aids in maintaining the confidentiality,
integrity, and availability of sensitive data.

## Conclusion

Deterministic encryption offers valuable protection for sensitive data in user
management systems, enabling efficient operations on encrypted data while
maintaining confidentiality. However, it's essential to remember that a
comprehensive security approach, extending beyond encryption techniques, is
vital in ensuring an overall robust and resilient data protection ecosystem. By
combining deterministic encryption with robust key management, access control
mechanisms, and layered defenses, you can create a secure environment for
sensitive information and safeguard your users against potential threats
