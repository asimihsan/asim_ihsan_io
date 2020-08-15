#!/usr/bin/env python3

"""
Usage

(cd hugo && hugo --buildDrafts --destination build) && ./src/analyze_post.py ./hugo/build/posts/breathing/index.json
"""

from typing import List
import json
import os.path
import pprint
import sys

from bs4 import BeautifulSoup
from spacy.lang.en import English
import bs4
import readability
import spacy
from termcolor import colored


thresholds_lookup = {
    "FleschReadingEase": [100, 60, 50, 0],
    "GunningFogIndex": [6, 8, 12, 17],
    "SMOGIndex": [6, 8, 12, 17],
    "Coleman-Liau": [6, 8, 12, 17],
}

def get_sentences(input: str, nlp: spacy.language.Language) -> List[str]:
    doc = nlp(input)
    return [sentence.text for sentence in doc.sents]

def main() -> None:
    post_path: str = sys.argv[1]

    print("\033[H\033[J")
    print('-' * 80)
    print('post: {}'.format(post_path))
    print('-' * 80)

    with open(post_path) as f_in:
        data = json.load(f_in)
    content: str = data["content"]
    soup = BeautifulSoup(content, features="lxml")

    # Last line is at the bottom of the article before footnotes, so delete
    # all footnotes
    last_line: bs4.element.Tag = soup.find_all("hr")[-1]
    for elem in last_line.find_all_next():
        elem.decompose()

    paragraphs = soup.find_all(['p', 'li'])

    # Delete footnote links
    for paragraph in paragraphs:
        for footnote_link in paragraph.find_all('sup'):
            footnote_link.decompose()

    paragraph_strings: List[str] = [p.get_text().replace('\n', ' ') for p in paragraphs]
    for paragraph_string in paragraph_strings:
        print(paragraph_string + "\n\n")

    nlp = English()
    sentencizer = nlp.create_pipe("sentencizer")
    nlp.add_pipe(sentencizer)
    sentences: List[str] = [sentence
                            for paragraph_string in paragraph_strings
                            for sentence in get_sentences(paragraph_string, nlp)]

    readability_results = readability.getmeasures(sentences, lang='en')
    #pprint.pprint(readability_results)

    print(f"words: {readability_results['sentence info']['words']}")
    for (key, value) in readability_results['readability grades'].items():
        if key in thresholds_lookup:
            thresholds = thresholds_lookup[key]
            for i, pair in enumerate(zip(thresholds, thresholds[1:])):
                if (value >= pair[0] and value <= pair[1]) or (pair[0] >= value and pair[1] <= value):
                    if i == 0:
                        print(colored("{}: {:.2f}".format(key, value), "green"))
                    elif i == 1:
                        print(colored("{}: {:.2f}".format(key, value), "yellow"))
                    else:
                        print(colored("{}: {:.2f}".format(key, value), "red"))    

if __name__ == "__main__":
    main()