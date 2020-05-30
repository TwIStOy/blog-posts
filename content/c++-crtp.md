+++
title = "Compare Between CRTP and Virtual"
date = 2018-10-16
slug = "compare-between-crtp-and-virtual"

[taxonomies]
categories = ["Post"]
tags = ["c++", "crtp", "virtual"]
+++

我们平时都会使用虚函数来实现 C++ 里的运行时的多态，但是虚函数会带来很多性能上面的问题：
1. 虚函数的调用需要额外的寻址
2. 虚函数不能被 inline，当使用比较小的虚函数的时候会带来很严重的性能负担
3. 需要在每个对象中维护一个额外的虚函数表

但是在有些情况下，我们就可以用一些静态的类型分发策略来带来一些性能上面的好处。

# 一个传统的例子
```c++
struct VirtualInterface {
  virtual void Skip(uint32_t steps) = 0;
};

struct VirtualImpl : public VirtualInterface {
  uint32_t index_;

  void Skip(uint32_t steps) override { index_ += steps; index_ %= INT_MAX; }
};

void VirtualRun(VirtualInterface* interface) {
  for (auto i = 0; i < N; i++) {
    for (auto j = 0; j < i; j++) {
      interface->Skip(j);
    }
  }
}
```
这里有一个很简单的例子，我们搞了一个简单的计数类来模拟这个过程。首先使用虚函数的方法去实现这个。在开了O2的情况下，运行了 3260628226 ns。

然后我们使用 CRTP 来实现：
```c++
template <typename Impl>
struct CrtpInterface {
  void Skip(uint32_t steps) { static_cast<Impl*>(this)->Skip(steps); }
};

struct CrtpImpl : public CrtpInterface<CrtpImpl> {
  void Skip(uint32_t steps) {
    index_ += steps;
    index_ %= INT_MAX;
  }

  uint32_t index_ = 0;
};

template <typename T>
void CrtpRun(CrtpInterface<T>* interface) {
  for (auto i = 0; i < N; i++) {
    for (auto j = 0; j < i; j++) {
      interface->Skip(j);
    }
  }
}
```
同样运行我们的代码， 29934437 ns。
显然在省去了查虚函数表，并且可以inline的情况下，程序有了更好的表现。

在具体的实现方式上，参考上面的实现就可以了…