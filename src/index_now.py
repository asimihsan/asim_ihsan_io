#!/usr/bin/env python3

"""Call IndexNow on all HTML pages.
"""


import os
import os.path
from typing import List

import requests

SCRIPT_PATH: str = os.path.dirname(os.path.abspath(__file__))
FRONTEND_DIR: str = os.path.abspath(os.path.join(SCRIPT_PATH, "..", "hugo", "build"))
HOST: str = "asim.ihsan.io"
ROOT_URL: str = "https://asim.ihsan.io"
INDEX_NOW_API_KEY: str = os.getenv('INDEX_NOW_API_KEY')


def main() -> None:
    url_list: List[str] = []
    for root, _dirs, files in os.walk(FRONTEND_DIR):
        for file in files:
            fullpath: str = os.path.join(root, file)
            extension: str = os.path.splitext(fullpath)[-1]
            if extension not in {".html"}:
                continue
            print("-" * 80)
            print(fullpath)
            path: str = ROOT_URL + fullpath.partition(FRONTEND_DIR)[-1].replace("index.html", "")
            print(path)
            if any(e in path for e in ["/posts/", "/tags/", "/categories/"]):
                continue
            url_list.append(path)
    
    print(url_list)
    for url in ["https://bing.com", "https://api.indexnow.org"]:
        print(url)
        req = requests.post(url, json={
            "host": HOST,
            "key": INDEX_NOW_API_KEY,
            "keyLocation": f"{ROOT_URL}/{INDEX_NOW_API_KEY}.txt",
            "urlList": url_list,
        })
        req.raise_for_status()
        print(req)


if __name__ == "__main__":
    main()
