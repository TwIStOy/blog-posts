+++
title = "Operator new 的重载"
date = 2015-08-31
slug = "override-operator-new"
[taxonomies]
categories =  ["Tech"]
tags = [
  "c++",
  "operator new",
  "override",
]
+++
new作为关键字是不能被重载的。当new作为关键字的时候的行为是：

1.  调用operator new分配内存。
2.  调用构造函数生成对象。
3.  返回相应的指针。

new的行为是不能被改变的，但是这里的operator new的行为是可以改变的。也就是对operator new的重载。

### new 运算符表达式的重载

**operator new**操作符可以被每个类作为成员函数重载，也可以作为全局函数重载。这里应该是推荐作为成员函数重载的。

##### **void* operator new(size\_t size) throw(std::bad\_alloc);**

参数是一个`size_t`类型，指明了要分配的内存的大小。

```
    void* operator new(std::size_t) throw(std::bad_alloc);
    void* operator delete(std::size_t) throw();
```
    

如果在构造函数执行的时候发生异常，在栈展开的过程中，要回收在第一步中**operator new**分配的内存的时候，会调用想对应的**operator delete**函数。

##### **void* operator new\[\](size\_t size) throw(std::bad\_alloc);**

用于分配数组对象内存的new操作符。如果数组的基类型没有这个成员函数的话，会调用全局的版本分配内存。

```
    void * operator new[] (std::size_t) throw(std::bad_alloc);
    void operator delete[](void*) throw();
```
    

##### **void* operator new(size_t,void*)**

带位置的new操作符（placement new）重载版本。C++标准库中已经提供了这个版本的简单实现，只是简单的返回参数指定的地址。

```
    // Default placement versions of operator new.
    inline void* operator new(std::size_t, void* __p) throw() { return __p; }
    inline void* operator new[](std::size_t, void* __p) throw() { return __p; }
    
    // Default placement versions of operator delete.
    inline void  operator delete  (void*, void*) throw() { }
    inline void  operator delete[](void*, void*) throw() { }
```
    

##### 自行定制参数的operator new函数

```
    operator new(size_,Type1, Type2, ... );
```
    

这时候就可以自定义参数以及其行为。

```
    struct point {
        int x, y;
        point() = default;
        point(int x, int y) : x(x), y(y) {}
        void* operator new(size_t, int&cur);
    } _pool[maxn];
    int cur;
    
    void* point::operator new(size_t sz, int &cur) {
        return _pool+(cur++);
    }
```
    

---

reference:

1.  [https://zh.wikipedia.org/zh/New_(C%2B%2B](https://zh.wikipedia.org/zh/New_(C%2B%2B))