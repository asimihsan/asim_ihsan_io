---
title: "Creating a Cost-Effective and Highly Available Chatbot with OpenAI, AWS, and Discord"
date: 2023-02-04T00:00:00-07:00
aliases:
  - /posts/openai-discord-bot-on-aws/
  - /openai-discord-bot-on-aws/
draft: false
summary: |
  This blog post discusses how to create a cost-effective and highly available chatbot
  with OpenAI, AWS, and Discord. It explains the advantages of using these three tools
  together, and the challenges involved in creating a chatbot. Solutions proposed in this
  article include using EC2 Spot Instances for cost-effective hosting and using distributed
  locking with leases to prevent duplicate work and handle faults, providing a
  cost-effective and reliable way to create a chatbot.
summary_video_enabled: true
summary_video: demo.mp4
summary_video_type: video/mp4
objectives: |
  By the end of this article you will be able to:

  - Connect a bot to Discord using WebSocket.
  - Create a chatbot using OpenAI language models.
  - Host a highly available chatbot on AWS using EC2 spot instances.

tags:
  - discord
  - openai
  - aws
---

{{< newsletter_signup >}}

## Problem statement

Creating a collaborative chatbot that can engage in conversations with multiple users is a challenging problem
that requires a secure, cost-effective, and highly available solution. OpenAI's language models can be used to
create such a chatbot. However, hosting it on a web application is not ideal because creating a usable web
user experience would require more work than necessary. Using an existing chat platform makes it easier to access the
chatbot on any device. Furthermore, the application needs to be secure, cost-effective, and highly available.

## System overview

![01-system-overview](01-system-overview.png)

0. Multiple bots connect to Discord over WebSocket.
1. Users connect to Discord using their preferred client. When they chat in channels, the messages are sent to the Discord server.
2. The Discord server forwards the messages to all connected Discord bots.
3. All bots try to acquire a lease on the message in DynamoDB. The bot that acquires the lease is the only bot that will send the message to OpenAI.

- System Overview - step-by-step walkthrough of system components
  - Technologies Used - list of technologies used
  - Code Samples - provide code samples to demonstrate how it works
  - Deployment - explain how the system is deployed
  - Visuals - include diagrams and screenshots to better explain the system and its components

- System Components - Overview of components used in the system
- Discord Client - Details of connecting to Discord using a Discord client
- AWS EC2 Spot Instances - Details of how the Discord bot runs on AWS EC2 spot instances
- WebSocket Connection - Overview of connecting the Discord bot to Discord over WebSocket
- OpenAI - Overview of how the bot talks to OpenAI to get chatbot responses
- End-to-End Sequence - Example of an end-to-end sequence of a user chatting
  - Diagram - Draw a diagram to illustrate the components involved in the end-to-end sequence 
- Summary - Summarize the system overview

This system provides an easy-to-use interface for users to create their own
custom chatbot using OpenAI language models. The bot is hosted on AWS EC2 spot
instances and connects to Discord over WebSocket. The bot talks to OpenAI to get
responses, allowing users to have an intelligent conversation with the bot. The
system is designed to support up to 10 messages per second and can handle
multiple shards using distributed locking and leases on DynamoDB to reduce calls
to OpenAI. An end-to-end sequence of a user chatting with the bot can be
illustrated with a diagram showing the various components involved. The system
is secure, with users able to run the bot on EC2 instances in their own AWS
account, ensuring their Discord messages are not shared with a third party. AWS
resources are configured with secure best practices to provide a highly
available chatbot.

### Benefits of using OpenAI, AWS, and Discord

### Challenges Involved in Creating a Discord Chatbot

### Solutions Proposed in this Article

## Cost-Effective Hosting

- Automation and configuration for a highly available chatbot
- Security considerations - secure best practices for AWS resources.

### EC2 Spot Instances

## Distributed Locking and Leases

- Leases and Failure Detection
- Distributed locking and leases on DynamoDB to prevent multiple
  instances of the bot from responding to the same message, and
  to minimize the number of API calls to OpenAI.

## Comparison

- provide a detailed comparison between the proposed system and alternative solutions

## Future plans

- Outlining potential development and optimization

## Conclusion

- Summarizing key points and future possibilities

## Appendix
