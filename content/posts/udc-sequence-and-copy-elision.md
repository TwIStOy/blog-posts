+++
title = "User-defined conversion and Copy elision"
date = 2019-04-19
slug = "user-defined-conversion-and-copy-elision"
[taxonomies]
categories =  ["Post"]
tags = [
  "c++",
  "c++11",
  "c++17",
  "standard",
]
+++


# 问题的开始

问题的开始是同事聊到了我们笔试题的一个问题，是说下面这个代码其实在编译的时候是有问题的。

```cpp
struct UserInfo {
  UserInfo(const std::string& name) : name_(name) {}

 private:
  std::string name_;
};

int main() {
  UserInfo u = "name";
}
```

# 最初的讨论和思考

显然在最开始的时候，我并没有发现这个代码的问题所在，并且被告知了在这段代码里面其实是有两个问题的。

在这个简单的例子里面，就涉及到了在规范里面两个很不容易注意到的行为，就像标题里聊的 `UDC(user-defined conversion)` 和 `copy-elision`。

## 关于隐式转换（implicit conversion）

在 `main` 函数里面唯一的语句，这首先是一个变量的声明和定义，同时还包括了这个变量的初始化（initialize）。在这个变量的初始化阶段，发生了几次类型转换，其中大部分都是隐式的（`implicit conversion`），并且调用到了不同的构造函数：

```
const char[5] =[implicit conversion(1)]=> std::string
              =[implicit conversion(2)]=> UserInfo
              =[copy/move(3)]=> UserInfo
```

第一次发生在字符串字面量（string literal）构造 `std::string` 的时候，显然这是一个隐式转换，因为并没有显式的调用 `std::string` 的构造函数，并且这个隐式转换显然是 `user-defined` 的。

第二次发生在 `std::string` 构造一个 `UserInfo` 的时候，这也是一个隐式转换，并且是 `user-defined` 的。

这两次隐式转换构成了一个隐式转换链（`implicit-conversion sequence`），问题就出在这个由两个 `user-defined conversion` 构成的隐式转换链上。在标准的 `16.3.3.1` 里讨论了有关于 `implicit conversion` 和 `user-defined conversion` 的部分，而在 `15.3` 里特别提到了：

  > At most one user-defined conversion (constructor or conversion functions) is implicitly applied to a single value.

在一个隐式转换序列里，只能存在最多一个用户定义的转换。这个条件在标准的隐藏的很深，我在通读标准的时候几次都错过了他们。（但是据说这个问题，曾经在邮件列表里有过蛮激烈的讨论的，但是可惜我那个时候还是个孩子hhh）

所以在这个问题里，发生 ill-formed 的第一个原因是，在一个 implicit conversion sequence 里面，存在多个 user-defined conversion。

## 关于复制消除（copy elision）

关于复制消除的部分，这里就要提到不同的两个版本，C++17 开始和 C++17 之前。

在 C++17 之前，并没有明确的提出在什么情况下，可以彻底进行复制消除（这里的彻底的指的是包括不进行是否有可用的 copy/move 构造函数的检查）。

所以在 C++17 之前，下面的这段代码是会有编译错误的：

```cpp
struct Foo {
  Foo(int) {}
  Foo(Foo&&) = delete;
  Foo(const Foo&) = delete;
};

int main() {
  Foo a = 1;
}
```

可以考虑上面给出的上面那个问题的隐式转换链，这个首先出现的是 source type 的 target type 的不一致，所以出现了一次 user-defined 的 implicit conversion。从类型 `int` 得到了类型 `Foo` 的一个 `prvalue`（这里的 `prvalue` 很重要）。然后才是从一个 `prvalue` 构造一个类型 `Foo` 的对象。

其实我们显然可以知道，第二个过程是会被优化掉的，一般的编译器都会优化成原地构造的。但是标准在这个时候要求了，在这种时候，即使这部分的内容会优化，但是依旧要进行编译时的检查，检查 copy/move 构造函数是否可用，如果不可用，那这个代码依旧是 ill-formed。

但是事情在 C++17 中发成了一个很大的改变 `11.6.4.3.9`，在一个是 prvalue 的时候，这里会用 direct-initalize，而不是尝试使用 copy/move initialize。也就是说，上面例子的代码在 C++17 之后其实是可以通过编译的。

但是这里要注意，适用的规则是一个 prvalue 的对象，xrvalue 是不可以的。也就是说，下面这样的代码依旧是不能通过编译的：

```cpp
struct Foo {
  Foo(int = 10) {}

  Foo(Foo&&) = delete;
  Foo(const Foo&) = delete;
};
struct Bar {
  operator Foo&& {
    return std::move(a);
  }
  
  Foo a;
};

int main() {
  Bar b;
  Foo a = b;
}
```

这里虽然做了一次隐式类型转换（从 `Bar` 到 `Foo`），但是得到的类型是一个 xrvalue，而 xrvalue 是不适合上面的拷贝消除规则的，所以还会尝试使用 copy/move 构造，得到 ill-formed 的结果。

----

文中提到的所有标准文档，都采用最新的 C++ 标准文档（ISO/IEC 14882 2017），除非特别指定此时讨论的C++版本。