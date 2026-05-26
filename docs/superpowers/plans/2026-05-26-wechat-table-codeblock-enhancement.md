# WeChat Table and Codeblock Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve the WeChat clipping pipeline so HTML tables, pseudo-tables, and unlabeled code fences are converted into usable Markdown instead of flattening into plain text.

**Architecture:** Extend the existing HTML-to-Markdown path in `C:\Users\ZXY\.codex\skills\wechat-clippings\scripts\clip_wechat_tikhub.py` with a small table state machine for real `<table>` markup, then add a postprocessor that recognizes common WeChat visual-table patterns in plain text. Add fenced-code language inference in the same normalization layer so code blocks default to `python`, `json`, or `bash` before falling back to `text`.

**Tech Stack:** Python 3, existing `html.parser`-based converter, standard library regex and JSON parsing.

---

### Task 1: Add a real HTML table converter

**Files:**
- Modify: `C:\Users\ZXY\.codex\skills\wechat-clippings\scripts\clip_wechat_tikhub.py`

- [ ] **Step 1: Write the failing regression case in a local verification snippet**

```python
html = '''<div id="js_content"><table><tr><th>原始 Query</th><th>改写后 Query</th><th>召回率提升</th></tr><tr><td>"核辐射能赔吗"</td><td>"核辐射或核污染是否属于责任免除范围"</td><td>+22%</td></tr></table></div>'''
```

- [ ] **Step 2: Run the current converter and confirm it flattens the table**

Run: `python -c "from C:\\Users\\ZXY\\.codex\\skills\\wechat-clippings\\scripts\\clip_wechat_tikhub import html_to_markdown; print(html_to_markdown(html))"`
Expected: table rows appear as loose paragraphs, not a Markdown table

- [ ] **Step 3: Implement table buffering in `BodyHTMLParser`**

```python
class BodyHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self.link_stack: list[str] = []
        self.list_depth = 0
        self.in_pre = False
        self.skip_depth = 0
        self.table_stack: list[dict[str, Any]] = []
        self.in_table = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        ...
        elif tag == "table":
            self._start_table()
        elif tag == "tr":
            self._start_table_row()
        elif tag in {"td", "th"}:
            self._start_table_cell(tag)
```

- [ ] **Step 4: Emit Markdown rows when the table closes**

```python
def _flush_table(self) -> None:
    ...
    self.parts.append("\n" + "\n".join(rows) + "\n")
```

- [ ] **Step 5: Re-run the sample and confirm the output uses `| --- |` separators**

Run: the same `python -c ...` command
Expected: one Markdown table with header and rows

- [ ] **Step 6: Commit**

```bash
git add C:\Users\ZXY\.codex\skills\wechat-clippings\scripts\clip_wechat_tikhub.py
git commit -m "feat: preserve WeChat tables"
```

### Task 2: Recover pseudo-tables from plain WeChat text

**Files:**
- Modify: `C:\Users\ZXY\.codex\skills\wechat-clippings\scripts\clip_wechat_tikhub.py`

- [ ] **Step 1: Add a plain-text table detector after `normalize_block_spacing`**

```python
def recover_plain_tables(value: str) -> str:
    lines = value.splitlines()
    ...
```

- [ ] **Step 2: Convert short aligned paragraph groups into Markdown tables**

```python
pseudo = """原始 Query\n改写后 Query\n召回率提升\n\"核辐射能赔吗\"\n\"核辐射或核污染是否属于责任免除范围\"\n+22%"""
```

- [ ] **Step 3: Wire the detector into `clean_wechat_chrome` and `plain_wechat_text_to_markdown`**

```python
text = recover_plain_tables(text)
```

- [ ] **Step 4: Verify a table-like paragraph block becomes a Markdown table instead of free text**

Run: a local Python snippet that prints `plain_wechat_text_to_markdown(pseudo)`
Expected: header row plus separated Markdown table rows

- [ ] **Step 5: Commit**

```bash
git add C:\Users\ZXY\.codex\skills\wechat-clippings\scripts\clip_wechat_tikhub.py
git commit -m "feat: recover pseudo tables in WeChat text"
```

### Task 3: Infer languages for unlabeled fenced code blocks

**Files:**
- Modify: `C:\Users\ZXY\.codex\skills\wechat-clippings\scripts\clip_wechat_tikhub.py`

- [ ] **Step 1: Add a fenced-code language inference helper**

```python
def infer_code_language(code: str) -> str:
    ...
```

- [ ] **Step 2: Detect Python, JSON, and Bash before falling back to text**

```python
if looks_like_python(code):
    return "python"
if looks_like_json(code):
    return "json"
if looks_like_bash(code):
    return "bash"
return "text"
```

- [ ] **Step 3: Normalize unlabeled fences inside `normalize_inline_markdown`**

```python
text = re.sub(r"```\s*\n(.*?)\n```", lambda m: f"```{infer_code_language(m.group(1))}\n{m.group(1).strip()}\n```", text, flags=re.S)
```

- [ ] **Step 4: Verify the screenshot-style Python snippet is emitted as `python`, not `text`**

Run: a local Python snippet that prints a fence containing `expand_prompt = """...` and `def expand_query(...):`
Expected: fence starts with `python`

- [ ] **Step 5: Commit**

```bash
git add C:\Users\ZXY\.codex\skills\wechat-clippings\scripts\clip_wechat_tikhub.py
git commit -m "feat: infer unlabeled WeChat code fences"
```

### Task 4: Run a real clipping regression pass

**Files:**
- Modify: none
- Test: generate one or two local WeChat clipping samples from cached or live URLs

- [ ] **Step 1: Re-run clipping on a table-heavy article and a code-heavy article**

Run: `python C:\Users\ZXY\.codex\skills\wechat-clippings\scripts\clip_wechat_tikhub.py <url> --count 1`
Expected: tables render as Markdown tables and code fences get a non-`text` language where possible

- [ ] **Step 2: Inspect the resulting Markdown for broken spacing, malformed pipes, or false positives**

Expected: no raw table columns left as isolated lines and no obvious code fence mislabels

- [ ] **Step 3: Commit regression artifacts only if they are intended as durable examples**

```bash
git add <any_intended_fixture_or_sample>
git commit -m "test: add WeChat table and codeblock regression coverage"
```
