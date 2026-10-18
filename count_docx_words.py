import sys
from docx import Document
from docx.table import Table
from docx.text.paragraph import Paragraph
from docx.oxml.ns import qn


def iter_blocks(parent):
    body = parent.element.body
    for child in body.iterchildren():
        if child.tag == qn("w:p"):
            yield Paragraph(child, parent)
        elif child.tag == qn("w:tbl"):
            yield Table(child, parent)


def words(text):
    return [w for w in text.split() if w.strip()]


doc = Document(sys.argv[1])
total = 0
table = 0
para = 0
headings = 0
for block in iter_blocks(doc):
    if isinstance(block, Table):
        for row in block.rows:
            for cell in row.cells:
                n = len(words(cell.text))
                total += n
                table += n
    else:
        n = len(words(block.text))
        total += n
        para += n
        if block.style.name.lower().startswith("heading"):
            headings += n

print(f"total words (Word-style): {total}")
print(f"  in tables:              {table}")
print(f"  in paragraphs:          {para}")
print(f"  of which headings:      {headings}")
print(f"  prose excluding tables: {total - table}")
