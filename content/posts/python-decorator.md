+++
title = "Python 装饰器"
date = 2015-08-21
slug = "python-decorator"
[taxonomies]
categories =  ["Tech"]
tags = [
  "Python",
]
+++

给函数添加一个包装层以添加额外的处理部分，我们就可以使用装饰器这种方法。

###### 定义一个装饰器：

```
    import time
    
    def timethis(func):
        def wrapper(*args, **kwargs):
            start = time.time()
            result = func(*args, **kwargs)
            end = time.time()
            print(func.__name__, end - start)
            return result
        return wrapper
```
    

###### 使用这个装饰器

```
    @timethis
    def countdown(n):
        while n > 0:
            n -= 1
```
    

当如此编写代码的时候和单独这么写的效果是一样的：

```
    def countdown(n):
        while n > 0:
            n -= 1
    countdown = timethis(countdown)
```
    

###### 保存函数签名等信息

但是我们像上面那么做的时候，其实是丢失了函数签名，doc等信息的，这时候可以通过对装饰器的装饰来解决这个问题。改动一下上面的代码：

```
    import time
    from functools import wraps
    
    def timethis(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            start = time.time()
            result = func(*args, **kwargs)
            end = time.time()
            print(func.__name__, end - start)
            return result
        return wrapper
```
    

###### 对装饰器进行解包装

可以通过访问`__wrapped__`属性来实现对原始函数的访问。

###### 一个可以接受参数的装饰器

其实是很简单的，在外层的函数部分接受定义装饰器时的参数就可以了。

```
    from functools import wraps, partial
    import logging
    
    def logged(level, name=None, message=None):
        def decorator(func):
            logname = name if name else func.__module__
            log = logging.getLogger(logname)
            logmsg = message if message else func.__name__
    
            @wraps(func)
            def wrapper(*args, **kwargs):
                log.log(level, logmsg)
                return func(*args, **kwargs)
    
            return wrapper
    
        return decorator
    
    
    @logged(logging.DEBUG)
    def add(x, y):
        return x + y
    
    logging.basicConfig(level=logging.DEBUG)
    print(add(2, 3))
```
    

###### 装饰器参数需要可以修改

还是刚才的那段代码，这次用到了另一个装饰器并且使用了`nonlocal`关键字来声明装饰器内部的属性。

```
    from functools import wraps, partial
    import logging
    
    def attach_wrapper(obj, func=None):
        if func is None:
            return partial(attach_wrapper, obj)
        setattr(obj, func.__name__, func)
        return func
    
    def logged(level, name=None, message=None):
        def decorator(func):
            logname = name if name else func.__module__
            log = logging.getLogger(logname)
            logmsg = message if message else func.__name__
    
            @wraps(func)
            def wrapper(*args, **kwargs):
                log.log(level, logmsg)
                return func(*args, **kwargs)
    
            @attach_wrapper(wrapper)
            def set_level(newlevel):
                nonlocal level
                level = newlevel
    
            @attach_wrapper(wrapper)
            def set_message(newmsg):
                nonlocal logmsg
                logmsg = newmsg
    
            return wrapper
    
        return decorator
    
    
    @logged(logging.DEBUG)
    def add(x, y):
        return x + y
    
    logging.basicConfig(level=logging.DEBUG)
    print(add(2, 3))
```
    

###### 可选参数的装饰器

还是上面的那段代码，如果`level`属性也是可选的，像上面那么写我们就必须用这样的方式去使用它：

```
    @logged()
    def fuck():
        pass
```
    

但是显然这不是我所希望的，因为我们总会忘记那个空的括号。所以我们就可以改动一下：

```
    def logged(func=None, *, level=logging.DEBUG, name=None, message=None):
        if func is None:
            return partial(logged, level=level, name=name, message=message)
        logname = name if name else func.__module__
        log = logging.getLogger(logname)
        logmsg = message if message else func.__name__
    
        @wraps(func)
        def wrapper(*args, **kwargs):
            log.log(level, logmsg)
            return func(*args, **kwargs)
        return wrapper
```
    

副作用是`*`之后的参数必须显式的给出形参的名字。

###### 用类来实现装饰器

前面给出的都是用函数闭包来实现装饰器的例子，当然我们也可以用一个类来实现装饰器。

```
    from functools import wraps
    
    class A:
        def decorator1(self, func):
            @wraps(func)
            def wrapper(*args, **kwargs):
                print("Decorate 1")
                return func(*args, **kwargs)
            return wrapper
    
        @classmethod
        def decorator2(cls, func):
            @wraps(func)
            def wrapper(*args, **kwargs):
                print ('Decorator 2')
                return func(*args, **kwargs)
            return wrapper
```
    

###### 把装饰器定义成类

这个时候要实现类的`__call__`和`__get__`方法。

```
    class Profield:
        def __init__(self, func):
            wraps(func)(self)
            self.ncalls = 0
    
        def __call__(self, *args, **kwargs):
            self.ncalls += 1
            return self.__wrapped__(*args, **kwargs)
    
        def __get__(self, instance, cls):
            if instance is None:
                return self
            else:
                return types.MethodType(self, instance)
```
    

这里的`__get__`方法的实现一定不能忽略。

* * *

相关资料：

* [functools — Higher-order functions and operations on callable objects](https://docs.python.org/3.4/library/functools.html)

###### 利用装饰器给被包装的函数添加参数

```
    import inspect
    
    def optional_debug(func):
        if 'debug' in inspect.getargspec(func).args:
            raise TypeError('debug argument already defined.')
        @wraps(func)
        def wrapper(*args, debug=False, **kwargs):
            if debug:
                print("fuck debug", func.__name__)
            return func(*args, **kwargs)
        return wrapper
```
    

这里的实现还检查了被包装的函数是不是已经有要包装进去的参数了来保证不会有参数名字冲突的问题。 但是这种实现不能解决函数签名的问题，在函数签名中是没有我们加入的debug这个参数的。所以我们再次修改我们的实现。

```
    def optional_debug(func):
        if 'debug' in inspect.getargspec(func).args:
            raise TypeError('debug argument already defined.')
        @wraps(func)
        def wrapper(*args, debug=False, **kwargs):
            if debug:
                print("fuck debug", func.__name__)
            return func(*args, **kwargs)
    
        sig = inspect.signature(func)
        parms = list(sig, parameters.values())
        parms.append(inspect.Parameter('debug', inspect.Parameter.KEYWORD_ONLY, default=False))
        wrapper.__signature__ = sig.replace(parameters=parms)
    
        return wrapper
```
    

###### 利用装饰器改变类方法的行为

```
    def log_getattribute(cls):
        orig_getattribute = cls.__getattribute__
    
        def new_attribute(self, name):
            print('getting:', name)
            return orig_getattribute(self, name)
    
        cls.__getattribute__ = new_attribute
    
    @log_getattribute
    class A:
        def __init__(self, x):
            self.x = x
        def spam(self):
            pass
```