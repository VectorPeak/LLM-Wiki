---
title: "算法面试专栏：python基础100题"
source: "https://mp.weixin.qq.com/s/0ECx-8tFA1T4QiwCwCV6pA"
author:
  - "[[乔木mq]]"
published:
created: 2026-05-19
description: "1. 在 CPython 中，list.append() 的时间复杂度在最坏情况下为 ，但其摊销复杂度为 。"
tags:
  - "clippings"
---
乔木mq *2026年4月3日 05:14*

1. 1\. 在 CPython 中， `list.append()` 的时间复杂度在最坏情况下为 ，但其摊销复杂度为 。请结合动态数组扩容策略（如 growth factor）推导其摊销分析过程，并说明为何 Python 选择 作为额外预留空间而非固定倍数。
2. 2\. 请从字节码层面解释为何 `a = a + [x]` 与 `a += [x]` 在可变对象（如 list）上的行为差异会导致性能数量级的不同，并用 `dis` 模块反汇编对比两者的操作码序列。
3. 3\. 给定一个包含 个元素的 `collections.deque` ，其 `rotate(k)` 方法的时间复杂度是多少？请结合其底层双向链表与块数组混合结构（block-linked list）分析旋转操作的指针重定向开销。
4. 4\. 在 GIL（Global Interpreter Lock）存在下，多线程 CPU-bound 任务无法并行。但某些 I/O 或 NumPy 操作却能“释放 GIL”。请列举至少三种 C 扩展模块主动释放 GIL 的典型场景，并说明其底层机制（如 `Py_BEGIN_ALLOW_THREADS` 宏的作用）。
5. 5\. 请推导 Python 整数对象（ `PyLongObject` ）在内存中的布局，并解释为何 `id(256) == id(256)` 但 `id(257) != id(257)` ，同时分析小整数缓存池（\[-5, 256\]）对引用计数和垃圾回收的影响。
6. 6\. 使用 `__slots__` 可减少实例内存占用。假设一个类有 个属性，普通实例 vs `__slots__` 实例的内存占用差值是多少？请基于 `PyObject_HEAD` 、 `__dict__` 指针、 `__weakref__` 指针及哈希表开销进行量化分析。
7. 7\. 在 CPython 的引用计数机制中，循环引用会导致内存泄漏。请描述 `gc` 模块如何通过三色标记-清除算法识别不可达循环，并推导其时间复杂度与对象图规模的关系。
8. 8\. 请分析 `asyncio` 事件循环中 `await asyncio.sleep(0)` 与 `await asyncio.sleep(1e-9)` 的调度行为差异，并解释为何前者能强制让出控制权而后者可能被优化掉。
9. 9\. 给定一个生成器函数 `gen()` ，调用 `next(gen())` 两次是否会创建两个独立的生成器状态？请从帧对象（ `PyFrameObject` ）生命周期和局部变量存储角度解释。
10. 10\. 在 Python 3.11+ 中，引入了“自适应解释器”（adaptive interpreter）和“快速调用协议”（vectorcall）。请说明 vectorcall 如何通过避免 `*args` 和 `**kwargs` 的元组/字典构造来降低函数调用开销，并量化其在高频调用场景下的性能收益。
11. 11\. 请推导 `functools.lru_cache(maxsize=n)` 的缓存淘汰策略时间复杂度，并说明其底层使用 `collections.OrderedDict` 时如何保证 O(1) 的 get/put 操作。
12. 12\. 在多重继承中，C3 线性化算法决定了 MRO（Method Resolution Order）。给定类 `class D(B, C): pass` ，其中 `B(A), C(A)` ，请手动执行 C3 合并规则推导 MRO，并证明其满足单调性和局部优先序。
13. 13\. 请解释 `sys.getsizeof()` 返回的大小为何不包括嵌套对象（如 list 中的元素），并设计一个递归函数精确计算任意嵌套容器的总内存占用（考虑字符串 intern、整数缓存等特殊情况）。
14. 14\. 在 `multiprocessing` 中， `spawn` 与 `fork` 启动方法在 Linux 上的内存复制行为有何本质区别？请结合 copy-on-write (COW) 机制分析 fork 后修改全局变量导致的物理内存膨胀问题。
15. 15\. 请分析 `pickle` 协议 5 引入的 out-of-band buffer 机制如何避免大数组序列化时的内存拷贝，并说明其与 `__reduce_ex__` 方法的协同工作方式。
16. 16\. 在 Python 字符串实现中，UTF-8、Latin-1 和 UCS-4 编码的选择依据是什么？请根据字符最大码点动态推导内部表示（ `compact unicode object` ）的内存布局公式。
17. 17\. 请推导 `heapq.heappushpop(heap, item)` 相比先 `heappush` 再 `heappop` 的常数因子优化，并分析其在滑动窗口 Top-K 场景下的缓存局部性优势。
18. 18\. 在 `contextvars` 模块中，上下文变量如何实现协程隔离？请从 `Context` 对象的链式快照（snapshot chain）和 copy-on-write 语义出发，分析其与 `threading.local` 的根本区别。
19. 19\. 请解释 `typing.Generic[T]` 在运行时如何通过 `__class_getitem__` 钩子实现参数化类型，并说明 `TypeVar` 的协变（covariant）约束如何影响 `isinstance` 检查的合法性。
20. 20\. 在 Python 3.12 的 `perf` profiling 支持中，如何通过 `--profile-import-time` 选项定位模块导入瓶颈？请结合 AST 编译、字节码生成和模块缓存（ `__pycache__` ）流程分析热点。
21. 21\. 请推导 `itertools.groupby(iterable, key)` 在输入未排序时的行为异常，并说明为何其内部状态机依赖于连续相等键值的稳定性。
22. 22\. 在 `dataclasses` 中， `frozen=True` 如何通过 `__setattr__` 拦截实现不可变性？请分析其与 `namedtuple` 在哈希计算和内存布局上的性能 trade-off。
23. 23\. 请分析 `pathlib.Path` 对象的 `__truediv__` 运算符重载如何实现跨平台路径拼接，并说明其与 `os.path.join` 在 Unicode normalization 和 trailing slash 处理上的差异。
24. 24\. 在 `decimal.Decimal` 的上下文中， `prec` 参数控制的是有效数字位数而非小数位数。请推导 `Decimal('1.23') + Decimal('4.567')` 在 `prec=4` 下的结果舍入过程（使用 IEEE 754 舍入模式）。
25. 25\. 请解释 `weakref` 模块如何避免循环引用，同时分析 `WeakKeyDictionary` 在键对象被回收时如何触发回调清理条目（涉及 `PyWeakReference` 的 callback 链表）。
26. 26\. 在 `ctypes` 中， `Structure._pack_` 属性如何影响字段对齐？请计算以下结构体在 `_pack_=1` 和默认对齐下的 sizeof 差异：
	```
	struct { char a; int b; short c; }
	```
27. 27\. 请推导 `re.compile(pattern).match(string)` 与 `re.match(pattern, string)` 在高频调用下的性能差异，并分析正则表达式缓存（ `_compile_cache` ）的 LRU 淘汰阈值。
28. 28\. 在 `logging` 模块中， `Logger` 的层级查找机制如何通过 `parent` 链实现？请说明为何 `logging.getLogger('a.b')` 会自动创建 `a` 的 placeholder logger。
29. 29\. 请分析 `unittest.mock.patch` 作为装饰器和上下文管理器时，在作用域退出时如何恢复原始对象（涉及 `__enter__` / `__exit__` 与 `start` / `stop` 的调用栈匹配）。
30. 30\. 在 `importlib` 中， `importlib.util.spec_from_file_location` 如何绕过 sys.path 加载模块？请说明其与 `exec(open(...).read())` 在命名空间污染和缓存注册上的根本区别。
31. 31\. 请推导 `numpy.array(list_of_lists)` 在非矩形输入（如 `[[1], [2,3]]` ）时的内存布局转换开销，并解释为何其返回 object dtype 而非抛出异常。
32. 32\. 在 `pandas` 中， `DataFrame.groupby().apply(func)` 的分组应用为何在某些情况下会触发多次 func 调用？请从 internal index alignment 和 dummy group 机制出发分析。
33. 33\. 请分析 `torch.utils.data.DataLoader` 中 `num_workers > 0` 时，worker 进程如何通过共享内存（ `shm` ）或文件描述符传递张量，并说明 `pin_memory=True` 对 GPU 传输带宽的影响。
34. 34\. 在 `scipy.sparse.csr_matrix` 中，矩阵-向量乘法 的计算复杂度是多少？请推导其基于 `indptr` 和 `indices` 的访存模式，并分析 cache miss 率与稀疏度的关系。
35. 35\. 请推导 `sklearn.preprocessing.StandardScaler` 的 `partial_fit` 方法如何增量更新均值 和方差 ，给出递推公式：
36. 36\. 在 `matplotlib` 中， `plt.plot()` 的 `drawstyle='steps-post'` 如何影响 line segment 的端点坐标？请推导其在离散事件可视化中的阶梯函数插值公式。
37. 37\. 请分析 `seaborn.heatmap` 在大数据矩阵（如 10k×10k）下为何会出现内存爆炸，并说明其内部调用 `matplotlib.pcolormesh` 时的 quad mesh 构建开销。
38. 38\. 在 `statsmodels` 的 OLS 回归中， `fit()` 方法如何通过 QR 分解避免 的显式求逆？请推导参数估计 的数值稳定性优势。
39. 39\. 请推导 `networkx.DiGraph` 的 `pagerank` 算法中阻尼因子 对迭代收敛速度的影响，并分析其 power iteration 的谱半径上界。
40. 40\. 在 `cvxpy` 中，问题规范化（canonicalization）如何将用户定义的目标函数转换为标准锥规划（conic form）？请以 Lasso 回归为例说明 epigraph 变换过程。
41. 41\. 请分析 `ray` 分布式框架中，对象存储（Plasma store）如何通过 memory-mapped 文件实现跨进程零拷贝，并说明其与 `multiprocessing.shared_memory` 的设计差异。
42. 42\. 在 `dask` 的 task graph 中， `compute(scheduler='threads')` 与 `scheduler='processes'` 在 GIL 限制下的适用场景有何不同？请结合 task 粒度与通信开销进行 trade-off 分析。
43. 43\. 请推导 `joblib.Parallel` 中 `backend='loky'` 相比 `'multiprocessing'` 在 worker 进程复用上的启动延迟优化，并说明其如何避免 fork 安全问题。
44. 44\. 在 `polars` DataFrame 中， `group_by().agg()` 如何利用 Apache Arrow 的列式内存布局实现向量化聚合？请分析其与 pandas 的 row-major 聚合在 CPU cache 利用率上的差异。
45. 45\. 请解释 `pyarrow.Table.from_pandas()` 在处理 categorical dtype 时如何映射为 dictionary-encoded array，并推导其内存压缩比公式（基于唯一值数量 与总行数 ）。
46. 46\. 在 `faiss` 的 IVF-PQ 索引中，请推导粗量化（coarse quantizer）与积量化（product quantizer）的联合距离近似公式：其中 为 centroid， 为残差。
47. 47\. 请分析 `transformers` 库中 `AutoTokenizer.from_pretrained()` 如何根据 `tokenizer_config.json` 动态加载分词器类，并说明其与模型架构的耦合机制。
48. 48\. 在 Hugging Face `Trainer` 中， `gradient_accumulation_steps > 1` 如何影响 optimizer step 的频率与 batch normalization 的统计量？请推导有效 batch size 与学习率缩放关系。
49. 49\. 请推导 LoRA 中权重更新矩阵 的梯度反向传播公式，并解释为什么固定预训练权重 仅训练 和 能显著减少 optimizer states 的显存占用？
50. 50\. 在 QLoRA 中，4-bit NormalFloat 量化如何通过分位数校准（quantile calibration）保持权重分布的动态范围？请推导其与 standard Float4 的 MSE 差异。
51. 51\. 请分析 FlashAttention-2 相较于 FlashAttention-1 在 block-wise 计算中的 warp-level 调度优化，并说明其如何减少 shared memory bank conflict。
52. 52\. 在 MoE（Mixture of Experts）架构中，Top-k 路由的负载均衡损失（auxiliary loss）如何定义？请推导其关于 expert assignment 概率 的梯度形式。
53. 53\. Ring Attention 如何通过环状设备拓扑将 attention 计算分解为 的 per-device 计算量（ 为序列长度， 为设备数）？请推导其通信步数与数据移动总量。
54. 54\. 在 DPO（Direct Preference Optimization）中，目标函数如何从 Bradley-Terry 偏好模型导出？请推导其与 PPO 的 KL penalty 项的等价性条件。
55. 55\. 请对比 PPO 与 DPO 在显存占用上的具体差异：PPO 需要存储 old policy logits 和 value estimates，而 DPO 仅需 reference model forward。量化两者在 batch size=1024 时的显存节省比例。
56. 56\. 在 ZeRO-3 中，参数分片（parameter partitioning）的具体通信时机是什么？请说明在 forward 前 gather、backward 后 reduce-scatter 的同步点如何与 gradient checkpointing 协同。
57. 57\. 请分析 FSDP（Fully Sharded Data Parallel）中 `reshard_after_forward=True` 如何通过及时释放 full parameter 来降低峰值显存，并推导其与 activation checkpointing 的叠加效果。
58. 58\. 在 LLM 推理中，KV Cache 的内存占用为 。请推导使用 PagedAttention（vLLM）如何通过虚拟内存分页将碎片率从 降至 。
59. 59\. 请解释 GPTQ 量化中 Hessian matrix 如何用于确定权重通道的量化敏感度，并推导二阶泰勒展开下的量化误差最小化目标。
60. 60\. 在 AWQ（Activation-aware Weight Quantization）中，如何通过 salient weight 保护机制保留对 activation 敏感的权重？请推导其 scale 因子 的校准过程。
61. 61\. 请分析 DeepSpeed 的 Ulysses 并行策略如何将 attention head 切分到不同 GPU，并推导其 all-to-all 通信量与 tensor parallelism 的 trade-off。
62. 62\. 在训练过程中出现 loss nan，但梯度 norm 正常。请从 mixed-precision training 的 loss scaling 机制出发，分析可能的 overflow 检测失效原因。
63. 63\. 当使用 AdamW 优化器时，weight decay 与 L2 regularization 在数学上是否等价？请推导其在非恒定学习率下的差异，并说明为何 AdamW 显式分离两者。

算法工程师 · 目录

继续滑动看下一个

乔木mq

向上滑动看下一个