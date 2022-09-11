+++
title = "Interface in C++"
date = 2018-08-06
slug = "interface-in-cpp"
[taxonomies]
categories =  ["Tech"]
tags = [
  "c++",
  "c++11",
  "compile-time",
  "reflection",
  "interface",
  "template",
]
+++

# Interface In C++
## 问题提出
我记得我不止一次提到说，我更喜欢 golang 的泛型设计。一个优秀的泛型系统，我希望是来表示一个方法可以接受什么。应该是一个类似于 concept 的概念。我们都知道，在 C++ 里面，我们更多的使用虚函数来实现这个功能，就像下面这样：

<!-- more -->

```c++
struct IPerson {
  virtual std::string Name() = 0;
  virtual uint32_t Age() = 0;
};
```
我们搞了一个几个纯虚函数来表示一个接口类，然后我们都会搞一些类来继承这个类，就像下面这样：
```c++
struct Student : public IPerson {
  std::string Name() override;
  uint32_t Age() override;
};
```
那在使用的地方：
```c++
void Foo(IPerson*);
```
这已经是我们一般在写代码时候的常规做法了，但是在这样的情况下，我们要求了所有使用这个的地方，都只能使用指针或者引用。因为我们不能对一个对象来搞这些东西。

再回想一下，golang 的泛型的样子，我们有没有一个办法，可以搞一个类似于 `interface` 的东西来让一个对象也可以表示这些东西呢？

## 简单思考1
基于上面的问题，考虑这个问题的背后是表示的是个什么类型的多态问题。Ok，显然是个运行时多态。编译时多态的问题可以配合 `template`, `constexpr` 来解决。那么运行时多态在原本的 C++ 是通过虚函数来解决的。虚函数的实现，又是通过一个虚函数表来实现的。那么问题来了，我们可不可以自己来维护一个虚函数表来达到我们想要的效果呢？
上面我们需要的接口类，显然我们可以提炼出来一个这样的虚函数表：
```c++
struct vtable {
  std::string (*Name)(void*);
  uint32_t (*Age)(void*);
};
```
这个虚函数表表示了这个接口需要哪些接口，在这里使用 `void*` 来表示任意类型的指针。
那有了这个虚函数表之后，我们应该怎么使用这个呢？就像这个这样：
```c++
template<typename T>
vtable vtable_for = {
  [](void* p) {
    return static_cast<T*>(p)->Name();
  },
  [](void*) {
    return static_cast<T*>(p)->Age();
  },
};
```
这里用了 C++14 的新特性：变量模板，来构造了一个静态的全局变量，来表示对应的制定类型的虚函数表实现。
在有了上面两个东西的基础上，就得到了接口类的实现：
```c++
struct Person {
  template<typename T>
  Person(T t) : vtable_( &vtable_for<T> ), p(new T{t}) {}
 private:
  vtable* vtable_;
  void* p;
};
```
接下来，这个类就可以很棒了。你可以像下面这么定义：
```c++
std::vector<Person> persons;

persons.push_back(Student{});
persons.push_back(Teacher{});
...
```
用起来的时候，一切都看起来和 golang 的那个版本差不多了呢。



- - - - - - 
**Reference:**
1. [https://zh.wikipedia.org/wiki/C%2B%2B14#%E5%8F%98%E9%87%8F%E6%A8%A1%E6%9D%BF](https://zh.wikipedia.org/wiki/C%2B%2B14#%E5%8F%98%E9%87%8F%E6%A8%A1%E6%9D%BF)