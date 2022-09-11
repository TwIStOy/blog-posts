+++
title = "C++ 中的类型推导"
date = 2017-02-09
slug = "cpp11-type-derivation"
[taxonomies]
categories =  ["Tech"]
tags = [
  "c++",
  "range-base-for",
  "auto",
  "decltype",
]
+++

# auto 的基本使用

`auto` 关键字被在变量声明或者作为函数返回值的占位符，在这两个位置的使用是可以通过单个等号右边，或者函数调用来确定 `auto` 具体应该成为什么类型的，比如像下面这样：

```c++
auto iter = map.begin();
template<typename T, typename U>
auto func(T a, U b) -> decltype(a + b);
```

<!-- more -->

在 C++14 中，后面的 `decltype` 部分也可以被省略，可以通过返回的表达式来直接推导，比如这样：

```c++
template<typename T, typename U>
auto func(T a, U b) {
  return a + b;
}
```

## for-range loop
还可以被用于在 for-range loop 中使用，作为循环变量类型的占位。

### for-range loop 的展开

```c++
{
  auto&& __range = range_expression;
  for (auto __begin = begin_expr, __end = end_expr; __begin != __end; ++__begin) {
    range_declaration = *__begin;
    loop_statement;
  }
}
```

展开中的 `begin_expr` 和 `end_expr` 都分别用 `std::begin(you_container)` 和 `std::end(you_container)` 来得到其实和终止的迭代器。
在这两个函数的内部会分别调用 `begin()` 和 `end()` 的成员函数来确定边界，边界应该是左闭右开的。

所以如果想要通过 for-range loop 来遍历自定义的数据结构的话，需要为这个数据结构提供 `begin()` 和 `end()` 两个成员函数，并且提供一个迭代器类型，
迭代器类型需要可以拷贝，并且重载了 `!=` 、前置 `++` 运算符和解引用（`*`）运算符。


### auto 占位符的使用
```
for (auto x: m) {
  ...
}
```

这个占位符有四种写法：
```
for (auto x: m);
for (auto& x: m);
for (const auto& x: m);
for (auto&& x: m);
```

#### `for (auto x: m)`
这种写法情况，被遍历的每一个元素都会被拷贝一次，也就是说在 `for` 的代码块中使用的是被遍历元素的一个拷贝。
所以这里就有一个情况是不能使用的，就是如果被遍历元素的类型不能拷贝，那么就不能用，比如 `std::unique_ptr`。

#### `for (auto& x: m)`
这样的写法大部分情况是没有问题的，元素不会被拷贝，而且可以在遍历的时候被修改。那么唯一会出问题的情况就是被遍历的对象是 `vector<bool>` 的时候。
`vector<bool>` 是 `vector<T>` 的一个特化，使用了位去存储元素，所以在遍历的时候返回的是一个 bit reference 对象，这个对象是不能被非 const 的
左值引用中。所以在这种情况下，是不能用这种遍历方法的。

#### `for (const auto& x: m)`
const 的左值引用作为在 C++ 中的万能类型，可以接受这个类型的任何对象，除了元素不能修改之外，可以在大部分情况中使用。作为引用，也不会引起额外的拷贝开销。

### `for (auto&& x: m)`
`auto&&` 可以被称为 Universal References，这里不是指它能兼容所有的引用类型，而是会因为引用折叠的原因可以根据 `auto` 推导出来的类型对实际类型做出改变。
所以如果在这里使用这种写法的话，就可以接受任意类型，并且可以修改其中的元素。


# `auto` 和 `decltype` 的推导

## `auto` 的推导
不包含引用的推导：
```c++
auto a = 1; // auto -> int, a -> int
auto b = new auto(2); // auto int*, a -> int*
```
包含指针的推导：
```c++
int a = 1;
auto *b = &a; // auto -> int, b -> int*
auto c = &a; // auto - int*, c -> int*
```
包含引用的推导：
```c++
int a = 1;
auto& d = a; // auto -> int, d -> int&
auto e = a; // auto -> int, e -> int

// CV 限定会在 auto 的推导中被丢弃
const auto f = a; // auto -> int, f -> const int
auto g = f; // auto -> int, g -> int

// 如果 auto 被引用修饰，那么表达式的 CV 限定将会被保留
auto const &h = a; // auto -> int, h -> int const&
auto &i = h; // auto -> const int, i -> cosnt int&
auto *j = &h; // auto -> const int, j -> const int*
```

## `decltype` 的推导
```c++
const std::vector<int> v;
auto a = v[0]；// a -> int
decltype（v[0]) b = 0; // b -> const int&

int c = 0;
decltype(c) d; // d -> int
decltype((c)) e; // e -> int&
```
大概就是 decltype 会反映里面表达式的类型，不会去掉对应的CV限定符。

---------------

- https://zh.wikipedia.org/wiki/C%2B%2B11#.E5.9E.8B.E5.88.A5.E6.8E.A8.E5.B0.8E
- https://isocpp.org/blog/2012/11/universal-references-in-c11-scott-meyers