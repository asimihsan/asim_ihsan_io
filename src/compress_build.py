#!/usr/bin/env python3

"""Compress files in the build directory with GZIP and Brotli, leave duplicate files in there.

That way we can ask CloudFront to redirect requests to the appropriately compressed file if the client requests it via
Accept-Encoding.
"""


import os
import os.path
import gzip
from typing import ByteString, Set

import brotli

SCRIPT_PATH = os.path.dirname(os.path.abspath(__file__))
FRONTEND_DIR = os.path.abspath(os.path.join(SCRIPT_PATH, "..", "hugo", "build"))


def brotli_compress(contents: ByteString, extension: str, destination: str) -> None:
    quality: int
    if extension == ".woff2":
        mode = brotli.MODE_GENERIC
        quality = 0
    elif extension in {".html"}:
        mode = brotli.MODE_TEXT
        quality = 11
    else:
        mode = brotli.MODE_GENERIC
        quality = 11
    brotli_compressed = brotli.compress(contents, mode=mode, quality=quality)
    with open(destination, "wb") as f_out:
        f_out.write(brotli_compressed)


def gzip_compress(contents: ByteString, extension: str, destination: str) -> None:
    gzip_compressed = gzip.compress(contents)
    with open(destination, "wb") as f_out:
        f_out.write(gzip_compressed)


def compress() -> None:
    # Compress all frontend files
    compressed_extensions: Set[str] = {".gz", ".br"}
    for root, dirs, files in os.walk(FRONTEND_DIR):
        for file in files:
            fullpath: str = os.path.join(root, file)
            extension: str = os.path.splitext(fullpath)[-1]
            if extension in compressed_extensions:
                print(f"skip already compressed f{fullpath}")
                continue

            brotli_path: str = fullpath + ".br"
            gzip_path: str = fullpath + ".gz"
            if all(os.path.isfile(elem) for elem in [brotli_path, gzip_path]):
                print(f"file already compressed, skipping f{fullpath}")
                continue

            print(f"handling file: {fullpath}")
            with open(fullpath, "rb") as f_in:
                contents = f_in.read()
            if not os.path.isfile(brotli_path):
                brotli_compress(contents, extension, brotli_path)
            if not os.path.isfile(gzip_path):
                gzip_compress(contents, extension, gzip_path)


def main() -> None:
    compress()


if __name__ == "__main__":
    main()
