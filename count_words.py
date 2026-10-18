import json, sys

path = sys.argv[1]
with open(path, encoding="utf-8") as fh:
    doc = json.load(fh)

words = []


def collect(node, flag):
    if isinstance(node, dict):
        t = node.get("t")
        if t in ("Str", "Code"):
            words.append((node["c"], flag))
            return
        if t == "Table":
            flag = True
        for key, value in node.items():
            if key == "t":
                continue
            collect(value, flag)
    elif isinstance(node, list):
        for item in node:
            collect(item, flag)


collect(doc["blocks"], False)

total = len(words)
table = sum(1 for _, f in words if f)
print(f"total words: {total}")
print(f"  in tables: {table}")
print(f"  prose:     {total - table}")
