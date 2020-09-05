+++
title = "Python元编程 - 在Python中实现重载"
date = 2017-05-08
slug = "python-meta-programming-1"
[taxonomies]
tags = [
  "python",
  "meta-programming",
  "python3",
]
+++

避免重复的代码，避免复制粘贴一些逻辑的时候，我们使用了函数。那么避免复制粘贴定义一些类似的，或者较为相像的类的时候，我们就需要一个生成类的方法，在Python中，我们使用的方法就是元类（MetaClass）。

## 元编程的应用（1）函数重载

在 Python 中，如果我们想要实现一个可以接受多种参数的函数，我们通常的方法都是在函数体里判断参数的个数，和各个的类型。这个办法很麻烦，并且也不容易维护，我也很希望可以像 C++ 一样可以简单的使用同样的名字去重载函数。利用元编程就可以做到。

我想做到像下面这样：

```python
class Fuck:
	def shit(self, x: int, y: int):
    	pass
    def shit(self, p: str):
    	pass

fuck = Fuck()
fuck.shit(1, 2)
fuck.shit("f")
```

首先是一个用来存重复函数的类，负责把一个函数的签名提取出来，存到一个 `dict` 里，在被运行的时候，按照参数类型找到存好的重载。

 ```python
import inspect, types
class MultiMethod:
    def __init__(self, name):
        self._methods = {}
        self.__name__ = name

    def insert_method(self, key, method):
        if key in self._methods:
            raise TypeError(
                "Can't insert arguments {}, already exists.".format(",".join([str(x) for x in key]))
            )
        self._methods[key] = method

    def register(self, method):
        sig = inspect.signature(method)

        arguments = []
        for name, parm in sig.parameters.items():
            if name == "self":
                continue
            if parm.annotation is inspect.Parameter.empty:
                raise TypeError(
                    "Argument {} must be annotated with a type.".format(name)
                )
            if not isinstance(parm.annotation, type):
                raise TypeError(
                    "Argument {} annotation must be a type.".format(name)
                )
            if parm.default is not inspect.Parameter.empty:
                self.insert_method(tuple(arguments), method)
            arguments.append(parm.annotation)
        self.insert_method(tuple(arguments), method)

    def __call__(self, *args):
        arguments = tuple(type(arg) for arg in args[1:])
        method = self._methods.get(arguments, None)
        if method:
            return method(*args)
        else:
            raise TypeError("No matching method for types {}".format(arguments))

    def __get__(self, instance, cls):
        if instance is not None:
            return types.MethodType(self, instance)
        else:
            return self
```

`dict` 类的子类，用于 `__prepare__` 函数的返回值，在 `__setitem__` 方法中进行实际的注册工作。
```python
class MultiDict(dict):
    def __setitem__(self, key, value):
        if key in self:
            current_value = self[key]
            if isinstance(current_value, MultiMethod):
                current_value.register(value)
            else:
                mvalue = MultiMethod(key)
                mvalue.register(current_value)
                mvalue.register(value)
                super().__setitem__(key, mvalue)
        else:
            super().__setitem__(key, value)
```

最后是支持函数重载的元类。
```python
class MultipleMeta(type):
    def __new__(cls, name, bases, clsdict):
        return type.__new__(cls, name, bases, clsdict)

    @classmethod
    def __prepare__(cls, name, bases):
        return MultiDict()
 ```