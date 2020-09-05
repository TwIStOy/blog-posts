+++
title =  "使用智能指针的默认行为来避免内存泄漏"
date = 2017-07-02
slug = "leak-freedom-in-cpp-by-default"
[taxonomies]
tags = [
  "c++",
  "unique_ptr",
  "shared_ptr",
  "Memory Leak",
]
+++

2016年的 cppcon 上，Herb Sutter 的演讲中提出了一些关于常用的数据结构如何使用智能指针自动的构造和析构来避免内存泄漏的情况发生。
可以在这里找到这个演讲的链接：[https://youtu.be/JfmTagWcqoE](https://youtu.be/JfmTagWcqoE)。

## 智能指针
### `unique_ptr`
1. 唯一所有权
2. 离开作用域时，会同时析构指向的对象

### `shared_ptr`
1. 共享所有权
2. 最后一个指向对象的 `shared_ptr` 被销毁时，析构指向的对象

### `weak_ptr`
1. 不表示所有权
2. 使用之前需要先创建一个 `shared_ptr`（通过 `wp.lock()`，这个操作会延长指向对象的生命周期到这个临时的 `shared_ptr` 被销毁时）


## 所有权（Ownership）
在这里我借用了 [Rust](https://www.rust-lang.org/en-US/) 中的一个概念：所有权（Ownership），也就是表示一个对象持有（HAS-A）另一个对象，被持有的对象的生命周期应该和其父对象的生命周期相同。通常，在 C++ 中，我们都会使用数据成员（data member）的方式去表示这样的关系。

```c++
class MyClass {
  Data data;
  /*...*/
};
```
在这用的使用情况下，如果我们需要一个更灵活一些的方案，可是同时也要具有这种持有的关系，这时候可以选择 `unique_ptr`，即有了如下方案：（这种方案也可以被称作 *Decoupled HAS-A* ）

```c++
class MyClass {
  unique_ptr<Data> pdata;
  /*...*/
};
```

## 常见使用场景

### 指向实现的指针（Pimpl Idiom）
很多时候我们会有需要将一些实现抽象出来到一个单独的类中，来实现接口和实现分离。在这样的场景下，我们对 `pImpl` 是不会有改变的，在这样的情况下，使用 `const unique_ptr`：

```c++
template<class T>
using PImpl = const unique_ptr<T>;

class MyClass {
  class Impl;
  PImpl<Impl> pImpl;
  /*...*/
};
```

### 动态数组成员（Dynamic Array Member）
这里有两种方案，一种是使用 STL 里的 `vector`，另一种就是使用 `unique_ptr`。对于那些长度可能会变化的需求，我倾向于 `unique_ptr<vector>`；而对于长度偏固定的场景下，直接使用数组的指针我觉得会是一个较好的选择：
```c++
class MyClss {
  const unique_ptr<Data[]> array;
  int array_size;
  /*...*/
  MyClass (size_t num_data) :
    array(make_unique<Data[]>(num_data)) {}
}
```

### 树（Tree）
一个我们想象中常见的二叉树，在每个节点上保存了其子节点和要保存的数据。

![](http://7vijdo.com1.z0.glb.clouddn.com/image/autoupload/blog-tree-1.jpg)

在这样的结构里，我们可以发现父节点持有着它的两个子节点，而且每个子节点仅被其父节点持有，在这样的情况下，显然应该使用 `unique_ptr`。

```c++
class Tree {
  struct Node {
    vector<unique_ptr<Node>> children;
    /*...*/
  };
  unique_ptr<Node> root;
  /*...*/
};
```
那如果每个节点上还保存了其父节点的信息呢，显然我们不能再使用一个 `unique_ptr` 来保存父节点的指针，因为这样就和 `unique_ptr` 的意义冲突了，并且会导致内存泄漏的情况。所以这里，就直接使用 raw pointer 去表示一个节点的父节点就可以了。

如果我们在程序的其他地方，需要一些额外的指针来指向树中节点所保存的信息，看起来和下图差不多：

![](http://7vijdo.com1.z0.glb.clouddn.com/image/autoupload/blog-tree-2.jpg)

在这种情况下，每个节点的所有权就不是唯一的，不再是它的父节点，可能是外部可能的任何一个对象，在这种情况下，就需要把使用的 `unique_ptr` 变成 `shared_ptr`。在这个基础上，我们可以方便的对外提供任意节点保存信息的指针（也是一个 `shared_ptr`）。

```c++
class Tree {
  struct Node {
    vector<shared_ptr<Node>> children;
    Data data;
  };
  shared_ptr<Node> root;
  shared_ptr<Data> find(/*...*/) {
    /*...*/
    return {spn, &(spn->data)};
  }
};
```
代码的倒数第三行中使用了 `shared_ptr` 的 `aliasing constructor`，提供了指向的内容的指针和用于管理这个指针的另一个 `shared_ptr` 对象。

### 双向链表（Doubly Linked List）
在一个双向链表中，我们用两个指针去表示前节点和后节点，在这样的情况下，我们会出现和上面树中相似的问题，在这种情况下，我们依旧可以使用 `unique_ptr + raw pointer` 的解决方案。

```c++
class LinkedList {
  struct Node {
    unique_ptr<Node> next;
    Node* prev;
    /*... data ...*/
  };
  unique_ptr<Node> root;
  /*...*/
};
```

### 有向无环图（DAG）
一个 DAG 和一棵树的区别是：在树中一个节点只能是另一个节点的子节点；而在 DAG 中，一个节点可以是多个节点的后继节点。在这样的基础下，我们把每个节点的 `unique_ptr` 改成 `shared_ptr` 就可以工作了。

```c++
class DAG {
  struct Node {
    vector<shared_ptr<Node>> children;
    vector<Node*> parents;
  /*… data …*/
  };
  vector<shared_ptr<Node>> roots;
};
```

### 环形链表（Circular List）
在环形链表中，我们不可避免的要处理一个节点被多个对象拥有的情况。但是，仔细考虑一下，这样的冲突只会发生在链表的头部，因为它会同时被最后一个节点和表示链表的头指针持有，那在这种情况下，我们可以选择断开最后一个节点和头节点的关系，即按照一个非环的单项链表存储，然后在最后一个节点的部分对其做特殊处理。
```c++
class CircularList {
  class Node {
    unique_ptr<Node> next;
    unique_ptr<Node>& head;
  public:
    auto get_next() { return next ? next.get(): head.get(); }
  };
  unique_ptr<Node> head;
};
```

---------
**Reference**

1. http://en.cppreference.com/w/cpp/memory/unique_ptr
2. http://en.cppreference.com/w/cpp/memory/shared_ptr
3. http://en.cppreference.com/w/cpp/memory/weak_ptr