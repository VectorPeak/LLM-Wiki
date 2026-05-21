自定义注解+AOP缓存优化


**团队不敢让新人写“会影响全局执行路径的 AOP.** AOP 的危险点在于：它不是普通函数调用，而是“隐形插队”
~~~
普通业务代码是这样：
Controller -> Service -> Mapper -> DB

AOP 后变成：
Controller -> 代理对象 -> AOP 前置逻辑 -> Service 方法 -> AOP 后置逻辑
~~~

**为什么不敢让新人写？**
**第一，AOP 的影响范围容易失控**
一个切点写宽了：
execution(\* com.xxx.service..\*(..))


**第二，Spring AOP 有代理陷阱**
比如同一个类内部调用，常见情况下不会经过代理：
~~~
@Service
public class UserService {
    @MyCache
    public User getUser(Long id) {
        return queryDb(id);
    }

    public User wrapper(Long id) {
        return getUser(id); // 这里可能绕过 AOP
    }
}
~~~


**第三，AOP 顺序很容易出问题**
缓存、事务、权限、日志、限流、异步都可能是 AOP：
~~~
@Transactional
@MyCache
public Order getOrder(Long id) {}
~~~
到底是先开事务，还是先查缓存？  
缓存异常要不要回滚事务？  
缓存命中时事务还开不开？  
这些顺序不清楚，线上问题会很隐蔽。Spring 文档里也专门说明 advice 有执行顺序问题：


**第四，缓存 AOP 不是只会 get/set Redis**
真正难的是：
~~~
key 怎么生成？
空值要不要缓存？
TTL 如何设置？
如何防穿透、击穿、雪崩？
更新数据库后怎么删缓存？
缓存和事务提交顺序怎么保证？
Redis 挂了是否降级？
序列化失败怎么办？
同一个接口不同用户权限是否会串数据？
~~~

新人如果只写：
~~~
查 Redis -> 查不到执行方法 -> 写 Redis
~~~
看起来能跑，但很容易埋雷。

所以面试官看到“自定义注解 + AOP 缓存优化”会警觉，是因为它经常被包装成高级项目亮点，但实际可能只是重复造 Spring Cache 的轮子。Spring 本身已经有 @Cacheable、@CachePut、@CacheEvict：

更准确地说：
~~~
新人可以用现成的 @Cacheable
新人也可以在明确规范下改一个小 AOP
但不建议让新人从零设计全局缓存 AOP
因为 AOP 属于“框架层代码”。业务代码写错，通常坏一个功能；AOP 写错，可能让一批功能以看不见的方式坏掉
~~~

Seata
Seata分布式事务协调框架
**Seata 通常意味着系统已经复杂到需要跨服务、跨数据库的一致性治理，而很多简历项目并不真的达到这个复杂度**