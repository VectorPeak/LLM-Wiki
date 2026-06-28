# 【RAG实战-14】MinerU解析短板分析

## 一、MinerU

> 最近有很多同学对 MinerU 的文档解析开源项目感兴趣，大家在写简历的时候，文档解析一般不会从 0-1 搭建，你可以考虑基于 MinerU 的现有问题进行改进（下文给出问题和处理思路），部署在你的项目中。
>
> 下面先用一段话快速概括：**MinerU 2.x 已把 PDF -> Markdown/JSON 的整体精度和速度拉到同类开源工具的第一梯队，但在版面顺序、复杂表格、竖排文字/小语种 OCR、公式与代码块识别、输出一致性、文件/硬件限制以及许可证合规性等方面仍有明显短板。**
>
> **官方 TODO 和 GitHub Issue 区也列出了若干尚未解决或正在处理/长期规划中的问题。接下来按类别展开说明，并给出改进建议。**

## 1. 版面与阅读顺序

| 问题 | 典型场景 | 说明 |
|---|---|---|
| 阅读顺序乱序 | 多栏期刊、广告型排版 | 模型以几何中心排序，极复杂布局仍会乱序（github.com） |
| 竖排文字支持不足 | 日文、古籍 PDF | 目前仅“有限支持”，竖排区域常被当成横排切块（mineru.readthedocs.io） |

> 改进方向：引入基于 GraphLayout 的阅读顺序推理或使用 VLM + RL 微调；竖排可通过增加直立文本数据，在 OCR 后处理阶段做方向校正。

## 2. 表格解析瓶颈

| 场景 | 症状 |
|---|---|
| 跨页长表 | 被拆成多个表且表头丢失（github.com） |
| 行列合并/嵌套表 | 单元格错位、列数溢出（github.com） |
| 90° 旋转表 | VLM 模式定位失败（github.com） |

> 改进方向：在版面检测后加跨页线索合并（行/列名相似度）、使用基于 TableDet + TableRec 的两阶段方法替换当前 rule-based 合并；对旋转表先做 Hough 或 DLA 方向检测再送入表格分割模型。

## 3. OCR 相关限制

- **小语种/重音符号**：拉丁重音、阿语易混字符误识率高（mineru.readthedocs.io）
- **无法关闭 OCR 开关**：`use_ocr=False` 仍触发 OCR 流程（github.com）
- **图像内文字**：虽然集成 PaddleOCR，可对 GPU 缓存与 batch-size 不够友好，易 OOM（github.com）

> 改进方向：切换 PP-OCRv5 多语模型并开放 lang fallback；把 OCR 模块抽成独立服务，增加显存/CPU 动态分配与真正的 disable 分支。

## 4. 公式与特殊符号识别

- 数学集合、化学分子式、函数曲线经常漏检或转 LaTeX 失败（github.com）
- Markdown 中渲染失败（分隔符/转义）（github.com）

> 改进方向：为公式检测增加 PIMask + TEDS Finetune；让公式渲染走 MathJax 并对 `$$...$$` 统一转换。

## 5. 结构化语义缺失

| 功能空缺 | 状态 |
|---|---|
| 标题分级 | 仅支持一级标题（mineru.readthedocs.io） |
| 目录/列表 | rule-based，罕见格式漏识（mineru.readthedocs.io） |
| 代码块识别 | 尚未支持（github.com） |
| 几何图形/化学式 | 仍在 TODO 列表（github.com） |

## 6. 输出一致性与重复字段

- VLM 模式偶尔生成重复块、字段名冲突（github.com）
- JSON 顺序不稳定，影响下游 RAG/QA 索引

## 7. 文件与运行环境限制

- **16 GB（推荐 32 GB）RAM & 6 GB+ VRAM**，超规格文档易超时（github.com）

## 8. 社区 TODO 与路线图

官方 README “TODO” 中仍列出 **阅读顺序模型化、索引/列表识别、表格识别增强、标题分类、代码块识别、化学式/几何形状识别** 等任务（github.com）。最新版 2.1.0 刚加入多语 PP-OCRv5、全局配置文件、显存优化等，但上述功能依然开发中或待社区 PR。

## 9. 快速改进清单

1. **二阶段表格解析**：TableDet -> TableRec 替换 rule-based 合并，提高跨页/合并单元格准确度。
2. **可插拔 OCR**：拆分为 micro-service，真正关闭 OCR 时绕过显存占用。也可以直接接入多模态 LLM。
3. **阅读顺序校正器**：Graph-based 或 RoBERTa-order 微调，专攻多栏/竖排。
4. **标题/代码块**：用 LLM-aided 分类（项目已内置 Qwen2.5-32B 接口，可在 post-process 里调）。
5. **License 梳理**：将 YOLO-AGPL 部分替换为 Apache-2.0 的 PP-YOLOE or RT-DETR，降低合规风险。
6. **输出一致性**：统一 middle_json -> schema-enforced JSON，再映射 Markdown，减少字段重复。
7. **小语种数据增补**：引入 publicly available OCR-Suite 语料 + 合成数据，提升拉丁/阿语准确率。
