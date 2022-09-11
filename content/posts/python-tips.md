+++
title = "Python Tips"
date = 2015-09-01
slug = "python-tips"
[taxonomies]
categories =  ["Tech"]
tags = [
  "python",
  "tips",
]
+++
### switch...case的写法

可以用if...elif...else的办法，或者使用跳转表：

```
    {
        0: "zero",
        1: "one",
        2: "two"
    }.get(x, "error")
```

### 有关于常量

显然命名风格这种办法并不能根本上阻止常量被改变。那么就可以定义一个类，修改这个类的`__setattr__`方法，当检查到key已经存在的时候直接抛出一个异常就可以了。

### 使用with自动关闭资源

with语句可以在代码块执行完毕后还原进入该代码块时的现场。包含有with语句的代码块的执行过程：  
1\. 计算表达式的值，返回一个上下文管理器对象。  
2\. 加载上下文管理器对象的`__exit__()`方法以备后用。  
3\. 调用上下文管理器对象的`__enter__()`方法。  
4\. 如果with语句中设置了目标对象，则将`__enter__()`方法的返回值赋值给目标对象。  
5\. 执行with中的代码块。  
6\. 如果步骤5中的代码正常结束，调用上下文管理器对象的`__exit__()`方法，其返回值直接忽略。  
7\. 如果步骤5中的代码执行过程中发生异常，调用上下文管理器对象的`__exit__()`方法，并将异常类型、值以及trackback信息作为参数传递给`__exit__()`方法。如果`__exit__()`返回值为`false`，则异常会被重新抛出；如果其返回值为`true`，异常被挂起，程序继续执行。

### 避免finally中可能发生的陷阱

小心由于finally中的return和break，导致被临时保存的应该向上层抛出的异常的屏蔽。  
finally会在其他部分的return之前被执行，也就是说其他部分中return的值会被保存起来，先去执行finally中的代码。如果finally中有return的话，会导致很奇怪严重的错误。

### 判断对象是否为空

Python中以下数据会当作空来处理：

* 常量None。
* 常量False。
* 任何形式的数值类型零，如：0、0L，0.0，0j。
* 空的序列，如：""、()、\[\]。
* 空的字典，如：{}。
* 当用户定义的类中定义了nonzero()方法和len()方法，并且该方法返回整数0或者布尔值False的时候。

Python会首先调用`__nonzero__()`方法来判断返回值为True或False。如果没定义这个方法，则会调用`__len__()`方法判断返回值是否为0。如果都没有，那么该类的实例在用布尔测试的时候都为真。

### 连接字符串应优先使用join而不是+

这里join比+的效率要高上很多。这里是由于join会先遍历整个list中的所有字符串，把他们的长度加起来，只进行一次内存申请，这里所有的字符串只会被拷贝一次；而运算符+则是每进行一个运算都要申请一次内存，并且进行一次内存拷贝，这样n个字符串连接就要进行n-1次内存申请。

### sort()和sorted()

```
    sorted(iterable[, cmp[, key[, reserse]]])
    a.sort([cmp[, key[, reserse]]])
```
    

* sort会直接修改原有列表，sorted会返回一个排序后的对象。
* 传入key比传入cmp的效率高，大约快50%。

### 使用traceback获取栈信息

```
    traceback.print_exc()
```
    

### 使用模块实现单例模式

在python中，模块是可以保证只初始化一次，线程安全，模块内变量绑定在模块中。完美的符合了单例模式的要求。

### 利用mixin特性让程序更灵活

利用了Python的mixin特性。在运行时可以改变一个实例的基类。

```
    #demo
    import mixins
    def staff():
        people = People()
        bases = [getattr(minxins, i) for i in config.checked()]
        people.__bases__ += tuple(bases)
        return people
```