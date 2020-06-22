#!/usr/bin/env python3

import os
from typing import Dict, Generator, List
import re
import urllib.parse
import http.client
import traceback

import boto3
import boto3.s3

BLOG_BUCKET_NAME: str = os.environ["BLOG_BUCKET_NAME"]
HOSTNAME: str = os.environ["HOSTNAME"]
KEY_RE_TO_SKIP: List[str] = [
    "\.DS_Store",
    "README\.md",
    ".br$",
    ".gz$",
]
RE_TO_SKIP = re.compile("|".join(elem for elem in KEY_RE_TO_SKIP))


def ping_url(url: str, http_conn: http.client.HTTPSConnection) -> None:
    print(f"ping_url entry. url: {url}")
    for accept_encoding in [None, "gzip, deflate", "gzip, deflate, br"]:
        headers: Dict[str, str] = {}
        if accept_encoding is not None:
            headers["Accept-Encoding"] = accept_encoding
        http_conn.request("GET", url, None, headers)
        resp = http_conn.getresponse()
        resp.read()
        print(
            f"ping_url code {resp.status}, accept_encoding {accept_encoding}, url {url}"
        )


def handler(event, context) -> None:
    print(f"BLOG_BUCKET_NAME: {BLOG_BUCKET_NAME}")
    print(f"HOSTNAME: {HOSTNAME}")

    s3 = boto3.resource("s3")
    http_conn = http.client.HTTPSConnection(HOSTNAME, 443)

    bucket: boto3.s3.Bucket = s3.Bucket(BLOG_BUCKET_NAME)
    keys = bucket.objects.all()
    matching_keys: Generator[boto3.s3.ObjectSummary] = (
        key for key in keys if RE_TO_SKIP.search(key.key) is None
    )
    urls: List[str] = ("/" + key.key for key in matching_keys)
    for url in urls:
        try:
            ping_url(url, http_conn)
        except:
            print("exception")
            traceback.print_exc()
            http_conn = http.client.HTTPSConnection(HOSTNAME, 443)

    return {}


if __name__ == "__main__":
    handler({}, None)
