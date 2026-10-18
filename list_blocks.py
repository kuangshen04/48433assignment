import sys
from docx import Document
from docx.table import Table
from docx.text.paragraph import Paragraph
from docx.oxml.ns import qn


def iter_blocks(doc):
    for child in doc.element.body.iterchildren():
        if child.tag == qn("w:p"):
            yield Paragraph(child, doc)
        elif child.tag == qn("w:tbl"):
            yield Table(child, doc)


doc = Document(sys.argv[1])
section = "(front)"
rows = []
for block in iter_blocks(doc):
    if isinstance(block, Table):
        n = sum(len(c.text.split()) for row in block.rows for c in row.cells)
        rows.append((section, "TABLE", n, block.rows[0].cells[0].text[:40].replace("\n", " ")))
        continue
    if block.style.name.lower().startswith("heading"):
        section = block.text.strip()[:44]
        continue
    n = len(block.text.split())
    if n:
        rows.append((section, "para", n, block.text.strip()[:70].replace("\n", " ")))

rows.sort(key=lambda r: -r[2])
print(f"{'words':>5}  {'kind':5}  section / opening")
for sec, kind, n, txt in rows[:24]:
    print(f"{n:5}  {kind:5}  [{sec[:30]}] {txt}")
print()
print("total blocks:", len(rows))
