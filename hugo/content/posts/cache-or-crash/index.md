---
title:
  "Cache or Crash: Exploring the risks of using caching in distributed software
  systems"
date: 2023-03-25T00:00:00-07:00
aliases:
  - /posts/cache-or-crash/
  - /cache-or-crash/
draft: false
summary: |
  Discover the complexities of caching in distributed software systems as we explore both its benefits and potential risks. Learn from real-world examples and delve into best practices for implementing caching securely, without compromising availability.
meta_description: >-
  Explore caching in distributed systems, learn from real-world incidents, and
  discover best practices for secure, high-performing caches.
utterances: true
objectives: |
  By the end of this article you will be able to:

  - Understand caching benefits and risks in distributed systems.
  - Examine real-world caching incidents and impacts.
  - Implement caching best practices for secure, high-performing systems.

summary_image_enabled: true
summary_image: fire.png
summary_image_webp: fire.webp
summary_image_title:
  Illustration of a dumpster on fire with a green letter M inside it.
summary_image_width: 300
summary_image_height: 300
tags:
  - distributed
  - cache
---

{{< newsletter_signup >}}

## Introduction

Caching is a powerful technique used to store and retrieve frequently accessed
data more efficiently, reducing the need to fetch the data from its original
source repeatedly. By improving software system performance, caching can reduce
latency, costs, and smooth over small downstream availability drops. The
benefits are significant, making caching a mandatory part of the software
engineering process and system design interviews.

However, caching also comes with immense risks. In this article, we will explore
real-world examples of caching-related incidents, discuss the dark side of
caching, and provide best practices for implementing and maintaining caches
securely and reliably. By understanding the benefits and risks of caching, you
can create high-performing software systems that strike the right balance
between caching strategies and alternatives.

## Real-World Examples

### OpenAI security breach on Mar/20/2023

OpenAI utilizes Redis to cache user information, reducing the load on their
database. However, the [ChatGPT security breach on March 20,
2023](https://openai.com/blog/march-20-chatgpt-outage), resulted from a change
that caused an unexpected surge in Redis request cancellations. This resulted in
users seeing chat titles and chat messages from other users.

Although the blame was laid on the feet of the [redis-py
client](https://github.com/redis/redis-py/issues/2624), it's not clear how and
why sensitive information is being stored in the cache as opposed to solely in a
database, nor what the load testing and monitoring strategies are.

### Slack outage on Feb/22/2022

The [Slack outage on February 22,
2022](https://slack.engineering/slacks-incident-on-2-22-22/) serves as a
compelling case study on the risks associated with caches in software
architectures.

During a routine deployment to a control plane of Consul agents, Memcache nodes
were sequentially removed from the cache fleet. At the same time, an inefficient
Vitess database query for fetching user data in group direct messages (GDMs)
occurred. With a significant portion of the cache unavailable, the database was
overwhelmed, and most queries timed out, preventing cache refilling. Slack's
users experienced a widespread outage, with many unable to access the platform
or experiencing significant performance issues.

{{< svg "slack.svg" "svg-img-full" >}}

## The Dark Side of Caching

Navigating the complexities of caching in distributed systems can be
challenging, as even expert guidance may not always provide accurate solutions.
Take, for instance, [Azure's "Caching
guidance"](https://learn.microsoft.com/en-us/azure/architecture/best-practices/caching),
which states:

> **For example, a database might support a limited number of concurrent
> connections. Retrieving data from a shared cache, however, rather than the
> underlying database, makes it possible for a client application to access this
> data even if the number of available connections is currently exhausted.**
> Additionally, if the database becomes unavailable, client applications might
> be able to continue by using the data that's held in the cache.
>
> Consider caching data that is read frequently but modified infrequently (for
> example, data that has a higher proportion of read operations than write
> operations). However, we don't recommend that you use the cache as the
> authoritative store of critical information. Instead, ensure that all changes
> that your application can't afford to lose are always saved to a persistent
> data store. **If the cache is unavailable, your application can still continue
> to operate by using the data store, and you won't lose important
> information.**

The crucial misstep here lies in relying on the cache as a means to enhance
availability when the data store can only support a limited number of concurrent
connections. In the event that the cache becomes unavailable, your application's
availability will inevitably suffer, as it can no longer access the data store
with the same level of concurrency. Consequently, the very purpose of using the
cache to improve availability is undermined.

The same incorrect design assumptions underlie the Slack outage. The Memcache
cluster inadvertently has become the crutch that papers over the inefficient
database queries and ineffectiveness of sharding by the Vitess database.

The OpenAI incident underscores the risks of storing sensitive data in a cache,
as security measures for the database might not cover the cache layer.
Furthermore, the choice and implementation of a database are crucial in
preventing such issues. Selecting an appropriate database could potentially
eliminate the need for caching altogether, mitigating the associated security
and availability risks.

## How DynamoDB improved their metadata caching

[DynamoDB](https://www.usenix.org/system/files/atc22-elhemali.pdf) is a
distributed system composed of multiple microservices, including metadata
service, request routing service, and storage nodes. The metadata service stores
routing information, while the request routing service handles authorization,
authentication, and routes requests to the appropriate storage nodes.

{{< svg "dynamodb-architecture-01.svg" >}}

Initially, DynamoDB stored metadata solely in the Metadata Service, which itself
runs on DynamoDB. This resulted in a high cache hit rate but also introduced
bi-modal behavior. This behavior caused performance issues and potential
cascading failures when new request routers were added or caches became
ineffective.

To address these issues, DynamoDB created an in-memory distributed datastore
called MemDS. MemDS stores metadata in memory and replicates it across its
fleet, scaling horizontally to handle the incoming request rate.

A new partition map cache was deployed on each request router host to avoid
bi-modality. Cache hits now trigger an asynchronous call to MemDS to refresh the
cache, ensuring a constant volume of traffic to the MemDS fleet regardless of
cache hit ratio. This approach increases the load on the metadata fleet compared
to conventional caches but prevents cascading failures when caches become
ineffective.

{{< svg "dynamodb-architecture-02.svg" >}}

DynamoDB storage nodes serve as the authoritative source of partition membership
data. Partition membership updates are pushed from storage nodes to MemDS and
propagated to all MemDS nodes. If the partition membership provided by MemDS is
stale, the incorrectly contacted storage node either responds with the latest
membership or an error code, triggering another MemDS lookup by the request
router. This design ensures efficient and reliable routing of requests in the
distributed system, reducing risks associated with caches and improving overall
performance.

## Best Practices for Implementing and Maintaining Caches

Before diving headfirst into caching, it's crucial to take a step back and
honestly assess whether your software service truly needs it. Overreliance on
caches can lead to potential disasters when traffic patterns shift or cache
fleets fail. Never use caches as an intentional means of increasing
availability, or if you do, ensure that your cache fleet undergoes the same
level of design assessment and load testing as the services it fronts.

To avoid issues with caching, it is essential to consider factors such as cache
hit ratio, tolerance to eventual consistency, and the rate of change of source
data when implementing caches. Additionally, choosing between local (on-box) and
external caches depends on the specific needs and requirements of the service.

## Conclusion: Mastering the Cache Balance

In conclusion, caching can be a powerful tool for improving the performance of
distributed software systems, but it also comes with inherent risks and
complexities. By carefully evaluating the necessity of caching, implementing
robust strategies, and monitoring cache usage, you can strike the right balance
between caching and alternative solutions. Ultimately, understanding the
benefits and risks of caching will enable you to create secure, high-performing
software systems that can withstand the challenges of ever-changing traffic
patterns and unexpected failures.
