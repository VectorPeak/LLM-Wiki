# SKILL解读-02-PDF Skill 深度解读

## 目录

1. 概览
2. 目录结构
3. 文件逐一解读
   3.1 `SKILL.md` - 技能主文件
   3.1.1 YAML 前置元数据
   3.1.2 概览与导航
   3.1.3 Quick Start - 快速入门
   3.1.4 Python 库指南
   3.1.5 命令行工具
   3.1.6 常见任务
   3.1.7 快速参考表
   3.1.8 后续参考
   3.2 `forms.md` - 表单填写工作流
   3.2.0 入口指令
   3.2.1 可填写表单（Fillable Fields）
   3.2.2 不可填写表单（Non-Fillable Fields）
   3.2.3 通用后续步骤（Step 2-4）
   3.3 `reference.md` - 高级参考文档
   3.3.3 命令行高级操作
   3.3.4 Python 高级技巧
   3.3.5 复杂工作流
   3.3.6 性能优化建议
   3.3.7 故障排除
   3.3.8 许可证信息
   3.4 `LICENSE.txt` - 许可证
4. 脚本文件详解
   4.1 `check_fillable_fields.py` - 表单域检测
   4.2 `convert_pdf_to_images.py` - PDF 转图片
   4.3 `extract_form_field_info.py` - 可填写表单域信息提取
   4.4 `extract_form_structure.py` - 不可填写表单结构提取
   4.5 `check_bounding_boxes.py` - 边界框验证
   4.6 `create_validation_image.py` - 验证图片生成
   4.7 `fill_pdf_form_with_annotations.py` - 注释方式填写表单
   4.8 `fill_fillable_fields.py` - 原生表单域填写
5. 整体架构与设计哲学
   5.1 流程图
   5.2 设计亮点
6. 深层分析

## 1. 概览

`pdf` 是一个专注于 PDF 文件处理的 Claude Code Skill，涵盖了 PDF 的读取、文本/表格提取、合并、拆分、旋转、水印添加、创建、表单填写、加密/解密、图片提取和 OCR 识别等全套操作。

许可证：Anthropic 专有许可（Proprietary）

## 2. 目录结构

```text
pdf/
├── SKILL.md                              # 技能主文件：快速入门与核心指南
├── forms.md                             # 表单填写完整工作流指南
├── reference.md                         # 高级参考文档（进阶库和技巧）
├── LICENSE.txt                          # Anthropic 专有许可证
└── scripts/                             # 8 个 Python 工具脚本
    ├── check_fillable_fields.py         # 检测 PDF 是否有可填写表单域
    ├── convert_pdf_to_images.py         # PDF 转 PNG 图片
    ├── extract_form_field_info.py       # 提取可填写表单域信息
    ├── extract_form_structure.py        # 提取不可填写 PDF 的表单结构
    ├── check_bounding_boxes.py          # 验证边界框的有效性
    ├── create_validation_image.py       # 生成带边界框标注的验证图片
    ├── fill_fillable_fields.py          # 填写可填写的 PDF 表单
    └── fill_pdf_form_with_annotations.py # 通过文本注释填写不可填写的表单
```

这个 Skill 的结构明显比前面的 `frontend-design` 复杂得多。它是一个“工具型 Skill”，不是靠纯 prompt 引导，而是靠主说明文件 + 工作流文档 + 高级参考 + 多个脚本工具共同协作。

## 3. 文件逐一解读

### 3.1 `SKILL.md` - 技能主文件

这是整个 Skill 的入口文件，包含 YAML 前置元数据和核心使用指南。

#### 3.1.1 YAML 前置元数据

```yaml
---
name: pdf
description: Use this skill whenever the user wants to do anything with PDF
  files.
  This includes reading or extracting text/tables from PDFs, combining or
  merging multiple PDFs into one, splitting PDFs apart, rotating pages, adding
  watermarks, creating new PDFs, filling PDF forms, encrypting/decrypting PDFs,
  extracting images, and OCR on scanned PDFs to make them searchable. If the user mentions
  a .pdf file or asks to produce one, use this skill.
license: Proprietary. LICENSE.txt has complete terms
---
```

译文：当用户想对 PDF 文件执行任何操作时，使用此技能。包括读取或提取 PDF 中的文本/表格、合并多个 PDF 为一个、拆分 PDF、旋转页面、添加水印、创建新 PDF、填写 PDF 表单、加密/解密 PDF、提取图片，以及对扫描件 PDF 进行 OCR 使其可搜索。如果用户提到 `.pdf` 文件或要求生成一个，请使用此技能。

这个描述的覆盖范围非常广，几乎把所有常见 PDF 处理需求都包进来了。

#### 3.1.2 概览与导航

原文：

```text
# PDF Processing Guide

## Overview

This guide covers essential PDF processing operations using Python libraries
and command-line tools. For advanced features, JavaScript libraries, and
detailed examples, see REFERENCE.md. If you need to fill out a PDF form,
read FORMS.md and follow its instructions.
```

译文：本指南涵盖使用 Python 库和命令行工具进行 PDF 处理的基本操作。高级功能、JavaScript 库和详细示例请参见 `REFERENCE.md`。如果需要填写 PDF 表单，请阅读 `FORMS.md` 并遵循其说明。

这部分相当于导航页，明确告诉模型：

- 基础操作看 `SKILL.md`
- 高级能力看 `REFERENCE.md`
- 表单填写走 `FORMS.md`

#### 3.1.3 Quick Start - 快速入门

```python
from pypdf import PdfReader, PdfWriter

# Read a PDF
reader = PdfReader("document.pdf")
print(f"Pages: {len(reader.pages)}")

# Extract text
text = ""
for page in reader.pages:
    text += page.extract_text()
```

使用 `pypdf` 两步完成 PDF 读取与文本提取：实例化 `PdfReader` 后遍历 `pages`，调用 `extract_text()` 即可。

#### 3.1.4 Python 库指南

##### 3.1.4.1 pypdf - 基础操作

合并 PDF：

```python
from pypdf import PdfWriter, PdfReader

writer = PdfWriter()
for pdf_file in ["doc1.pdf", "doc2.pdf", "doc3.pdf"]:
    reader = PdfReader(pdf_file)
    for page in reader.pages:
        writer.add_page(page)

with open("merged.pdf", "wb") as output:
    writer.write(output)
```

拆分 PDF：

```python
reader = PdfReader("input.pdf")
for i, page in enumerate(reader.pages):
    writer = PdfWriter()
    writer.add_page(page)
    with open(f"page_{i+1}.pdf", "wb") as output:
        writer.write(output)
```

提取元数据：

```python
reader = PdfReader("document.pdf")
meta = reader.metadata
print(f"Title: {meta.title}")
print(f"Author: {meta.author}")
print(f"Subject: {meta.subject}")
print(f"Creator: {meta.creator}")
```

旋转页面：

```python
reader = PdfReader("input.pdf")
writer = PdfWriter()

page = reader.pages[0]
page.rotate(90)  # Rotate 90 degrees clockwise
writer.add_page(page)

with open("rotated.pdf", "wb") as output:
    writer.write(output)
```

可以看出，`pypdf` 在这个 Skill 里被定义为“基础操作工具”：读、写、合并、拆分、旋转、元数据获取。

##### 3.1.4.2 pdfplumber - 文本与表格提取

带布局提取文本：

```python
import pdfplumber

with pdfplumber.open("document.pdf") as pdf:
    for page in pdf.pages:
        text = page.extract_text()
        print(text)
```

提取表格：

```python
with pdfplumber.open("document.pdf") as pdf:
    for i, page in enumerate(pdf.pages):
        tables = page.extract_tables()
        for j, table in enumerate(tables):
            print(f"Table {j+1} on page {i+1}:")
            for row in table:
                print(row)
```

高级表格提取：

```python
import pandas as pd

with pdfplumber.open("document.pdf") as pdf:
    all_tables = []
    for page in pdf.pages:
        tables = page.extract_tables()
        for table in tables:
            if table:  # Check if table is not empty
                df = pd.DataFrame(table[1:], columns=table[0])
                all_tables.append(df)

# Combine all tables
if all_tables:
    combined_df = pd.concat(all_tables, ignore_index=True)
    combined_df.to_excel("extracted_tables.xlsx", index=False)
```

将所有页的表格提取后合并为单个 DataFrame，最终导出为 Excel 文件。

##### 3.1.4.3 reportlab - 创建 PDF

基础 PDF 创建：

```python
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

c = canvas.Canvas("hello.pdf", pagesize=letter)
width, height = letter

# Add text
c.drawString(100, height - 100, "Hello World!")
c.drawString(100, height - 120, "This is a PDF created with reportlab")

# Add a line
c.line(100, height - 140, 400, height - 140)

# Save
c.save()
```

多页 PDF：

```python
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
from reportlab.lib.styles import getSampleStyleSheet

doc = SimpleDocTemplate("report.pdf", pagesize=letter)
styles = getSampleStyleSheet()
story = []

# Add content
title = Paragraph("Report Title", styles["Title"])
story.append(title)
story.append(Spacer(1, 12))

body = Paragraph("This is the body of the report. " * 20, styles["Normal"])
story.append(body)
story.append(PageBreak())

# Page 2
story.append(Paragraph("Page 2", styles["Heading1"]))
story.append(Paragraph("Content for page 2", styles["Normal"]))

# Build PDF
doc.build(story)
```

上下标注意事项：

```text
IMPORTANT: Never use Unicode subscript/superscript characters
(₀₁₂₃₄₅₆₇₈₉, ⁰¹²³⁴⁵⁶⁷⁸⁹) in ReportLab PDFs. The built-in fonts
do not include these glyphs, causing them to render as solid black boxes.

Instead, use ReportLab's XML markup tags in Paragraph objects.

For canvas-drawn text (not Paragraph objects), manually adjust font
the size and position rather than using Unicode subcripts/superscripts.
```

译文：不要在 ReportLab PDF 中使用 Unicode 上下标字符。内置字体不包含这些字形，会导致渲染为实心黑色方块。应改用 ReportLab 在 `Paragraph` 对象中的 XML 标记标签；对于 canvas 绘制的文字（非 Paragraph 对象），手动调整字体大小和位置，而不是使用 Unicode 上下标字符。

示例：

```python
from reportlab.platypus import Paragraph
from reportlab.lib.styles import getSampleStyleSheet

styles = getSampleStyleSheet()

# Subscripts: use <sub> tag
chemical = Paragraph("H<sub>2</sub>O", styles["Normal"])

# Superscripts: use <super> tag
squared = Paragraph("x<super>2</super> + y<super>2</super>", styles["Normal"])
```

这段细节很关键，说明这个 Skill 不只是给出“怎么做”，还会提前规避 PDF 渲染中的坑。

#### 3.1.5 命令行工具

##### 3.1.5.1 pdftotext（poppler-utils）

```text
# Extract text
pdftotext input.pdf output.txt

# Extract text preserving layout
pdftotext -layout input.pdf output.txt

# Extract specific pages
pdftotext -f 1 -l 5 input.pdf output.txt  # Pages 1-5
```

##### 3.1.5.2 qpdf

```text
# Merge PDFs
qpdf --empty --pages file1.pdf file2.pdf -- merged.pdf

# Split pages
qpdf input.pdf --pages . 1-5 -- pages1-5.pdf
qpdf input.pdf --pages . 6-10 -- pages6-10.pdf

# Rotate pages
qpdf input.pdf output.pdf --rotate=+90:1  # Rotate page 1 by 90 degrees

# Remove password
qpdf --password=mypassword --decrypt encrypted.pdf decrypted.pdf
```

##### 3.1.5.3 pdftk（if available）

```text
# Merge
pdftk file1.pdf file2.pdf cat output merged.pdf

# Split
pdftk input.pdf burst

# Rotate
pdftk input.pdf rotate east output rotated.pdf
```

命令行工具这一段的价值在于：有些场景里 shell 工具比 Python 库更直接、更稳定，特别适合快速批处理。

#### 3.1.6 常见任务

OCR 识别扫描件：

```python
# Requires: pip install pytesseract pdf2image
import pytesseract
from pdf2image import convert_from_path

# Convert PDF to images
images = convert_from_path("scanned.pdf")

# OCR each page
text = ""
for i, image in enumerate(images):
    text += f"Page {i+1}:\n"
    text += pytesseract.image_to_string(image)
    text += "\n\n"

print(text)
```

添加水印：

```python
from pypdf import PdfReader, PdfWriter

# Create watermark (or load existing)
watermark = PdfReader("watermark.pdf").pages[0]

# Apply to all pages
reader = PdfReader("document.pdf")
writer = PdfWriter()

for page in reader.pages:
    page.merge_page(watermark)
    writer.add_page(page)

with open("watermarked.pdf", "wb") as output:
    writer.write(output)
```

提取嵌入图片：

```text
# Using pdfimages (poppler-utils)
pdfimages -j input.pdf output_prefix

# This extracts all images as output_prefix-000.jpg, output_prefix-001.jpg, etc.
```

密码保护：

```python
from pypdf import PdfReader, PdfWriter

reader = PdfReader("input.pdf")
writer = PdfWriter()

for page in reader.pages:
    writer.add_page(page)

# Add password
writer.encrypt("userpassword", "ownerpassword")

with open("encrypted.pdf", "wb") as output:
    writer.write(output)
```

#### 3.1.7 快速参考表

| 任务 | 最佳工具 | 命令/代码 |
| --- | --- | --- |
| 合并 PDF | pypdf | `writer.add_page(page)` |
| 拆分 PDF | pypdf | 每页一个文件 |
| 提取文本 | pdfplumber | `page.extract_text()` |
| 提取表格 | pdfplumber | `page.extract_tables()` |
| 创建 PDF | reportlab | Canvas 或 Platypus |
| 命令行合并 | qpdf | `qpdf --empty --pages ...` |
| OCR 扫描件 | pytesseract | 先转换为图片 |
| 填写 PDF 表单 | pdf-lib 或 pypdf | 见 `FORMS.md` |

#### 3.1.8 后续参考

```text
## Next Steps

- For advanced pypdfium2 usage, see REFERENCE.md
- For JavaScript libraries (pdf-lib), see REFERENCE.md
- If you need to fill out a PDF form, follow the instructions in FORMS.md
- For troubleshooting guides, see REFERENCE.md
```

译文：

- 高级 `pypdfium2` 用法，见 `REFERENCE.md`
- JavaScript 库（`pdf-lib`），见 `REFERENCE.md`
- 如需填写 PDF 表单，请遵循 `FORMS.md` 中的说明
- 故障排除指南，见 `REFERENCE.md`

### 3.2 `forms.md` - 表单填写工作流

这是整个 Skill 中最复杂也最精华的部分，定义了一套严格的分步流程来处理 PDF 表单填写。

核心设计思路：先判断表单类型（可填写/不可填写），然后分别走不同的处理管线。

#### 3.2.0 入口指令

```text
CRITICAL: You MUST complete these steps in order. Do not skip ahead to writing code.

If you need to fill out a PDF form, first check to see if the PDF has fillable
form fields. Run this script from this file's directory:
    python scripts/check_fillable_fields <file.pdf>
and depending on the result go to either the "Fillable fields" or
"Non-fillable fields" and follow those instructions.
```

译文：关键：必须按顺序完成以下步骤，不得跳步直接写代码。填写 PDF 表单前，先检测 PDF 是否有可填写的表单域。从当前文件所在目录运行：

```bash
python scripts/check_fillable_fields <file.pdf>
```

然后根据结果进入“可填写表单域”或“不可填写表单域”章节。

#### 3.2.1 可填写表单（Fillable Fields）

如果 PDF 有可填写表单域，从当前文件目录运行字段提取脚本，生成包含字段列表的 JSON 文件：

```bash
python scripts/extract_form_field_info.py <input.pdf> <field_info.json>
```

字段信息 JSON 格式：

```json
[
  {
    "field_id": "(unique ID for the field)",
    "page": "(page number, 1-based)",
    "rect": "[left, bottom, right, top] bounding box in PDF coordinates, y=0 is the bottom of the page",
    "type": "text | checkbox | radio_group | choice"
  },
  {
    "field_id": "(unique ID)",
    "page": 1,
    "type": "checkbox",
    "checked_value": "(set field to this value to check the checkbox)",
    "unchecked_value": "(set field to this value to uncheck the checkbox)"
  },
  {
    "field_id": "(unique ID)",
    "page": 1,
    "type": "radio_group",
    "radio_options": [
      {
        "value": "(set field to this value to select this radio option)",
        "rect": "(bounding box for the radio button for this option)"
      }
    ]
  },
  {
    "field_id": "(unique ID)",
    "page": 1,
    "type": "choice",
    "choice_options": [
      {
        "value": "(set field to this value to select this option)",
        "text": "(display text of the option)"
      }
    ]
  }
]
```

后续步骤：

1. 将 PDF 每页转为 PNG，分析每个表单域用途：

```bash
python scripts/convert_pdf_to_images.py <file.pdf> <output_directory>
```

2. 创建 `field_values.json`，指定每个字段要填入的值。

3. 运行填写脚本：

```bash
python scripts/fill_fillable_fields.py <input_pdf> <field_values.json> <output_pdf>
```

该脚本会校验字段 ID 和值是否合法；如果打印错误信息，需修正字段后重试。

`field_values.json` 示例：

```json
[
  {
    "field_id": "last_name",
    "description": "The user's last name",
    "page": 1,
    "value": "Simpson"
  },
  {
    "field_id": "Checkbox12",
    "description": "Checkbox to be checked if the user is 18 or over",
    "page": 1,
    "value": "/On"
  }
]
```

#### 3.2.2 不可填写表单（Non-Fillable Fields）

如果 PDF 没有可填写表单域，需要通过添加文本注释来填写。优先从 PDF 结构中提取坐标（更准确），如有必要再退回到视觉估算。

##### 3.2.2.0 Step 1 - 结构提取尝试

```bash
python scripts/extract_form_structure.py <input.pdf> form_structure.json
```

这个 JSON 会包含：

- `labels`：所有文本元素坐标
- `lines`：水平线/行边界
- `checkboxes`：小方形框及中心坐标
- `row_boundaries`：由水平线推导出的行边界

判断原则：

- 如果 `form_structure.json` 中有意义的标签（文本元素能对应字段），使用方案 A：结构坐标
- 如果 PDF 是扫描件/图像型，文本像 `(cid:x)` 乱码或基本不可用，使用方案 B：视觉估算

##### 3.2.2.1 方案 A - 结构坐标（首选）

适用条件：`extract_form_structure.py` 找到了文本标签。

坐标系说明：PDF 坐标，`y=0` 在页面顶部，向下增大。

A.1 分析结构：

1. 标签组：相邻文本合并为一个标签，例如 `Last` + `Name`
2. 行结构：相同 `top` 值附近的标签视为同一行
3. 字段列：输入区从标签结尾处开始
4. 复选框：直接使用结构中提取的复选框坐标

A.2 检查缺失元素：

- 圆形复选框：脚本通常只识别方形框
- 复杂图形：装饰性元素或非标准控件可能提取不到
- 浅色或褪色元素：可能被漏掉

如果在 PDF 图像中看到了 `form_structure.json` 没有的字段，必须对那些字段回退到视觉分析（见混合方案）。

A.3 创建 `fields.json`（PDF 坐标）：

文本字段：

- `entry_x0 = label_x1 + 5`
- `entry_x1 = next label's x0` 或行边界
- `entry_top = same as label top`
- `entry_bottom = row boundary line below`，或 `label bottom + row_height`

复选框：

- 直接使用 `form_structure.json` 里的矩形框坐标

统一使用 `pdf_width` / `pdf_height` 标记为 PDF 坐标系。

`fields.json` 示例（PDF 坐标）：

```json
{
  "pages": [
    {"page_number": 1, "pdf_width": 612, "pdf_height": 792}
  ],
  "form_fields": [
    {
      "page_number": 1,
      "description": "Last name entry field",
      "field_label": "Last Name",
      "label_bounding_box": [43, 63, 87, 73],
      "entry_bounding_box": [92, 63, 260, 79],
      "entry_text": {"text": "Smith", "font_size": 10}
    },
    {
      "page_number": 1,
      "description": "US Citizen Yes checkbox",
      "field_label": "Yes",
      "label_bounding_box": [260, 200, 280, 210],
      "entry_bounding_box": [285, 197, 292, 205],
      "entry_text": {"text": "X"}
    }
  ]
}
```

A.4 验证边界框：

```bash
python scripts/check_bounding_boxes.py fields.json
```

这个脚本会检查：

- 边界框是否相交
- `entry` 框是否过小以至于无法容纳字体

##### 3.2.2.2 方案 B - 视觉估算（备用）

适用条件：PDF 是扫描件/图像型，结构提取没有找到可用文本标签（例如全部显示为 `(cid:X)` 模式）。

B.1 将 PDF 转为图片：

```bash
python scripts/convert_pdf_to_images.py <input.pdf> <images_dir/>
```

B.2 初始字段识别：

- 表单字段标签和其大致位置
- 文本输入区（线条、框线、留白区）
- 复选框及其大概位置

B.3 放大精修（精度关键）：

对每个字段，在估计位置周围裁切一个局部区域，再精细判断。

ImageMagick 裁切命令：

```bash
magick <page_image> -crop <width>x<height>+<x>+<y> +repage <crop_output.png>
# 若 magick 不可用，改用 convert 命令，参数相同
# 例：对估值框左（100,150）附近的 Name 字段进行裁切放大
magick images_dir/page_1.png -crop 300x80+50+120 +repage crops/name_field.png
```

需要精确识别：

1. 输入区域起始像素位置（标签后）
2. 输入区域结束位置（下一字段前或页边）
3. 输入行/框的上、下边界

将裁切坐标还原成完整图片坐标：

- `full_x = crop_x + crop_offset_x`
- `full_y = crop_y + crop_offset_y`

示例：如果裁切从 `(50,120)` 开始，而输入框在裁切图中是 `(52,18)`，那么：

- `entry_x0 = 52 + 50 = 102`
- `entry_top = 18 + 120 = 138`

相邻字段可尽量合并裁切，减少重复工作。

`fields.json` 示例（图片坐标）：

```json
{
  "pages": [
    {"page_number": 1, "image_width": 1700, "image_height": 2200}
  ],
  "form_fields": [
    {
      "page_number": 1,
      "description": "Last name entry field",
      "field_label": "Last Name",
      "label_bounding_box": [120, 175, 242, 198],
      "entry_bounding_box": [255, 175, 720, 218],
      "entry_text": {"text": "Smith", "font_size": 10}
    }
  ]
}
```

B.5 填写前验证边界框：

```bash
python scripts/check_bounding_boxes.py fields.json
```

##### 3.2.3 混合方案（Hybrid Approach）

适用条件：结构提取能处理大多数字段，但遗漏了少数元素，例如圆形复选框、特殊控件等。

策略：

1. 已在 `form_structure.json` 中检测到的字段，使用方案 A
2. 对遗漏字段转图后，用方案 B 的裁切放大法
3. 对视觉估算得到的像素坐标做比例换算：

```text
pdf_x = image_x * (pdf_width / image_width)
pdf_y = image_y * (pdf_height / image_height)
```

4. 最终统一到同一个 `fields.json` 中，全部写成 PDF 坐标并带上 `pdf_width` / `pdf_height`

#### 3.2.3 通用后续步骤（Step 2-4）

Step 2 - 填写前验证：

```bash
python scripts/check_bounding_boxes.py fields.json
```

检查内容：

- 相交的边界框（会导致文本重叠）
- `entry` 过小，无法容纳指定字体

Step 3 - 填写表单：

```bash
python scripts/fill_pdf_form_with_annotations.py <input.pdf> fields.json <output.pdf>
```

脚本会自动检测坐标系并处理转换。

Step 4 - 验证输出：

```bash
python scripts/convert_pdf_to_images.py <output.pdf> <verify_images/>
```

再目视确认文字位置。若文字错位：

- 方案 A：检查是否正确使用了 `form_structure.json` 的 PDF 坐标与 `pdf_width/pdf_height`
- 方案 B：检查图像尺寸是否一致，像素坐标是否准确
- 混合方案：检查视觉估算坐标到 PDF 坐标的换算是否正确

### 3.3 `reference.md` - 高级参考文档

这个文档包含主技能文件未涉及的高级 PDF 处理功能、详细示例和额外库。

#### 3.3.1 pypdfium2 库（Apache/BSD 许可）

```text
pypdfium2 is a Python binding for PDFium (Chromium's PDF library).
It's excellent for fast PDF rendering, image generation, and serves
as a PyMuPDF replacement.
```

译文：`pypdfium2` 是 PDFium（Chromium 的 PDF 库）的 Python 绑定，非常适合快速 PDF 渲染和图片生成，也可作为 PyMuPDF 的替代。

渲染 PDF 为图片：

```python
import pypdfium2 as pdfium
from PIL import Image

# Load PDF
pdf = pdfium.PdfDocument("document.pdf")

# Render page to image
page = pdf[0]  # First page
bitmap = page.render(
    scale=2.0,  # Higher resolution
    rotation=0  # No rotation
)

# Convert to PIL Image
img = bitmap.to_pil()
img.save("page_1.png", "PNG")

# Process multiple pages
for i, page in enumerate(pdf):
    bitmap = page.render(scale=1.5)
    img = bitmap.to_pil()
    img.save(f"page_{i+1}.jpg", "JPEG", quality=90)
```

提取文本：

```python
import pypdfium2 as pdfium

pdf = pdfium.PdfDocument("document.pdf")
for i, page in enumerate(pdf):
    text = page.get_text()
    print(f"Page {i+1} text length: {len(text)} chars")
```

#### 3.3.2 JavaScript 库

##### 3.3.2.1 pdf-lib（MIT 许可）

```text
pdf-lib is a powerful JavaScript library for creating and modifying PDF
documents in any JavaScript environment.
```

译文：`pdf-lib` 是一个功能强大的 JavaScript 库，可在任何 JavaScript 环境中创建和修改 PDF 文档。

加载与操作现有 PDF：

```javascript
import { PDFDocument } from 'pdf-lib';
import fs from 'fs';

async function manipulatePDF() {
  const existingPdfBytes = fs.readFileSync('input.pdf');
  const pdfDoc = await PDFDocument.load(existingPdfBytes);

  const pageCount = pdfDoc.getPageCount();
  console.log(`Document has ${pageCount} pages`);

  const newPage = pdfDoc.addPage([600, 400]);
  newPage.drawText('Added by pdf-lib', { x: 100, y: 300, size: 16 });

  const pdfBytes = await pdfDoc.save();
  fs.writeFileSync('modified.pdf', pdfBytes);
}
```

从零创建复杂 PDF：

```javascript
import { PDFDocument, rgb, StandardFonts } from 'pdf-lib';
import fs from 'fs';

async function createPDF() {
  const pdfDoc = await PDFDocument.create();

  const helveticaFont = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const helveticaBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

  const page = pdfDoc.addPage([595, 842]); // A4 size
  const { width, height } = page.getSize();

  page.drawText('Invoice #12345', {
    x: 50, y: height - 50, size: 18,
    font: helveticaBold, color: rgb(0.2, 0.2, 0.8)
  });

  page.drawRectangle({
    x: 40, y: height - 100, width: width - 80, height: 30,
    color: rgb(0.9, 0.9, 0.9)
  });

  const items = [
    ['Item', 'Qty', 'Price', 'Total'],
    ['Widget', '2', '$50', '$100'],
    ['Gadget', '1', '$75', '$75']
  ];

  let yPos = height - 150;
  items.forEach(row => {
    let xPos = 50;
    row.forEach(cell => {
      page.drawText(cell, { x: xPos, y: yPos, size: 12, font: helveticaFont });
      xPos += 120;
    });
    yPos -= 25;
  });

  const pdfBytes = await pdfDoc.save();
  fs.writeFileSync('created.pdf', pdfBytes);
}
```

高级合并与拆分：

```javascript
import { PDFDocument } from 'pdf-lib';
import fs from 'fs';

async function mergePDFs() {
  const mergedPdf = await PDFDocument.create();

  const pdf1 = await PDFDocument.load(fs.readFileSync('doc1.pdf'));
  const pdf2 = await PDFDocument.load(fs.readFileSync('doc2.pdf'));

  // Copy all pages from pdf1
  const pdf1Pages = await mergedPdf.copyPages(pdf1, pdf1.getPageIndices());
  pdf1Pages.forEach(page => mergedPdf.addPage(page));

  // Copy specific pages from pdf2 (pages 0, 2, 4)
  const pdf2Pages = await mergedPdf.copyPages(pdf2, [0, 2, 4]);
  pdf2Pages.forEach(page => mergedPdf.addPage(page));

  fs.writeFileSync('merged.pdf', await mergedPdf.save());
}
```

##### 3.3.2.2 pdfjs-dist（Apache 许可）

```text
PDF.js is Mozilla's JavaScript library for rendering PDFs in the browser.
```

译文：`PDF.js` 是 Mozilla 用于在浏览器中渲染 PDF 的 JavaScript 库。

基础加载与渲染：

```javascript
import * as pdfjsLib from 'pdfjs-dist';

pdfjsLib.GlobalWorkerOptions.workerSrc = './pdf.worker.js';

async function renderPDF() {
  const pdf = await pdfjsLib.getDocument('document.pdf').promise;
  console.log(`Loaded PDF with ${pdf.numPages} pages`);

  const page = await pdf.getPage(1);
  const viewport = page.getViewport({ scale: 1.5 });

  const canvas = document.createElement('canvas');
  const context = canvas.getContext('2d');
  canvas.height = viewport.height;
  canvas.width = viewport.width;

  await page.render({ canvasContext: context, viewport }).promise;
  document.body.appendChild(canvas);
}
```

带坐标的文本提取：

```javascript
import * as pdfjsLib from 'pdfjs-dist';

async function extractText() {
  const pdf = await pdfjsLib.getDocument('document.pdf').promise;
  let fullText = '';

  for (let i = 1; i <= pdf.numPages; i++) {
    const page = await pdf.getPage(i);
    const textContent = await page.getTextContent();
    // 此处可继续遍历 textContent.items，获取文本与坐标
  }
}
```

提取注释与表单（Extract Annotations and Forms）

```javascript
import * as pdfjsLib from 'pdfjs-dist';

async function extractAnnotations() {
  const pdf = await pdfjsLib.getDocument('annotated.pdf').promise;

  for (let i = 1; i <= pdf.numPages; i++) {
    const page = await pdf.getPage(i);
    const annotations = await page.getAnnotations();

    annotations.forEach(annotation => {
      console.log(`Type: ${annotation.subtype}`);
      console.log(`Content: ${annotation.contents}`);
      console.log(`Coordinates: ${JSON.stringify(annotation.rect)}`);
    });
  }
}
```

##### 3.3.3 命令行高级操作

###### 3.3.3.1 poppler-utils 高级功能

带边界框坐标的文本提取：

```bash
# Extract text with bounding box coordinates (essential for structured data)
pdftotext -bbox-layout document.pdf output.xml

# The XML output contains precise coordinates for each text element
```

高分辨率图片转换：

```bash
# Convert to PNG with specific resolution
pdftoppm -png -r 300 document.pdf output_prefix

# Convert specific page range with high resolution
pdftoppm -png -r 600 -f 1 -l 3 document.pdf high_res_pages

# Convert to JPEG with quality setting
pdftoppm -jpeg -jpegopt quality=85 -r 200 document.pdf jpeg_output
```

提取嵌入图片：

```bash
# Extract all embedded images with metadata
pdfimages -j -p document.pdf page_images

# List image info without extracting
pdfimages -list document.pdf

# Extract images in their original format
pdfimages -all document.pdf images/img
```

###### 3.3.3.2 qpdf 高级功能

复杂页面操作：

```bash
# Split PDF into groups of pages
qpdf --split-pages=3 input.pdf output_group_%02d.pdf

# Extract specific pages with complex ranges
qpdf input.pdf --pages input.pdf 1,3-5,8,10-z -- extracted.pdf

# Merge specific pages from multiple PDFs
qpdf --empty --pages doc1.pdf 1-3 doc2.pdf 5-7 doc3.pdf 2,4 -- combined.pdf
```

PDF 优化与修复：

```bash
# Optimize PDF for web (linearize for streaming)
qpdf --linearize input.pdf optimized.pdf

# Remove unused objects and compress
qpdf --optimize-level=all input.pdf compressed.pdf

# Attempt to repair corrupted PDF structure
qpdf --check input.pdf
qpdf --fix-qdf damaged.pdf repaired.pdf

# Show detailed PDF structure for debugging
qpdf --show-all-pages input.pdf > structure.txt
```

高级加密：

```bash
# Add password protection with specific permissions
qpdf --encrypt user_pass owner_pass 256 --print=none --modify=none -- input.pdf encrypted.pdf

# Check encryption status
qpdf --show-encryption encrypted.pdf

# Remove password protection (requires password)
qpdf --password=secret123 --decrypt encrypted.pdf decrypted.pdf
```

##### 3.3.4 Python 高级技巧

###### 3.3.4.1 pdfplumber 精确坐标提取

```python
import pdfplumber

with pdfplumber.open("document.pdf") as pdf:
    page = pdf.pages[0]

    # Extract all text with coordinates
    chars = page.chars
    for char in chars[:10]:
        print(f"Char: '{char['text']}' at x:{char['x0']:.1f} y:{char['y0']:.1f}")

    # Extract text by bounding box (left, top, right, bottom)
    bbox_text = page.within_bbox((100, 100, 400, 200)).extract_text()
```

自定义表格设置（Advanced Table Extraction with Custom Settings）：

```python
import pdfplumber
import pandas as pd

with pdfplumber.open("complex_table.pdf") as pdf:
    page = pdf.pages[0]

    table_settings = {
        "vertical_strategy": "lines",
        "horizontal_strategy": "lines",
        "snap_tolerance": 3,
        "intersection_tolerance": 15
    }

    tables = page.extract_tables(table_settings)

    # Visual debugging for table extraction
    img = page.to_image(resolution=150)
    img.save("debug_layout.png")
```

###### 3.3.4.2 reportlab 专业报告表格

```python
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib import colors

data = [
    ['Product', 'Q1', 'Q2', 'Q3', 'Q4'],
    ['Widgets', '120', '135', '142', '158'],
    ['Gadgets', '85', '92', '98', '105']
]

doc = SimpleDocTemplate("report.pdf")
elements = []

styles = getSampleStyleSheet()
elements.append(Paragraph("Quarterly Sales Report", styles['Title']))

table = Table(data)
table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, 0), 14),
    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
    ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
    ('GRID', (0, 0), (-1, -1), 1, colors.black)
]))
elements.append(table)
doc.build(elements)
```

##### 3.3.5 复杂工作流

方法一：`pdfimages` 提取图片（最快）

```bash
pdfimages -all document.pdf images/img
```

方法二：`pypdfium2` + 图像处理

```python
import pypdfium2 as pdfium
from PIL import Image
import numpy as np

def extract_figures(pdf_path, output_dir):
    pdf = pdfium.PdfDocument(pdf_path)

    for page_num, page in enumerate(pdf):
        bitmap = page.render(scale=3.0)
        img = bitmap.to_pil()
        img_array = np.array(img)

        # Simple figure detection (non-white regions)
        mask = np.any(img_array != [255, 255, 255], axis=2)
        # Further contour detection and bounding box extraction
        # would be implemented here based on specific needs
```

批量处理（Batch PDF Processing with Error Handling）：

```python
import os
import glob
from pypdf import PdfReader, PdfWriter
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def batch_process_pdfs(input_dir, operation='merge'):
    pdf_files = glob.glob(os.path.join(input_dir, '*.pdf'))

    if operation == 'merge':
        writer = PdfWriter()
        for pdf_file in pdf_files:
            try:
                reader = PdfReader(pdf_file)
                for page in reader.pages:
                    writer.add_page(page)
                logger.info(f"Processed: {pdf_file}")
            except Exception as e:
                logger.error(f"Failed to process {pdf_file}: {e}")
                continue
        with open("batch_merged.pdf", "wb") as output:
            writer.write(output)

    elif operation == 'extract_text':
        for pdf_file in pdf_files:
            try:
                reader = PdfReader(pdf_file)
                text = "".join(page.extract_text() for page in reader.pages)
                output_file = pdf_file.replace('.pdf', '.txt')
                with open(output_file, 'w', encoding='utf-8') as f:
                    f.write(text)
                logger.info(f"Extracted text from: {pdf_file}")
            except Exception as e:
                logger.error(f"Failed to extract text from {pdf_file}: {e}")
                continue
```

##### 3.3.6 性能优化建议

高级 PDF 裁切（Advanced PDF Cropping）：

```python
from pypdf import PdfWriter, PdfReader

reader = PdfReader("input.pdf")
writer = PdfWriter()

page = reader.pages[0]
page.mediabox.left = 50
page.mediabox.bottom = 50
page.mediabox.right = 550
page.mediabox.top = 750

writer.add_page(page)
with open("cropped.pdf", "wb") as output:
    writer.write(output)
```

性能优化建议：

```text
1. For Large PDFs
   - Use streaming approaches instead of loading entire PDF in memory
   - Use qpdf --split-pages for splitting large files
   - Process pages individually with pypdfium2

2. For Text Extraction
   - pdftotext -bbox-layout is fastest for plain text extraction
   - Use pdfplumber for structured data and tables
   - Avoid pypdf.extract_text() for very large documents

3. For Image Extraction
   - pdfimages is much faster than rendering pages
   - Use low resolution for previews, high resolution for final output

4. For Form Filling
   - pdf-lib maintains form structure better than most alternatives
   - Pre-validate form fields before processing
```

分块处理内存管理（Memory Management）：

```python
def process_large_pdf(pdf_path, chunk_size=10):
    reader = PdfReader(pdf_path)
    total_pages = len(reader.pages)

    for start_idx in range(0, total_pages, chunk_size):
        end_idx = min(start_idx + chunk_size, total_pages)
        writer = PdfWriter()

        for i in range(start_idx, end_idx):
            writer.add_page(reader.pages[i])

        with open(f"chunk_{start_idx//chunk_size}.pdf", "wb") as output:
            writer.write(output)
```

##### 3.3.7 故障排除

加密 PDF（Encrypted PDFs）：

```python
from pypdf import PdfReader

try:
    reader = PdfReader("encrypted.pdf")
    if reader.is_encrypted:
        reader.decrypt("password")
except Exception as e:
    print(f"Failed to decrypt: {e}")
```

损坏 PDF（Corrupted PDFs）：

```bash
qpdf --check corrupted.pdf
qpdf --replace-input corrupted.pdf
```

文本提取失败 - OCR 降级（Text Extraction Issues）：

```python
import pytesseract
from pdf2image import convert_from_path

def extract_text_with_ocr(pdf_path):
    images = convert_from_path(pdf_path)
    text = ""
    for image in images:
        text += pytesseract.image_to_string(image)
    return text
```

##### 3.3.8 许可证信息

| 库 / 工具 | 许可证 |
| --- | --- |
| pypdf | BSD License |
| pdfplumber | MIT License |
| pypdfium2 | Apache/BSD License |
| reportlab | BSD License |
| poppler-utils | GPL-2 License |
| qpdf | Apache License |
| pdf-lib | MIT License |
| pdfjs-dist | Apache License |

#### 3.4 `LICENSE.txt` - 许可证

Anthropic 专有许可，禁止提取、复制、分发或逆向工程。

## 4. 脚本文件详解

### 4.1 `check_fillable_fields.py` - 表单域检测

整个表单填写流程的第一步，判断 PDF 是否有原生的可填写表单域。

```python
import sys
from pypdf import PdfReader

# 读取命令行传入的 PDF 文件
reader = PdfReader(sys.argv[1])

# get_fields() 返回 PDF 中所有可填写的表单域
# 如果返回非空说明是可填写表单，走 fillable 路径
# 否则走 non-fillable 路径（通过注释方式叠加文字）
if (reader.get_fields()):
    print("This PDF has fillable form fields")
else:
    print("This PDF does not have fillable form fields; you will need to visually determine where to enter data")
```

作用：路由决策。决定后续走“可填写表单”还是“不可填写表单”的处理路径。

### 4.2 `convert_pdf_to_images.py` - PDF 转图片

将 PDF 的每一页转换为 PNG 图片，用于视觉分析和结果验证。

```python
import os
import sys
from pdf2image import convert_from_path

def convert(pdf_path, output_dir, max_dim=1000):
    # 以 200 DPI 渲染 PDF 的每一页为图片
    images = convert_from_path(pdf_path, dpi=200)

    for i, image in enumerate(images):
        width, height = image.size
        # 如果图片尺寸超过 max_dim（默认 1000px），等比缩放
        # 这是为了让 Claude 能在上下文中高效处理图片（太大会浪费 token）
        if width > max_dim or height > max_dim:
            scale_factor = min(max_dim / width, max_dim / height)
            new_width = int(width * scale_factor)
            new_height = int(height * scale_factor)
            image = image.resize((new_width, new_height))

        # 按 page_1.png, page_2.png ... 命名保存
        image_path = os.path.join(output_dir, f"page_{i+1}.png")
        image.save(image_path)
        print(f"Saved page {i+1} as {image_path} (size: {image.size})")

    print(f"Converted {len(images)} pages to PNG images")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: convert_pdf_to_images.py [input pdf] [output directory]")
        sys.exit(1)

    pdf_path = sys.argv[1]
    output_directory = sys.argv[2]
    convert(pdf_path, output_directory)
```

作用：在流程中承担两个角色。① 分析阶段让 Claude 可视化理解表单布局；② 验证阶段确认填写结果是否正确。

### 4.3 `extract_form_field_info.py` - 可填写表单域信息提取

从可填写 PDF 中提取所有表单域的详细信息（ID、类型、位置、选项等）。

```python
import json
import sys
from pypdf import PdfReader

def get_full_annotation_field_id(annotation):
    """递归向上遍历注释的父级链，组装完整的字段 ID
    例如：如果字段有 Parent -> Child 结构，则 ID 为 "Parent.Child"
    """
    components = []
    while annotation:
        field_name = annotation.get('/T')  # /T 是 PDF 规范中的字段名属性
        if field_name:
            components.append(field_name)
        annotation = annotation.get('/Parent')
    return ".".join(reversed(components)) if components else None

def make_field_dict(field, field_id):
    """根据字段类型（/FT 属性）构建字段信息字典"""
    field_dict = {"field_id": field_id}
    ft = field.get('/FT')  # /FT = Field Type

    if ft == "/Tx":
        # /Tx = 文本输入框
        field_dict["type"] = "text"
    elif ft == "/Btn":
        # /Btn = 按钮类型（包含复选框和单选按钮）
        field_dict["type"] = "checkbox"
        states = field.get("/_States_", [])
        if len(states) == 2:
            # 通常两个状态：一个是选中值，一个是 "/Off"
            if "/Off" in states:
                field_dict["checked_value"] = states[0] if states[0] != "/Off" else states[1]
                field_dict["unchecked_value"] = "/Off"
            else:
                print(f"Unexpected state values for checkbox {field_id}: ")
                field_dict["checked_value"] = states[0]
                field_dict["unchecked_value"] = states[1]
    elif ft == "/Ch":
        # /Ch = 下拉选择框
        field_dict["type"] = "choice"
        states = field.get("/_States_", [])
        field_dict["choice_options"] = [{
            "value": state[0],
            "text": state[1],
        } for state in states]
    else:
        field_dict["type"] = f"unknown ({ft})"
    return field_dict

def get_field_info(reader: PdfReader):
    """主函数：遍历所有字段，关联页面位置，处理单选按钮组"""
    fields = reader.get_fields()
    field_info_by_id = {}
    possible_radio_names = set()

    # 第一遍：收集普通字段，标记可能的单选按钮组（有 /Kids 的 /Btn 类型）
    for field_id, field in fields.items():
        if field.get("/Kids"):
            if field.get("/FT") == "/Btn":
                possible_radio_names.add(field_id)
                continue
        field_info_by_id[field_id] = make_field_dict(field, field_id)

    radio_fields_by_id = {}

    # 第二遍：遍历每页的注释，关联字段与页面位置
    for page_index, page in enumerate(reader.pages):
        annotations = page.get('/Annots', [])
        for ann in annotations:
            field_id = get_full_annotation_field_id(ann)
            if field_id in field_info_by_id:
                # 为普通字段添加页码和矩形位置
                field_info_by_id[field_id]["page"] = page_index + 1
                field_info_by_id[field_id]["rect"] = ann.get('/Rect')
            elif field_id in possible_radio_names:
                # 处理单选按钮组：每个选项是一个独立的注释
                try:
                    on_values = [v for v in ann["/AP"]["/N"] if v != "/Off"]
                except KeyError:
                    continue
                if len(on_values) == 1:
                    rect = ann.get('/Rect')
                    if field_id not in radio_fields_by_id:
                        radio_fields_by_id[field_id] = {
                            "field_id": field_id,
                            "type": "radio_group",
                            "page": page_index + 1,
                            "radio_options": [],
                        }
                    radio_fields_by_id[field_id]["radio_options"].append({
                        "value": on_values[0],
                        "rect": rect,
                    })

    # 过滤掉无法定位的字段，按页码和位置排序
    fields_with_location = []
    for field_info in field_info_by_id.values():
        if "page" in field_info:
            fields_with_location.append(field_info)
        else:
            print(f"Unable to determine location for field id: {field_info.get('field_id')}, ignoring")

    def sort_key(f):
        if "radio_options" in f:
            rect = f["radio_options"][0]["rect"] or [0, 0, 0, 0]
        else:
            rect = f.get("rect") or [0, 0, 0, 0]
        # 按页码排序，同一页内从上到下、从左到右排列
        adjusted_position = [-rect[1], rect[0]]
        return [f.get("page"), adjusted_position]

    sorted_fields = fields_with_location + list(radio_fields_by_id.values())
    sorted_fields.sort(key=sort_key)
    return sorted_fields

def write_field_info(pdf_path: str, json_output_path: str):
    reader = PdfReader(pdf_path)
    field_info = get_field_info(reader)
    with open(json_output_path, "w") as f:
        json.dump(field_info, f, indent=2)
    print(f"Wrote {len(field_info)} fields to {json_output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: extract_form_field_info.py [input pdf] [output json]")
        sys.exit(1)
    write_field_info(sys.argv[1], sys.argv[2])
```

作用：可填写表单路径的核心步骤。产出结构化的字段信息 JSON，包含字段类型、位置、可选值等完整数据，供后续填写使用。

### 4.4 `extract_form_structure.py` - 不可填写表单结构提取

使用 `pdfplumber` 分析不可填写 PDF 的视觉结构，提取文本标签、线条和复选框的精确坐标。

```python
"""
用途：分析不可填写 PDF 的表单结构。
使用 pdfplumber 提取：文本标签+坐标、水平线（行边界）、复选框（小方形矩形）。
输出 JSON 包含：pages, labels, lines, checkboxes, row_boundaries。
"""

import json
import sys
import pdfplumber

def extract_form_structure(pdf_path):
    structure = {
        "pages": [],          # 每页的宽高信息
        "labels": [],         # 所有文本标签及其精确坐标
        "lines": [],          # 水平线（用于横断行边界）
        "checkboxes": [],     # 小方形矩形（被识别为复选框）
        "row_boundaries": []  # 根据水平线推算的行边界
    }

    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages, 1):
            structure["pages"].append({
                "page_number": page_num,
                "width": float(page.width),
                "height": float(page.height)
            })

            # 提取每个词（word）的位置消息
            # x0, top, x1, bottom 定义了文本的边界矩形
            words = page.extract_words()
            for word in words:
                structure["labels"].append({
                    "page": page_num,
                    "text": word["text"],
                    "x0": round(float(word["x0"]), 1),
                    "top": round(float(word["top"]), 1),
                    "x1": round(float(word["x1"]), 1),
                    "bottom": round(float(word["bottom"]), 1)
                })

            # 提取水平线：仅保留跨越页面宽度 50% 以上的线条
            # 这些长线通常是表单的行分隔符
            for line in page.lines:
                if abs(float(line["x1"]) - float(line["x0"])) > page.width * 0.5:
                    structure["lines"].append({
                        "page": page_num,
                        "y": round(float(line["top"]), 1),
                        "x0": round(float(line["x0"]), 1),
                        "x1": round(float(line["x1"]), 1)
                    })

            # 检测复选框：宽高在 5-15px 之间且近似正方形的矩形
            for rect in page.rects:
                width = float(rect["x1"]) - float(rect["x0"])
                height = float(rect["bottom"]) - float(rect["top"])
                if 5 <= width <= 15 and 5 <= height <= 15 and abs(width - height) < 2:
                    structure["checkboxes"].append({
                        "page": page_num,
                        "x0": round(float(rect["x0"]), 1),
                        "top": round(float(rect["top"]), 1),
                        "x1": round(float(rect["x1"]), 1),
                        "bottom": round(float(rect["bottom"]), 1),
                        "center_x": round((float(rect["x0"]) + float(rect["x1"])) / 2, 1),
                        "center_y": round((float(rect["top"]) + float(rect["bottom"])) / 2, 1)
                    })

            # 根据水平线计算行边界（相邻两条线之间的区域就是一行）
            lines_by_page = {}
            for line in structure["lines"]:
                page_id = line["page"]
                if page_id not in lines_by_page:
                    lines_by_page[page_id] = []
                lines_by_page[page_id].append(line["y"])

            for page_id, y_coords in lines_by_page.items():
                y_coords = sorted(set(y_coords))
                for i in range(len(y_coords) - 1):
                    structure["row_boundaries"].append({
                        "page": page_id,
                        "row_top": y_coords[i],
                        "row_bottom": y_coords[i + 1],
                        "row_height": round(y_coords[i + 1] - y_coords[i], 1)
                    })

    return structure

def main():
    if len(sys.argv) != 3:
        print("Usage: extract_form_structure.py <input.pdf> <output.json>")
        sys.exit(1)

    pdf_path = sys.argv[1]
    output_path = sys.argv[2]
    print(f"Extracting structure from {pdf_path}...")
    structure = extract_form_structure(pdf_path)
    with open(output_path, "w") as f:
        json.dump(structure, f, indent=2)

    print(f"Found:")
    print(f"  - {len(structure['pages'])} pages")
    print(f"  - {len(structure['labels'])} text labels")
    print(f"  - {len(structure['lines'])} horizontal lines")
    print(f"  - {len(structure['checkboxes'])} checkboxes")
    print(f"  - {len(structure['row_boundaries'])} row boundaries")
    print(f"Saved to {output_path}")

if __name__ == "__main__":
    main()
```

作用：不可填写表单路径“方案 A”的关键。通过分析 PDF 的矢量元素（文字、线条、矩形）推断表单结构，为计算真实填写坐标提供数据基础。

### 4.5 `check_bounding_boxes.py` - 边界框验证

在填写表单之前验证 `fields.json` 中定义的边界框是否合理。

```python
from dataclasses import dataclass
import json
import sys

@dataclass
class RectAndField:
    rect: list[float]      # 边界框坐标 [x0, y0, x1, y1]
    rect_type: str         # "label" 或 "entry"
    field: dict            # 关联的字段信息

def get_bounding_box_messages(fields_json_stream) -> list[str]:
    messages = []
    fields = json.load(fields_json_stream)
    messages.append(f"Read {len(fields['form_fields'])} fields")

    def rects_intersect(r1, r2):
        """检查两个矩形是否相交（AABB 碰撞检测）"""
        disjoint_horizontal = r1[0] >= r2[2] or r1[2] <= r2[0]
        disjoint_vertical = r1[1] >= r2[3] or r1[3] <= r2[1]
        return not (disjoint_horizontal or disjoint_vertical)

    # 收集所有的 label 和 entry 边界框
    rects_and_fields = []
    for f in fields["form_fields"]:
        rects_and_fields.append(RectAndField(f["label_bounding_box"], "label", f))
        rects_and_fields.append(RectAndField(f["entry_bounding_box"], "entry", f))

    has_error = False
    # O(n^2) 检查：所有框之间是否有交叉
    for i, ri in enumerate(rects_and_fields):
        for j in range(i + 1, len(rects_and_fields)):
            rj = rects_and_fields[j]
            if ri.field["page_number"] == rj.field["page_number"] and rects_intersect(ri.rect, rj.rect):
                has_error = True
                if ri.field is rj.field:
                    # 同一字段的 label 和 entry 框重叠
                    messages.append(f"FAILURE: intersection between label and entry bounding boxes for `{ri.field['description']}`")
                else:
                    # 不同字段的框重叠
                    messages.append(f"FAILURE: intersection between {ri.rect_type} bounding box for `{ri.field['description']}` and {rj.rect_type} bounding box for `{rj.field['description']}`")
                    if len(messages) >= 20:
                        messages.append("Aborting further checks; fix bounding boxes and try again")
                        return messages

        # 额外检查：entry 框的高度是否足够容纳文字
        if ri.rect_type == "entry":
            if "entry_text" in ri.field:
                font_size = ri.field["entry_text"].get("font_size", 14)
                entry_height = ri.rect[3] - ri.rect[1]
                if entry_height < font_size:
                    has_error = True
                    messages.append(f"FAILURE: entry bounding box height ({entry_height}) for `{ri.field['description']}` is too short for font size: {font_size}")

    if not has_error:
        messages.append("SUCCESS: All bounding boxes are valid")
    return messages

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: check_bounding_boxes.py [fields.json]")
        sys.exit(1)
    with open(sys.argv[1]) as f:
        messages = get_bounding_box_messages(f)
    for msg in messages:
        print(msg)
```

### 4.6 `create_validation_image.py` - 验证图片生成

在页面图片上绘制边界框，用于视觉验证坐标是否准确。

```python
import json
import sys
from PIL import Image, ImageDraw

def create_validation_image(page_number, fields_json_path, input_path, output_path):
    with open(fields_json_path, 'r') as f:
        data = json.load(f)

    img = Image.open(input_path)
    draw = ImageDraw.Draw(img)
    num_boxes = 0

    for field in data["form_fields"]:
        if field["page_number"] == page_number:
            entry_box = field["entry_bounding_box"]
            label_box = field["label_bounding_box"]
            # 红色框 = 填写区域（entry），蓝色框 = 标签区域（label）
            draw.rectangle(entry_box, outline='red', width=2)
            draw.rectangle(label_box, outline='blue', width=2)
            num_boxes += 2

    img.save(output_path)
    print(f"Created validation image at {output_path} with {num_boxes} bounding boxes")

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: create_validation_image.py [page number] [fields.json] [input image] [output image]")
        sys.exit(1)
    page_number = int(sys.argv[1])
    fields_json_path = sys.argv[2]
    input_image_path = sys.argv[3]
    output_image_path = sys.argv[4]
    create_validation_image(page_number, fields_json_path, input_image_path, output_image_path)
```

作用：调试辅助工具。通过可视化标注让用户 / Claude 直观确认坐标是否对齐正确。

### 4.7 `fill_pdf_form_with_annotations.py` - 注释方式填写表单

通过在 PDF 上添加 `FreeText` 注释来填写不可填写的表单，支持 PDF 坐标和图片坐标两种输入。

```python
import json
import sys
from pypdf import PdfReader, PdfWriter
from pypdf.annotations import FreeText

def transform_from_image_coords(bbox, image_width, image_height, pdf_width, pdf_height):
    """将图片坐标系转换为 PDF 坐标系
    图片坐标系：原点在左上角，y 轴向下
    PDF 坐标系：原点在左下角，y 轴向上
    """
    x_scale = pdf_width / image_width
    y_scale = pdf_height / image_height

    left = bbox[0] * x_scale
    right = bbox[2] * x_scale
    # y 轴方向需要翻转
    top = pdf_height - (bbox[1] * y_scale)
    bottom = pdf_height - (bbox[3] * y_scale)

    return left, bottom, right, top

def transform_from_pdf_coords(bbox, pdf_height):
    """将 forms.md 中使用的 PDF 坐标（y=0 顶部）转换为 pypdf 需要的坐标（y=0 在底部）
    这是因为 pdfplumber 输出的 y=0 在顶部，而 pypdf 的注释要求 y=0 在底部
    """
    left = bbox[0]
    right = bbox[2]
    pypdf_top = pdf_height - bbox[1]
    pypdf_bottom = pdf_height - bbox[3]
    return left, pypdf_bottom, right, pypdf_top

def fill_pdf_form(input_pdf_path, fields_json_path, output_pdf_path):
    with open(fields_json_path, "r") as f:
        fields_data = json.load(f)

    reader = PdfReader(input_pdf_path)
    writer = PdfWriter()
    writer.append(reader)

    # 获取每页的实际 PDF 尺寸
    pdf_dimensions = {}
    for i, page in enumerate(reader.pages):
        mediabox = page.mediabox
        pdf_dimensions[i + 1] = [mediabox.width, mediabox.height]

    annotations = []
    for field in fields_data["form_fields"]:
        page_num = field["page_number"]
        page_info = next(p for p in fields_data["pages"] if p["page_number"] == page_num)
        pdf_width, pdf_height = pdf_dimensions[page_num]

        # 自动检测坐标系：pdf_width 表示使用 PDF 坐标，image_width 表示使用图片坐标
        if "pdf_width" in page_info:
            transformed_entry_box = transform_from_pdf_coords(
                field["entry_bounding_box"], float(pdf_height)
            )
        else:
            image_width = page_info["image_width"]
            image_height = page_info["image_height"]
            transformed_entry_box = transform_from_image_coords(
                field["entry_bounding_box"],
                image_width, image_height,
                float(pdf_width), float(pdf_height)
            )

        if "entry_text" not in field or "text" not in field["entry_text"]:
            continue
        entry_text = field["entry_text"]
        text = entry_text["text"]
        if not text:
            continue

        font_name = entry_text.get("font", "Arial")
        font_size = str(entry_text.get("font_size", 14)) + "pt"
        font_color = entry_text.get("font_color", "000000")

        # 创建 FreeText 注释 - 这是在 PDF 上添加文字的标准方式
        annotation = FreeText(
            text=text,
            rect=transformed_entry_box,
            font=font_name,
            font_size=font_size,
            font_color=font_color,
            border_color=None,      # 无边框
            background_color=None,  # 无背景
        )
        annotations.append(annotation)
        writer.add_annotation(page_number=page_num - 1, annotation=annotation)

    with open(output_pdf_path, "wb") as output:
        writer.write(output)

    print(f"Successfully filled PDF form and saved to {output_pdf_path}")
    print(f"Added {len(annotations)} text annotations")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: fill_pdf_form_with_annotations.py [input pdf] [fields.json] [output pdf]")
        sys.exit(1)
    fill_pdf_form(sys.argv[1], sys.argv[2], sys.argv[3])
```

作用：不可填写表单路径的最终执行步骤。将文字作为注释层叠加到 PDF 上，巧妙地实现了在任意 PDF 上“填写”文字的能力。坐标系自动检测是其核心设计亮点。

### 4.8 `fill_fillable_fields.py` - 原生表单域填写

直接操作 PDF 的原生表单域来填写数据，支持文本框、复选框、单选按钮组和下拉选择。

```python
import json
import sys
from pypdf import PdfReader, PdfWriter
from extract_form_field_info import get_field_info

def fill_pdf_fields(input_pdf_path: str, fields_json_path: str, output_pdf_path: str):
    # 读取要填写的字段值
    with open(fields_json_path) as f:
        fields = json.load(f)

    # 按页码组织字段
    fields_by_page = {}
    for field in fields:
        if "value" in field:
            field_id = field["field_id"]
            page = field["page"]
            if page not in fields_by_page:
                fields_by_page[page] = {}
            fields_by_page[page][field_id] = field["value"]

    reader = PdfReader(input_pdf_path)

    # 验证阶段：检查每个字段 ID 是否存在、页码是否正确、值是否合法
    has_error = False
    field_info = get_field_info(reader)
    fields_by_ids = {f["field_id"]: f for f in field_info}
    for field in fields:
        existing_field = fields_by_ids.get(field["field_id"])
        if not existing_field:
            has_error = True
            print(f"ERROR: `{field['field_id']}` is not a valid field ID")
        elif field["page"] != existing_field["page"]:
            has_error = True
            print(f"ERROR: Incorrect page number for `{field['field_id']}`")
        else:
            if "value" in field:
                err = validation_error_for_field_value(existing_field, field["value"])
                if err:
                    print(err)
                    has_error = True
    if has_error:
        sys.exit(1)

    # 使用 clone_from 保留原始 PDF 的所有内容
    writer = PdfWriter(clone_from=reader)
    for page, field_values in fields_by_page.items():
        # auto_regenerate=False 避免自动重新生成外观流（可能破坏格式）
        writer.update_page_form_field_values(
            writer.pages[page - 1], field_values, auto_regenerate=False
        )

    # 设置 NeedAppearances 标志，让 PDF 查看器在打开时自动渲染字段外观
    writer.set_need_appearances_writer(True)

    with open(output_pdf_path, "wb") as f:
        writer.write(f)

def validation_error_for_field_value(field_info, field_value):
    """针对不同字段类型验证值的合法性"""
    field_type = field_info["type"]
    field_id = field_info["field_id"]

    if field_type == "checkbox":
        checked_val = field_info["checked_value"]
        unchecked_val = field_info["unchecked_value"]
        if field_value != checked_val and field_value != unchecked_val:
            return f"ERROR: Invalid value '{field_value}' for checkbox '{field_id}'. Valid: '{checked_val}' or '{unchecked_val}'"
    elif field_type == "radio_group":
        option_values = [opt["value"] for opt in field_info["radio_options"]]
        if field_value not in option_values:
            return f"ERROR: Invalid value '{field_value}' for radio group '{field_id}'. Valid: {option_values}"
    elif field_type == "choice":
        choice_values = [opt["value"] for opt in field_info["choice_options"]]
        if field_value not in choice_values:
            return f"ERROR: Invalid value '{field_value}' for choice '{field_id}'. Valid: {choice_values}"
    return None

def monkeypatch_pypdf_method():
    """修补 pypdf 的一个兼容性问题
    某些 PDF 的 /Opt 字段包含 [value, display_text] 对，
    但 pypdf 期望只有单个值，这个补丁将其转换为正确格式
    """
    from pypdf.generic import DictionaryObject
    from pypdf.constants import FieldDictionaryAttributes

    original_get_inherited = DictionaryObject.get_inherited

    def patched_get_inherited(self, key: str, default=None):
        result = original_get_inherited(self, key, default)
        if key == FieldDictionaryAttributes.Opt:
            if isinstance(result, list) and all(isinstance(v, list) and len(v) == 2 for v in result):
                result = [r[0] for r in result]
        return result

    DictionaryObject.get_inherited = patched_get_inherited

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: fill_fillable_fields.py [input pdf] [field_values.json] [output pdf]")
        sys.exit(1)
    monkeypatch_pypdf_method()  # 先打补丁再执行
    fill_pdf_fields(sys.argv[1], sys.argv[2], sys.argv[3])
```

作用：可填写表单路径的最终执行步骤。直接操作 PDF 原生表单域。包含完整的验证逻辑（字段存在性、页码、值合法性），以及一个针对 `pypdf` 兼容性问题的运行时补丁。

## 5. 整体架构与设计哲学

### 5.1 流程图

```text
用户请求填写 PDF 表单
        |
        v
check_fillable_fields.py ---> 有可填写域?
        |                    |
       是                    否
        |                    |
        v                    v
extract_form_field_info.py   extract_form_structure.py
        |                    |
        v                    有结构数据?
convert_pdf_to_images.py          |-- 是 -> 方案 A（结构坐标）
(视觉分析字段用途)                 |-- 否 -> 方案 B（视觉估算）
        |                         |-- 部分 -> 混合方案
        v                    |
创建 field_values.json       创建 fields.json
        |                    |
        v                    v
fill_fillable_fields.py   check_bounding_boxes.py（验证）
        |                    |
        v                    v
      输出 PDF      fill_pdf_form_with_annotations.py
                                 |
                                 v
                              输出 PDF
                                 |
                                 v
                  convert_pdf_to_images.py（验证输出）
```

### 5.2 设计亮点

| 维度 | 设计亮点 | 说明 |
| --- | --- | --- |
| 1 | 路由决策模式 | 先检测再分流，避免用错误方法处理 PDF |
| 2 | 双坐标系支持 | PDF 坐标和图片坐标自动检测与转换 |
| 3 | 验证闭环 | 填写前验证边界框 + 填写后视觉验证 |
| 4 | 渐进式降级 | 结构提取 -> 视觉估算 -> 混合方案，逐级兜底 |
| 5 | 脚本化稳定性操作 | 将坐标计算、验证、填写等确定性操作封装为脚本，让 AI 专注于理解和决策 |

## 6. 深层分析

这个 PDF Skill 和前面的前端设计 Skill 完全不同。它不是“创意引导型”，而是“工具编排型”：

1. 主文件 `SKILL.md` 负责常见操作和导航
2. `forms.md` 负责复杂表单工作流，且强制分步执行
3. `reference.md` 负责进阶库和高级特性
4. `scripts/` 目录负责把抽象流程变成可执行工具链

从设计上看，这个 Skill 解决的是一个典型问题：PDF 任务表面上看像一个需求，实际上经常分裂成多条完全不同的执行路径：

- 普通 PDF 文本提取
- 表格提取
- 新建 PDF
- 命令行批处理
- 可填写表单
- 不可填写表单
- 扫描件 OCR
- 浏览器端渲染

因此，它不能像 `frontend-design` 那样只靠一个单文件 prompt 指导，而必须把：

- 路由逻辑
- 工具选择
- 坐标系统
- 验证机制
- 故障回退方案

全部显式写出来。

尤其是 `forms.md` 的设计非常值得注意：它不是直接教“怎么填表”，而是先让模型判断“是哪一类表单”，然后再强制进入对应分支。这种“先分类，再执行”的 Skill 结构，非常适合复杂工程问题。
