+++
title = "Const Reference of Pointer"
date = 2018-01-17
slug = "const-reference-of-pointer"
[taxonomies]
categories =  ["Post"]
tags = [
  "c++",
  "c++11",
  "reference",
  "pointer",
]
+++

问题起源：
在子类中实现一个模板父类的纯虚函数的时候，不能正确的通过编译。
```c++
template<typename T>
struct Fuck {
    virtual void shit(const T&) = 0;
}
```

<!-- more -->

`shit`函数接受一个常量引用，当我们使用一个指针类型(`A*`)来实例化这个模板类的时候，函数`shit`的类型就应该是：
```c++
void shit(const T&) = 0; <value T = A*>
```
当我尝试用下面这样的表示来实现这个函数的时候发生了编译错误：
```c++
struct FuckImpl : Fuck<A*> {
    void shit(const A*&) override;
}
```
这里正确的写法应该是：
```c++
struct FuckImpl : Fuck<A*> {
  void shit(A* const&) override;
};
```
这个问题大概由于`const`修饰符的结合性的问题，在前一种写法中`const`并没有修饰后面的引用，而是由于结合性的原因修饰了前面的指针。所以后一种写法中，`const`明确的修饰了后面引用。提供了正确的类型。

- - - - ---
额外的吐槽：这里就要吐槽`g++`的报错了，我用`clang`编译的时候就给出了正确的表达式写法，只要抄上去就好了。2333