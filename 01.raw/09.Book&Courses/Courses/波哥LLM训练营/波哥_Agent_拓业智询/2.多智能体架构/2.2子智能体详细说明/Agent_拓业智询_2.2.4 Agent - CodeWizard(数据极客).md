# 2.2.4 Agent - CodeWizard（数据极客）

## 目录

1. 职责定位
2. 核心代码位置
3. Prompt 设计【重要】
   - 3.1 ANALYSIS_PROMPT（第 35-124 行）
   - 3.2 CHART_PROMPT（第 126-171 行）
   - 3.3 CODE_FIX_PROMPT（第 173-215 行）
4. 核心实现
   - 4.1 `process()` 入口（第 350-380 行）
   - 4.2 `_analyze_data()` 数据分析（第 382-520 行）
   - 4.3 沙箱执行环境【重要】：`_execute_in_sandbox()` 安全沙箱（第 1085-1301 行）
   - 4.4 自愈机制：`_execute_with_self_correction()` 带自愈的执行（第 521-608 行）
   - 4.5 代码清理（逻辑防御）：`_clean_code()` 清理 LLM 输出（第 746-927 行）
   - 4.6 调试日志：`_save_debug_log()` 单步调试（第 984-1009 行）

## 1. 职责定位

CodeWizard 是系统中唯一有权执行 Python 代码的 Agent，负责：

1. 数据清洗：统一不同来源的数据口径
2. 统计分析：计算关键指标（CAGR 年复合增长率、同比等）
3. 预测建模：简单的趋势预测
4. 专业绘图：生成高质量数据可视化（PNG 图片）

![CodeWizard 后端执行 Python 生成图表示例](https://img.vectorpeak.cn/obsidian/2026/05-06/codewizard_chart_output_upload.png?imageSlim)

## 2. 核心代码位置

文件路径：`backend/app/service/deep_research_v2/agents/wizard.py`（1302 行）

## 3. Prompt 设计【重要】

> 这里的 prompt 非常重要，prompt 书写的集大成。

### 3.1 ANALYSIS_PROMPT（第 35-124 行）

用于生成数据分析代码。

````python
ANALYSIS_PROMPT = """你是一位资深的数据分析师，擅长用Python进行数据处理和可视化。

## 研究问题
{query}

## 可用数据
{data_points}

## 任务
根据上述数据，生成Python代码完成以下任务:
1. 数据清洗和标准化
2. 计算关键统计指标
3. 生成专业的可视化图表

## 代码要求（必须严格遵守）

### 0. 禁止使用反斜杠续行（最重要！）
**严禁使用反斜杠 `\` 进行代码续行**。Python 的字典、列表、函数参数天然支持跨行书写，不需要反斜杠。

正确示例:
```python
data = {{
    "Year": [2020, 2021, 2022],
    "Value": [100, 200, 300]
}}
df = pd.DataFrame(data)
```

错误示例（绝对禁止）:
```python
data = {{ \
    "Year": ...
}}
```

### 1. 数据精简
- **只选取最关键的5-10个数据点**，不要把所有数据都写入代码
- **相同指标去重**：如果有多个年份的同一指标，只保留有代表性的几个
- **代码总长度不超过40行**
- **禁止生成重复数据**：如 `[2020, 2020, 2020...]` 这种重复是错误的

### 2. 数据定义方式
必须使用“列字典”格式定义数据:
```python
data = {{
    "Year": [2018, 2020, 2022, 2024],
    "Market_Size": [604.2, 1500, 2300, 3000]
}}
df = pd.DataFrame(data)
```

**禁止**使用复杂的嵌套列表 `[[...], [...]]`。

### 3. 数据清洗
创建 DataFrame 后，**必须**执行类型转换:
```python
for col in df.columns:
    if col != 'Year':
        df[col] = pd.to_numeric(df[col], errors='coerce')
df = df.dropna()
```

### 4. 环境限制
- **禁止import语句**，已预定义: pd, np, plt, sns
- **禁止plt.rcParams**，中文字体已预设

### 5. 高级图表样式（必须遵守）
生成专业、高端的商业图表，要求:
- **图表尺寸**: `plt.figure(figsize=(12, 7), dpi=200)`
- **seaborn主题**: `sns.set_theme(style='whitegrid', palette='husl')`
- **标题字体**: `plt.title('标题', fontsize=18, fontweight='bold', pad=20)`
- **轴标签**: `fontsize=14`
- **刻度**: `fontsize=12`
- **配色**: 使用专业配色如 `#6366f1`（靛蓝）、`#06b6d4`（青色）、`#10b981`（翡翠绿）
- **网格线**: `plt.grid(True, linestyle='--', alpha=0.3)`
- **去除边框**: `sns.despine()`
- **折线**: `linewidth=2.5, marker='o', markersize=8`，可加面积填充 `plt.fill_between()`
- **柱状图**: 添加数值标签
- **保存**: `plt.savefig('chart.png', dpi=200, bbox_inches='tight', facecolor='white')`

## 输出格式（严格JSON，code字段用\\n表示换行）
```json
{{
    "analysis_plan": "简要分析计划",
    "code": "sns.set_theme(style='whitegrid')\\ndata = {{'Year': [2020, 2022, 2024], 'Value': [100, 150, 200]}}\\ndf = pd.DataFrame(data)\\ndf['Value'] = pd.to_numeric(df['Value'], errors='coerce')\\nplt.figure(figsize=(12, 7), dpi=200)\\nplt.plot(df['Year'], df['Value'], linewidth=2.5, marker='o', markersize=8, color='#6366f1')\\nplt.fill_between(df['Year'], df['Value'], alpha=0.15, color='#6366f1')\\nplt.title('市场规模趋势', fontsize=18, fontweight='bold')\\nplt.xlabel('年份', fontsize=14)\\nplt.ylabel('规模（亿元）', fontsize=14)\\nplt.xticks(fontsize=12)\\nplt.yticks(fontsize=12)\\nsns.despine()\\nplt.savefig('chart.png', dpi=200, bbox_inches='tight', facecolor='white')",
    "expected_outputs": ["图表描述"]
}}
```

注意: code 字段中的换行请使用 `\\n` 字符表示，不要使用物理换行符，也**绝对不要使用续行符 `\\`**。
"""
````

关键要求：

- 禁止使用反斜杠续行：`\` 会导致 `unexpected character after line continuation character` 错误
- 数据精简：只选取最关键的 5-10 个数据点
- 列字典格式：`data = {"Year": [2020, 2022], "Value": [100, 200]}`
- 代码长度：不超过 40 行
- 禁止 `import`：已预导入 `pd`、`np`、`plt`、`sns`
- 高级样式：seaborn 主题、专业配色、高 DPI

示例代码：

```python
sns.set_theme(style='whitegrid')
data = {'Year': [2020, 2022, 2024], 'Value': [100, 150, 200]}
df = pd.DataFrame(data)
df['Value'] = pd.to_numeric(df['Value'], errors='coerce')
plt.figure(figsize=(12, 7), dpi=200)
plt.plot(df['Year'], df['Value'], linewidth=2.5, marker='o', markersize=8, color='#6366f1')
plt.fill_between(df['Year'], df['Value'], alpha=0.15, color='#6366f1')
plt.title('市场规模趋势', fontsize=18, fontweight='bold')
plt.xlabel('年份', fontsize=14)
plt.ylabel('规模（亿元）', fontsize=14)
sns.despine()
plt.savefig('chart.png', dpi=200, bbox_inches='tight', facecolor='white')
```

### 3.2 CHART_PROMPT（第 126-171 行）

用于生成特定类型图表的代码。

````python
CHART_PROMPT = """你是专业的数据可视化专家，擅长制作高端商业图表。

## 主题: {topic}
## 图表类型: {chart_type}
## 标题: {title}

## 数据
{data}

## 代码要求（重要）

### 基础要求
1. **严禁使用反斜杠 `\` 进行代码续行**
2. **不要写import语句**，已预导入: pd, np, plt, sns
3. 数据定义使用标准字典格式: `data = {{"col1": [...], "col2": [...]}}`

### 高级样式要求（必须遵守）
1. **图表尺寸**: `plt.figure(figsize=(12, 7), dpi=200)`
2. **使用 seaborn 主题**: `sns.set_theme(style='whitegrid', palette='husl')`
3. **标题字体**: `plt.title('标题', fontsize=18, fontweight='bold', pad=20)`
4. **坐标轴标签**: `plt.xlabel('X轴', fontsize=14)` 和 `plt.ylabel('Y轴', fontsize=14)`
5. **刻度字体**: `plt.xticks(fontsize=12)` 和 `plt.yticks(fontsize=12)`
6. **添加数据标签**: 在柱状图或折线图的数据点上显示数值
7. **配色方案**: 使用渐变色或专业配色，如 `color='#6366f1'` 或 `palette='Blues_d'`
8. **网格线**: 使用浅色虚线网格 `plt.grid(True, linestyle='--', alpha=0.3)`
9. **边框优化**: `sns.despine()` 去除上右边框
10. **保存**: `plt.savefig('chart.png', dpi=200, bbox_inches='tight', facecolor='white', edgecolor='none')`

### 折线图额外要求
- 线宽 2.5: `linewidth=2.5`
- 添加数据点标记: `marker='o', markersize=8`
- 添加面积填充: `plt.fill_between(x, y, alpha=0.15)`

### 柱状图额外要求
- 圆角效果（如支持）
- 添加数值标签: `for i, v in enumerate(values): plt.text(i, v + offset, str(v), ha='center', fontsize=11)`

## 输出格式（严格JSON）
```json
{{
    "code": "sns.set_theme(style='whitegrid')\\ndata = {{'Year': [2020, 2022], 'Value': [100, 200]}}\\ndf = pd.DataFrame(data)\\nplt.figure(figsize=(12, 7), dpi=200)\\nplt.bar(df['Year'], df['Value'], color='#6366f1')\\nplt.title('标题', fontsize=18, fontweight='bold')\\nplt.xlabel('年份', fontsize=14)\\nplt.ylabel('数值', fontsize=14)\\nplt.xticks(fontsize=12)\\nplt.yticks(fontsize=12)\\nsns.despine()\\nplt.savefig('chart.png', dpi=200, bbox_inches='tight', facecolor='white')",
    "chart_description": "图表说明"
}}
```

注意: code字段用 `\\n` 表示换行，**绝对不要使用续行符 `\\`**。
"""
````

支持的图表类型：

- 折线图（line）
- 柱状图（bar）
- 饼图（pie）
- 散点图（scatter）
- 热力图（heatmap）

### 3.3 CODE_FIX_PROMPT（第 173-215 行）

用于修复执行失败的代码（自愈机制）。

````python
CODE_FIX_PROMPT = """你是一位Python专家，需要修复执行失败的代码。

## 错误类型诊断

请根据错误信息判断错误类型并采取对应修复方法:

1. **如果错误是 `could not convert string to float`**:
   说明你试图将包含中文或特殊字符的列作为数值列处理。
   **修复方法**: 在绘图或计算前，使用 `pd.to_numeric(df['col'], errors='coerce')`
   清洗该列，并删除 NaN 值。
   不要直接画包含中文内容的列（除非是作为标签）。

2. **如果错误是 `SyntaxError`**:
   检查是否有多余的反斜杠或未闭合的括号。

3. **如果错误是 `KeyError`**:
   检查 DataFrame 列名是否正确，确保使用的列名与数据定义一致。

4. **如果错误是类型相关（`TypeError`）**:
   检查数据类型是否匹配，必要时使用 `.astype()` 或 `pd.to_numeric()` 转换。

## 原始代码
{code}

## 错误信息
{error}

## 输出
{stdout}

## 要求
1. **不要写import语句**，已预导入: pd, np, plt, sns
2. 中文字体已预设
3. 使用“列字典”格式定义数据: `data = {{"col1": [...], "col2": [...]}}`
4. 创建 DataFrame 后立即转换数值列

## 输出格式
```json
{{
    "error_analysis": "错误原因分析",
    "fix_description": "具体修复说明",
    "fixed_code": "data = {{'Year': [2020, 2021], 'Value': [100, 200]}}\\ndf = pd.DataFrame(data)\\ndf['Value'] = pd.to_numeric(df['Value'], errors='coerce')\\nprint('done')"
}}
```
"""
````

错误诊断：

- `could not convert string to float` → 使用 `pd.to_numeric()` 清洗数据
- `SyntaxError` → 检查反斜杠、括号
- `KeyError` → 检查列名
- `TypeError` → 类型转换

## 4. 核心实现

### 4.1 `process()` 入口（第 350-380 行）

```python
async def process(self, state: ResearchState) -> ResearchState:
    """处理入口"""
    if state["phase"] != ResearchPhase.ANALYZING.value:
        # 检查是否有需要分析的数据
        if len(state["data_points"]) >= 3:
            state["phase"] = ResearchPhase.ANALYZING.value
        else:
            self.logger.warning(f"数据点不足 ({len(state['data_points'])} < 3)，跳过分析")
            return state

    # 执行数据分析
    await self._analyze_data(state)

    # 生成图表
    await self._generate_charts(state)

    return state
```

触发条件：

- `phase == ANALYZING` 或
- `data_points >= 3`

### 4.2 `_analyze_data()` 数据分析（第 382-520 行）

```python
async def _analyze_data(self, state: ResearchState) -> None:
    """分析数据"""
    if not state["data_points"]:
        return

    # 格式化数据点
    data_summary = []
    for dp in state["data_points"]:
        data_summary.append(f"- {dp.get('name')}: {dp.get('value')} {dp.get('unit', '')} ({dp.get('year', 'N/A')})")

    prompt = self.ANALYSIS_PROMPT.format(
        query=state["query"],
        data_points="\n".join(data_summary)
    )

    response = await self.call_llm(
        system_prompt="你是专业的数据分析师，擅长Python数据处理和可视化。",
        user_prompt=prompt,
        json_mode=True
    )

    result = self.parse_json_response(response)

    if result and result.get("code"):
        code = result["code"]

        # 确保 code 是字符串类型
        if isinstance(code, list):
            code = "\n".join(str(c) for c in code)

        # 清理代码
        cleaned_code = self._clean_code(code)

        # 执行代码（带自愈能力）
        execution_result = await self._execute_with_self_correction(
            cleaned_code,
            state
        )

        # 如果生成了图表，发送 chart SSE 事件
        charts_generated = execution_result.get("charts", [])
        if charts_generated:
            for i, chart_b64 in enumerate(charts_generated):
                chart_entry = {
                    "id": f"chart_analysis_{uuid.uuid4().hex[:8]}",
                    "title": f"数据分析图表 {i+1}",
                    "chart_type": "generated",
                    "image_base64": chart_b64,
                    "section_id": "analysis"
                }
                state["charts"].append(chart_entry)

                # 发送单个图表事件到前端
                self.add_message(state, "chart", {
                    "agent": self.name,
                    "title": chart_entry["title"],
                    "chart_type": "generated",
                    "image_base64": chart_b64
                })
```

## 4.3 沙箱执行环境【重要】

### `_execute_in_sandbox()` 安全沙箱（第 1085-1301 行）

```python
def _execute_in_sandbox(self, code: str) -> Dict[str, Any]:
    """
    沙箱执行代码

    注意：这是一个简化的沙箱，生产环境应使用更安全的方案
    如 Docker 容器或专门的代码执行服务
    """
    import matplotlib
    matplotlib.use('Agg')  # 非交互式后端
    import matplotlib.pyplot as plt

    # 预导入所有允许的模块
    import pandas as pd
    import numpy as np
    import seaborn as sns

    # 白名单基础模块
    allowed_base_modules = [
        'pandas', 'numpy', 'matplotlib', 'seaborn',
        'datetime', 'math', 'statistics', 'json', 'collections', 're'
    ]

    # 保存原始的 __import__ 函数
    import builtins
    original_import = builtins.__import__

    def safe_import(name, globals=None, locals=None, fromlist=(), level=0):
        """安全的 import 函数，只允许白名单模块"""
        base_module = name.split('.')[0]
        if base_module in allowed_base_modules:
            return original_import(name, globals, locals, fromlist, level)
        raise ImportError(f"Import of '{name}' is not allowed in sandbox")

    # 准备执行环境
    exec_globals = {
        '__builtins__': {
            '__import__': safe_import,
            'print': print,
            'len': len,
            'range': range,
            # ... 其他安全的内置函数 ...
            'open': None,  # 禁用 open
        },
        # 直接提供模块引用（无需 import 即可使用）
        'pd': pd,
        'np': np,
        'plt': plt,
        'sns': sns,
    }

    # 捕获输出
    stdout_capture = io.StringIO()
    stderr_capture = io.StringIO()
    charts = []

    try:
        # 预设高级图表样式
        chinese_fonts = [
            'Heiti TC', 'STHeiti', 'PingFang HK', 'Hiragino Sans GB',
            'SimHei', 'Microsoft YaHei', 'Arial Unicode MS', 'DejaVu Sans'
        ]
        plt.rcParams['font.sans-serif'] = chinese_fonts
        plt.rcParams['axes.unicode_minus'] = False
        plt.rcParams['figure.figsize'] = [12, 7]
        plt.rcParams['figure.dpi'] = 200
        plt.rcParams['axes.titlesize'] = 18
        plt.rcParams['axes.titleweight'] = 'bold'

        with redirect_stdout(stdout_capture), redirect_stderr(stderr_capture):
            exec(code, exec_globals)

        # 检查是否生成了图表
        fig = plt.gcf()
        if fig.get_axes():
            buf = io.BytesIO()
            fig.savefig(buf, format='png', dpi=150, bbox_inches='tight', facecolor='white')
            buf.seek(0)
            chart_b64 = base64.b64encode(buf.read()).decode('utf-8')
            charts.append(chart_b64)
            plt.close(fig)

        return {
            "success": True,
            "output": stdout_capture.getvalue(),
            "error": stderr_capture.getvalue() if stderr_capture.getvalue() else None,
            "charts": charts
        }

    except Exception as e:
        plt.close('all')
        return {
            "success": False,
            "output": stdout_capture.getvalue(),
            "error": str(e),
            "charts": []
        }
```

安全机制：

1. 白名单 import：只允许 pandas、numpy、matplotlib、seaborn 等安全模块
2. 禁用危险函数：禁用 `open`、`exec`、`eval`、`os`、`sys`、`subprocess`
3. 禁止网络访问：禁用 `requests`、`urllib`、`socket`
4. 非交互式后端：`matplotlib.use('Agg')`，不弹窗
5. 中文字体预设：避免中文乱码

## 4.4 自愈机制

### `_execute_with_self_correction()` 带自愈的执行（第 521-608 行）

```python
async def _execute_with_self_correction(
    self,
    code: str,
    state: ResearchState,
    max_retries: int = 3
) -> Dict[str, Any]:
    """
    带自愈能力的代码执行

    特点:
    - 首次执行失败后，将错误信息反馈给LLM修复
    - 最多重试 max_retries 次
    - 记录所有尝试和修复过程
    """
    current_code = code
    retries = 0

    while retries <= max_retries:
        # 执行代码
        result = await self._execute_code(current_code)

        if result.get("success"):
            return {
                "success": True,
                "output": result.get("output", ""),
                "charts": result.get("charts", []),
                "retries": retries,
                "final_code": current_code
            }

        # 执行失败，尝试修复
        error = result.get("error", "Unknown error")
        stdout = result.get("output", "")

        if retries >= max_retries:
            return {
                "success": False,
                "error": error,
                "output": stdout,
                "charts": [],
                "retries": retries,
                "final_code": current_code
            }

        # 发送修复尝试消息
        self.add_message(state, "thought", {
            "agent": self.name,
            "content": f"代码执行失败（第{retries + 1}次），正在自动修复: {error[:100]}..."
        })

        # 调用 LLM 修复代码
        fixed_result = await self._fix_code(current_code, error, stdout)

        if fixed_result and fixed_result.get("fixed_code"):
            current_code = fixed_result["fixed_code"]
            self.logger.info(f"Code fixed: {fixed_result.get('fix_description', 'N/A')}")

            # 发送修复后的代码
            self.add_message(state, "code_fix", {
                "agent": self.name,
                "error_analysis": fixed_result.get("error_analysis", ""),
                "fix_description": fixed_result.get("fix_description", ""),
                "retry": retries + 1
            })
        else:
            break

        retries += 1

    return {
        "success": False,
        "error": "Max retries exceeded",
        "retries": retries,
        "final_code": current_code
    }
```

自愈流程：

1. 执行代码 → 失败
2. 将错误信息发送给 LLM → 生成修复后的代码
3. 执行修复后的代码 → 成功/失败
4. 最多重试 3 次

## 4.5 代码清理（逻辑防御）

### `_clean_code()` 清理 LLM 输出（第 746-927 行）

这是最复杂的函数，用于修复 LLM 生成代码中的格式问题。

核心问题：LLM 可能输出以下格式：

```python
# 错误格式 1：反斜杠续行
data = { \
    "Year": [2020, 2021]
}

# 错误格式 2：转义的 \n
sns.set_theme(style='whitegrid')\ndata = {...}\nplt.plot(...)

# 错误格式 3：LaTeX 风格换行
data = {...}\\[10pt]df = pd.DataFrame(data)

# 错误格式 4：语句粘连
df = pd.DataFrame(data) plt.figure(figsize=(12, 7))
```

清理策略：

```python
def _clean_code(self, code: str) -> str:
    """清理LLM生成的代码，修复常见格式问题"""
    import re

    # 移除markdown代码块标记
    code = re.sub(r'^```python\s*', '', code, flags=re.MULTILINE)
    code = re.sub(r'^```\s*$', '', code, flags=re.MULTILINE)

    # 如果代码已经是正常的多行格式
    if '\n' in code and '\\n' not in code:
        return '\n'.join([line.rstrip() for line in code.split('\n')]).strip()

    # 使用占位符保护字符串内的 \n
    placeholder = "__NL_PLACEHOLDER__"

    def protect_strings(text):
        """保护字符串字面量内的 \n"""
        # ... 字符级处理，区分行分隔符和字符串内的 \n ...

    protected = protect_strings(code)

    # 处理异常换行标记
    protected = re.sub(r'\\\\?\[\d+pt\]\s*', '\n', protected)  # LaTeX 风格
    protected = re.sub(r'\\\\?\[换行\]\s*', '\n', protected)   # 中文标记
    protected = protected.replace('\\\\[n]', '\n')              # [\n] 格式

    # 修复语句粘连
    protected = re.sub(
        r'([^\\])\\n(True|False|None)\s+(plt\.|fig\s*=|ax\.|df\s*=)',
        r'\1\n\2',
        protected
    )

    # 处理转义换行
    protected = protected.replace('\\\\\\n', '\n')  # 四重转义
    protected = protected.replace('\\\\n', '\n')    # 双重转义
    protected = protected.replace('\\n', '\n')      # 单重转义

    # 恢复字符串内的 \n
    protected = protected.replace(placeholder, '\\n')

    # 移除所有行尾的续行符（反斜杠）
    lines = protected.split('\n')
    cleaned_lines = []
    for line in lines:
        # 移除 import 语句
        if line.strip().startswith('import ') or line.strip().startswith('from '):
            continue

        # 移除 plt.rcParams
        if 'plt.rcParams' in line:
            continue

        # 移除行尾的 \（核心修复）
        line = re.sub(r'\\\s*$', '', line)
        cleaned_lines.append(line.rstrip())

    return '\n'.join(cleaned_lines).strip()
```

关键修复：

- 第 918 行：`line = re.sub(r'\\\s*$', '', line)`：移除所有行尾的反斜杠续行符

## 4.6 调试日志

### `_save_debug_log()` 单步调试（第 984-1009 行）

```python
def _save_debug_log(self, step_name: str, content: str):
    """
    保存单步调试日志，便于追踪代码执行流程

    每次运行会创建一个带时间戳的目录
    """
    import os
    from datetime import datetime

    if not hasattr(self, '_debug_session_dir'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self._debug_session_dir = f"/tmp/codewizard_debug/session_{timestamp}"
        os.makedirs(self._debug_session_dir, exist_ok=True)

    file_path = f"{self._debug_session_dir}/{step_name}.txt"
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(f"=== {step_name} ===\n")
        f.write(f"时间: {datetime.now().isoformat()}\n")
        f.write(f"长度: {len(content)} 字符\n")
        f.write("=" * 60 + "\n\n")
        f.write(content)
```

日志文件（位于 `/tmp/codewizard_debug/session_YYYYMMDD_HHMMSS/`）：

- `1_llm_response.txt`：LLM 原始响应
- `2_json_parsed.txt`：JSON 解析结果
- `3_code_raw.txt`：原始 code 字段
- `4_code_before_clean.txt`：清理前的代码
- `5_code_after_clean.txt`：清理后的代码
- `6_syntax_check.txt`：语法检查结果
- `7_validation.txt`：有效性验证
- `8_execution_result.txt`：执行结果

## 5. 高级图表样式

### 5.1 预设样式（第 1209-1231 行）

```python
# 中文字体
chinese_fonts = ['Heiti TC', 'STHeiti', 'PingFang HK', 'Hiragino Sans GB']
plt.rcParams['font.sans-serif'] = chinese_fonts
plt.rcParams['axes.unicode_minus'] = False

# 高级默认样式
plt.rcParams['figure.figsize'] = [12, 7]
plt.rcParams['figure.dpi'] = 200
plt.rcParams['font.size'] = 12
plt.rcParams['axes.titlesize'] = 18
plt.rcParams['axes.titleweight'] = 'bold'
plt.rcParams['axes.labelsize'] = 14
plt.rcParams['xtick.labelsize'] = 12
plt.rcParams['ytick.labelsize'] = 12
plt.rcParams['legend.fontsize'] = 12
plt.rcParams['axes.spines.top'] = False
plt.rcParams['axes.spines.right'] = False
plt.rcParams['axes.grid'] = True
plt.rcParams['grid.alpha'] = 0.3
plt.rcParams['grid.linestyle'] = '--'
```

### 5.2 专业配色

```python
# 渐变色
color = '#6366f1'  # 靛蓝
color = '#06b6d4'  # 青色
color = '#10b981'  # 翡翠绿

# 面积填充
plt.fill_between(x, y, alpha=0.15, color='#6366f1')
```

## 6. 模型选择

配置位置：`backend/app/config/llm_config.py`

```python
wizard: ModelConfig = field(default_factory=lambda: ModelConfig(
    model="deepseekv3.2",
    temperature=0.3,
    max_tokens=4000
))
```

## 7. SSE 事件流

CodeWizard 发送的 SSE 事件：

| 事件类型 | 说明 | 示例 |
| --- | --- | --- |
| `code` | 生成的代码 | `{"language": "python", "code": "..."}` |
| `code_result` | 执行结果 | `{"success": true, "has_chart": true}` |
| `code_fix` | 自愈修复 | `{"error_analysis": "...", "retry": 1}` |
| `chart` | 生成的图表 | `{"title": "...", "image_base64": "..."}` |

## 8. 安全限制

### 8.1 禁止的操作（第 310-339 行）

```python
FORBIDDEN_PATTERNS = [
    r'\bimport\s+os\b',
    r'\bimport\s+sys\b',
    r'\bimport\s+subprocess\b',
    r'\bopen\s*\(',
    r'\bexec\s*\(',
    r'\beval\s*\(',
    r'__import__',
    r'\bimport\s+requests\b',
    r'\bimport\s+socket\b',
    # ... 更多禁止模式 ...
]
```

### 8.2 允许的模块（第 300-307 行）

```python
ALLOWED_MODULES = {
    'pandas', 'numpy', 'matplotlib', 'matplotlib.pyplot',
    'seaborn', 'datetime', 'math', 'statistics', 'json',
    'collections', 're', 'wordcloud', 'jieba'
}
```

## 9. 总结

CodeWizard 是系统中唯一执行代码的 Agent（1302 行），其核心能力：

1. 沙箱执行：安全的 Python 代码执行环境
2. 自愈机制：代码执行失败后自动修复（最多 3 次）
3. 代码清理：复杂的清理逻辑，修复 LLM 输出的格式问题
4. 高级样式：专业的 seaborn 主题、高 DPI、渐变色
5. 中文支持：预设中文字体，避免乱码
6. 图片输出：生成 base64 编码的 PNG 图片
7. 调试友好：完整的单步调试日志

与 DataAnalyst 的区别：

- DataAnalyst：生成 ECharts JSON 配置（前端渲染）
- CodeWizard：执行 Python 代码，生成 PNG 图片（后端渲染）

安全机制：

- 白名单 import
- 禁用文件操作、网络访问、系统调用
- 正则表达式检测危险操作
