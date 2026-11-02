"""Derive the KJV -> am-2000 verse map that tool/build_crossrefs.dart applies.

openbible.info cross references are numbered the English (KJV) way. The
Amharic 2000 edition is not: Psalms follow the Greek numbering, Proverbs 25-31
live partly in Proverbs 24 and partly in the separate book ተግሣጽ (stored as
`4MA`), Esther, Daniel and 2 Chronicles carry the Greek additions, and a few
dozen chapters break at a different verse. Without this map about one
reference in six lands one to three verses — or a whole psalm — away.

How: am-nasv-2001 is an Amharic translation that numbers like the KJV, so its
text can be aligned verse by verse against am-2000's (same language, shared
names and phrasing). Each book is aligned with a banded dynamic programme over
word + character-bigram similarity, with a small bonus for keeping a verse on
its own number so near-identical neighbours cannot pull a match sideways.

Run (needs the 80-weahadu SQLite builds):

    python -I -X utf8 tool/versification/derive_kjv_map.py \
        D:/Projects/EOTCOpenSource/80-weahadu/dist/sqlite \
        tool/data/kjv_to_am2000.json

Output only lists verses whose number changes; anything absent maps to itself.
"""

import collections
import json
import re
import sqlite3
import sys

BOOKS = (
    "GEN EXO LEV NUM DEU JOS JDG RUT 1SA 2SA 1KI 2KI 1CH 2CH EZR NEH EST JOB "
    "PSA PRO ECC SNG ISA JER LAM EZK DAN HOS JOL AMO OBA JON MIC NAM HAB ZEP "
    "HAG ZEC MAL MAT MRK LUK JHN ACT ROM 1CO 2CO GAL EPH PHP COL 1TH 2TH 1TI "
    "2TI TIT PHM HEB JAS 1PE 2PE 1JN 2JN 3JN JUD REV"
).split()

MIN_SIM = 0.08        # below this two verses are not treated as a match
SAME_NUMBER = 0.15    # bonus for keeping a verse on its own number
WEAK = 0.12           # a Proverbs match weaker than this follows its neighbour


def grams(text):
    text = re.sub(r"[\s፡።፣፤፥፦፧፨\d.,;:!?“”\"'()\[\]«»‘’—-]+", " ", text or "").strip()
    words = text.split()
    out = set(words)
    out |= {w[i:i + 2] for w in words for i in range(len(w) - 1)}
    return out


def sim(a, b):
    return len(a & b) / len(a | b) if a and b else 0.0


def load(db, books):
    rows = collections.defaultdict(list)
    for b, ch, v, t in db.execute(
            "SELECT book, chapter, verse, text FROM verse ORDER BY book, chapter, ord"):
        if b in books and v > 0:
            rows[b].append(((ch, v), t or ""))
    return rows


def chapter_counts(db):
    return {(b, ch): n for b, ch, n in db.execute(
        "SELECT book, chapter, max(verse) FROM verse WHERE verse > 0 GROUP BY book, chapter")}


def align(src, dst):
    """Monotonic alignment of two verse lists; returns {src index: dst index}."""
    gs = [grams(t) for _, t in src]
    gd = [grams(t) for _, t in dst]
    n, m = len(src), len(dst)
    band = max(60, abs(n - m) + 60)
    prev = [0.0] * (m + 1)
    back = []
    for i in range(1, n + 1):
        cur = [0.0] * (m + 1)
        bk = bytearray(m + 1)
        centre = i * m // n
        for j in range(1, m + 1):
            best, k = prev[j], 1
            if cur[j - 1] > best:
                best, k = cur[j - 1], 2
            if abs(j - centre) <= band:
                s = sim(gs[i - 1], gd[j - 1])
                if s > MIN_SIM and src[i - 1][0] == dst[j - 1][0]:
                    s += SAME_NUMBER
                if s > MIN_SIM and prev[j - 1] + s > best:
                    best, k = prev[j - 1] + s, 3
            cur[j], bk[j] = best, k
        back.append(bk)
        prev = cur
    i, j, pairs = n, m, {}
    while i > 0 and j > 0:
        k = back[i - 1][j]
        if k == 3:
            pairs[i - 1] = j - 1
            i, j = i - 1, j - 1
        elif k == 1:
            i -= 1
        else:
            j -= 1
    # Fill the gaps between matched anchors: equal gaps pair one to one,
    # unequal ones spread proportionally, ends extend from the nearest anchor.
    anchors = [(-1, -1)] + sorted(pairs.items()) + [(n, m)]
    for (x0, y0), (x1, y1) in zip(anchors, anchors[1:]):
        gx, gy = x1 - x0 - 1, y1 - y0 - 1
        for k in range(1, gx + 1):
            if gy <= 0:
                y = y0 if y0 >= 0 else max(0, y1)
            elif gx == gy:
                y = y0 + k
            elif gx > 1:
                y = y0 + 1 + round((k - 1) * (gy - 1) / (gx - 1))
            else:
                y = y0 + 1
            pairs[x0 + k] = min(max(y, 0), m - 1)
    return pairs


def revert_slips(book, mapping, src_counts, dst_counts):
    """Undo short sideways slips inside chapters both editions number alike."""
    by_chapter = collections.defaultdict(list)
    for k, v in mapping.items():
        by_chapter[k[0]].append((k, v))
    for ch, items in by_chapter.items():
        moved = [(k, v) for k, v in items if k != v]
        if not moved or src_counts.get((book, ch)) != dst_counts.get((book, ch)):
            continue
        if any(v[0] != ch for _, v in moved):
            continue
        verses = sorted(k[1] for k, _ in moved)
        run = longest = 0
        last = None
        for x in verses:
            run = run + 1 if last == x - 1 else 1
            longest = max(longest, run)
            last = x
        if longest <= 3:
            for k, _ in items:
                mapping[k] = k


def proverbs_tail(src_rows, am):
    """KJV Proverbs 24:23-31:31 -> Proverbs 24 (Greek order) or ተግሣጽ (4MA)."""
    cand = [(("PRO", ch, v), t) for ch, v, t in am.execute(
        "SELECT chapter, verse, text FROM verse WHERE book='PRO' AND chapter=24 AND verse>0 ORDER BY ord")]
    cand += [(("4MA", ch, v), t) for ch, v, t in am.execute(
        "SELECT chapter, verse, text FROM verse WHERE book='4MA' AND verse>0 ORDER BY chapter, ord")]
    gc = [grams(t) for _, t in cand]
    out, prev_j, prev_ch = {}, None, None
    for (ch, v), t in src_rows:
        if ch < 24 or (ch == 24 and v <= 22):
            continue
        g = grams(t)
        best = max(range(len(cand)), key=lambda j: sim(g, gc[j]))
        s = sim(g, gc[best])
        if s < WEAK and prev_j is not None and prev_ch == ch and prev_j + 1 < len(cand):
            best = prev_j + 1
        prev_j, prev_ch = best, ch
        out[(ch, v)] = [cand[best][0], s]
    keys = list(out)
    for i, k in enumerate(keys[:-1]):
        (b1, c1, v1), s1 = out[keys[i + 1]]
        if out[k][1] < WEAK and k[1] == 1 and s1 >= WEAK and v1 > 1:
            out[k] = [(b1, c1, v1 - 1), out[k][1]]
    return {k: target for k, (target, _) in out.items()}


def main(sqlite_dir, out_path):
    nasv = sqlite3.connect(f"{sqlite_dir}/am-nasv-2001.db")
    am = sqlite3.connect(f"{sqlite_dir}/am-2000.db")
    src, dst = load(nasv, set(BOOKS)), load(am, set(BOOKS))
    src_counts, dst_counts = chapter_counts(nasv), chapter_counts(am)
    result = {}
    for book in BOOKS:
        s, d = src[book], dst[book]
        pairs = align(s, d)
        mapping = {s[x][0]: d[pairs[x]][0] for x in range(len(s))}
        revert_slips(book, mapping, src_counts, dst_counts)
        result[book] = {k: (book,) + v for k, v in mapping.items()}
        print(f"{book}: {sum(1 for k, v in mapping.items() if k != v)} renumbered", flush=True)

    # Proverbs 24:23 onwards leave the Proverbs book in the Ethiopic canon.
    for k, target in proverbs_tail(src["PRO"], am).items():
        result["PRO"][k] = target

    # am-nasv-2001 glues KJV Psalm 117 onto 118 and drops 118:1-2, so set
    # those two psalms by hand: Greek 116 is KJV 117, Greek 117 is KJV 118.
    for v in (1, 2):
        result["PSA"][(117, v)] = ("PSA", 116, v)
    for v in range(1, 30):
        result["PSA"][(118, v)] = ("PSA", 117, v)

    compact = {}
    for book, mapping in result.items():
        moved = {f"{ch}:{v}": (f"{t[1]}:{t[2]}" if t[0] == book else f"{t[0]} {t[1]}:{t[2]}")
                 for (ch, v), t in sorted(mapping.items()) if t != (book, ch, v)}
        if moved:
            compact[book] = moved
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump({
            "_about": "KJV verse -> am-2000 verse, for openbible.info cross references. "
                      "Only renumbered verses are listed; absent verses map to themselves. "
                      "Built by tool/versification/derive_kjv_map.py.",
            **compact,
        }, f, ensure_ascii=False, indent=1, sort_keys=False)
    print("renumbered verses:", sum(len(m) for m in compact.values()))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
