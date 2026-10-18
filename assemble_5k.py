import re
import sys

wb_path, add_path, out_path = sys.argv[1], sys.argv[2], sys.argv[3]


def split_sections(path):
    text = open(path, encoding="utf-8").read()
    parts = re.split(r"(?m)^## ", text)
    head = parts[0]
    sections = {}
    for part in parts[1:]:
        lines = part.split("\n", 1)
        title = lines[0].strip()
        body = lines[1] if len(lines) > 1 else ""
        sections[title] = body.rstrip() + "\n"
    return head, sections


def pick(sections, prefix):
    for title in sections:
        if title.startswith(prefix):
            return title, sections[title]
    raise SystemExit(f"missing section: {prefix}")


wb_head, wb = split_sections(wb_path)
_, add = split_sections(add_path)

order = [
    ("A", "A1"),
    ("W", "2. Constraints"),
    ("W", "4. Risk"),
    ("A", "A2"),
    ("W", "3. NFRs"),
    ("A", "A3"),
    ("A", "A4"),
    ("W", "1. User Story Backlog"),
    ("W", "5. Data Dictionary"),
    ("A", "A5"),
    ("A", "A6"),
    ("W", "6. C4 Level 1"),
    ("A", "A7"),
    ("A", "A8"),
    ("W", "12. Architecture Pattern"),
    ("W", "11. Smell"),
    ("W", "13. Communication"),
    ("W", "7. Cloud Model"),
    ("A", "A9"),
    ("W", "8. Dynamic"),
    ("W", "9. STRIDE"),
    ("W", "10. Security Mitigation"),
    ("W", "17. HAZOP"),
    ("W", "16. Architectural Decision"),
    ("W", "14. Architecture Evaluation"),
    ("W", "15. ATAM"),
    ("A", "A10"),
    ("A", "A11"),
]

out = ["# Agricultural Supply Chain Tracker — Architecture Report\n"]
for src, key in order:
    title, body = pick(add if src == "A" else wb, key)
    out.append(f"## {title}\n{body}")
open(out_path, "w", encoding="utf-8").write("\n".join(out))
print(f"assembled {len(order)} sections")
