+++
title = "C++11内存模型"
date = 2018-03-19
slug = "cpp11-memory-model"
[taxonomies]
categories = ["Post"]
tags = [
  "c++",
  "c++11",
  "memory-model",
  "concurrency",
]
+++
# Introduction
// cpp concurrency in action 里的例子
```c++
void undefined_behaviour_with_double_checked_locking() {
  if (!resource_ptr) { // 1
    std::lock_guard<std::mutex> lk(resource_mutex);
    if (!resource_ptr) { // 2
      resource_ptr.reset(new some_resource); // 3
    }
  }
  resource_ptr->do_something(); // 4
}
```
在 *C++ Concurrency in Action*  中提到过一段很有意思的代码，这段代码存在潜在的条件竞争。未被锁保护的操作①，没有与另一个线程中被锁保护了的操作③进行同步，在这样的情况下就有可能产生条件竞争。这个操作不光会覆盖指针本身，还有会影响到其指向的对象。所以在后面的操作④就有可能会导致不正确的结果。

# Out-of-order process
让我们从一个稍微简单一点的例子聊起。考虑现在我们的程序有两个线程，他们持有共同的变量 `a` 和 `b`，其中 `a` 和 `b` 的初始值都是0，两个线程分别执行了这样的代码：

>  线程1
```c++
b = 1;  // 1
a = 1;   // 2
```
> 线程2：
```c++
int a = 0, b = 0;
while (a == 0);
assert(b == 1);  // 3
```
在这个例子里面，我们可以保证每次在位置①的断言都可以成功么？
显然我们没有办法预期位置③的断言每次都成功，因为我们没法保证操作①每次都在操作②之前完成。
这里有两个主要的原因：
1. 编译器可能会对没有依赖的语句进行优化，重排他们的执行顺序
2. CPU在执行字节码的时候，会对没有依赖关系的语句重排执行顺序
显然在上面的例子中，操作②就有可能被重排到操作①之前，在这种情况下我们在线程2就没法观测到正确的结果，从而导致位置③的断言失败。
考虑这样的一种情况：
```asm
L1: LDR R1, [R0]
L2: ADD R2, R1, R1
L3: ADD R4, R3, R3
```
在按序执行的情况下，我们预期的顺序应该是：
`L1`->`L2`->`L3`

然而我们可以很容易的发现，语句3 和语句1 是没有依赖关系的，而语句2可以会依赖于语句1的执行结果，所以CPU经过乱序，并且可能将这三个操作发送到两个不同的CPU单元上，并且得到另一种执行顺序：
`L1`->`L2`
`L3`

再就是现在的多核CPU带来的可能缓存不一致的问题，在一个CPU核心上后写入的数据在其他的地方未必是后写入的。所以就会出现我们最上面的例子中，我们尝试使用一个标记位用来标记其他的数据是否已经准备好了，然后我们可能会在另一个核心上来判断这个标志位来决定所需要的数据是否已经准备就位。这样的操作的风险就在于，可能在被乱序执行的情况下，标志位被先写入了，然后才开始准备数据，这样在另一个核心观测就会得到不一样的、错误的结果。所以我们就必须在我们的代码中做出一些保护机制。

在C++11之前，我们有一种普遍的用法，就是内存屏障。而在C++11中，我们有了另一个选择，就是`atomic`。

# `atomic` in C++11
`atomic` 是在 C++11 中被加入了标准库的，这个库提供了针对于布尔、整数和指针类型的原子操作。原子操作意味着不可分的最小执行单位，一个原子操作要么成功，要么失败，是不会被线程的切换多打断的执行片段。对于在不同的线程上访问原子类型上操作是well-defined的，是不具有数据竞争的。

## 模板类 `atomic`
模板类 `atomic` 是整个库的核心，标准库中提供了针对布尔类型、整数类型和指针类型的特化，除此之外的情况请保证用于特化模板的类型时一个平凡的（trivial）类型。
在原子类上，显然有两个基础操作：
```c++
void store(T, memory_order = memory_order_seq_cst) volatile noexcept;
void store(T, memory_order = memory_order_seq_cst) noexcept;
T load(memory_order = memory_order_seq_cst) const volatile noexcept;
T load(memory_order = memory_order_seq_cst) const noexcept;
```
用于更新原子对象当前值的 `store` 方法和读取原子对象当前值的 `load` 方法。对于 `store` 方法，指定的内存顺序必须是 `std::memory_order_relaxed`、`std::memory_order_release` 或 `std::memory_order_seq_cst`其中的一个，指定为其他的内存顺序都是未定义行为；对于`load`方法，指定的内存顺序必须是 `std::memory_order_relaxed`、`std::memory_order_consume`、`std::memory_order_acquire`或`std::memory_order_seq_cst`其中的一个，其他的内存顺序同样都是未定义行为。
还有一个操作，原子的以新值替换旧值并返回旧值。
```c++
T exchange( T desired, std::memory_order order = std::memory_order_seq_cst ) noexcept;
T exchange( T desired, std::memory_order order = std::memory_order_seq_cst ) volatile noexcept;
```
这是一个读-修改-写的操作，类似的还有`test-and-set`，`fetch-and-add`，`compare-and-swap`。


# Memory Model
C++中提供了六种内存模型，其中的一些通常会成对出现。

memory_order_relaxed：对操作的上下文没有要求，仅要求当前操作的原子性
memory_order_consume：当前的加载操作，在其影响的内存位置上进行 *消费*：当前线程中依赖于该值读或写的操作不能被重排到该操作之前；在其他线程中，该值所依赖的变量的写入都可以被当前线程正确的观测到
memory_order_acquire：当前的加载操作，在其影响的内存位置上进行 *获取*：当前线程的读或写都不能重排到该操作之前；在其他线程中的所有位于该操作之前的读或写都可以被当前线程正确的观测到
memory_order_release：当前的存储操作，在其影响的内存位置上进行 *释放*：当前线程的读或写都不能重排到该操作之前；在其他线程中的所有位于该操作之前的写都可以被当前线程正确的观测到
memory_order_acq_rel：当前的加载或是存储操作，既在其影响的内存位置上进行 *获取* 也进行 *释放*
memory_order_seq_cst：当前的加载操作在其影响的内存位置进行 *获取*，存储操作进行 *释放*，读-修改-写操作进行 *获取* 和 *释放*


## `memory_order_relaxed`
在这个内存模型中，不要求操作在访问同样内存时候的操作顺序，只保证了原子性和修改的一致性。考虑下面的例子，对于初值为0的两个原子量`x`和`y`：
```c++
// thread 1
r1 = y.load(memory_order_relaxed); // 1
x.store(r1, memory_order_relaxed); // 2
// thread 2
r2 = x.load(memory_order_relaxed); // 3 
y.store(42, memory_order_relaxed); // 4
```
这里是允许出现`x`和`y`同时等于42的情况，因为我们即使知道操作①先于操作②，操作③先于操作④；但是我们没有约束操作④不能优先出现于操作①。所以我们可以观测到任何可能的结果。

## `memory_order_acquire` && `memory_order_consume`
在这个顺序模型中，存储操作 *释放* ；加载操作 *消费* 。如果线程1中的存储操作使用了 *释放* 标记；而线程2中的加载操作使用了 *消费* 标记。那么在线程1中的存储操作所依赖的所有内存写入都对在线程2中都可以被正确的观测到。这种同步仅仅建立在存储和加载的两个线程之间，对其他线程无效。

可以使用`std::kill_dependency`来消除从带有消费标记的加载操作开始的依赖树，不会讲依赖带入返回值。这个操作可以避免依赖链在离开函数作用域时，不必要的`memory_order_acquire`栅栏。

## `memory_order_acquire` && `memory_order_release`
在这个顺序模型中，存储操作 *释放*；加载操作 *获取*。如果线程1中的存储操作使用了 *释放* 标记；而线程2中的加载操作使用了 *获取* 标记。那么在线程1中，所以先于存储操作的内存写入在线程2中都可以被正确的观测到。这种同步仅建立在存储和加载的两个线程之间，对其他的线程无效。
所以考虑最开始的代码，如果我们将变量`a`改为`atomic<int>`，并且使用 release-acquire 的内存模型，就可以保证断言③的绝对正确。
```c++
atomic<int> a;
int b;
```
>  线程1
```c++
b = 1;  // 1
a.store(1, std::memory_order_release);  // 2
```
> 线程2：
```c++
int a = 0, b = 0;
while (a.load(std::memory_order_acquire) == 0);
assert(b == 1);  // 3
```
## `memory_order_seq_cst`
除了在进行 *释放* 和 *获取* 操作外，还会的所有持有此标记的操作建立一个单独全序（single total modification order）。这个表示每个标记了*memory_order_seq_cst*的操作，都可以观测到在其之前发生的标记有*memory_order_seq_cst*；并且可能观测到在其之前的，未标记为`memory_order_seq_cst`的操作。
```c++
#include <thread>
#include <atomic>
#include <cassert>
 
std::atomic<bool> x = {false};
std::atomic<bool> y = {false};
std::atomic<int> z = {0};
 
void write_x() {
    x.store(true, std::memory_order_seq_cst);
}
 
void write_y() {
    y.store(true, std::memory_order_seq_cst);
}
 
void read_x_then_y() {
    while (!x.load(std::memory_order_seq_cst));
    if (y.load(std::memory_order_seq_cst)) {
        ++z;
    }
}
 
void read_y_then_x() {
    while (!y.load(std::memory_order_seq_cst));
    if (x.load(std::memory_order_seq_cst)) {
        ++z;
    }
}
 
int main(){
    std::thread a(write_x);
    std::thread b(write_y);
    std::thread c(read_x_then_y);
    std::thread d(read_y_then_x);
    a.join(); b.join(); c.join(); d.join();
    assert(z.load() != 0);  // 1
}
```
上面例子中操作①处的断言绝不可能失败。

使用此序列顺序在多核模式下要求完全内存栅栏的CPU指令，这可能会成为性能的瓶颈，因为它将其受影响的内存的影响传播到了每个核心。