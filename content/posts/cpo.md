+++
date = 2022-09-06
slug = "cpo"
title = "Customization Point Object"

[taxonomies]
categories =  ["Tech"]
tags = [ "c++", "c++20", "ranges", "cpo", "niebloid" ]
+++

# 解决什么问题？
标题是要聊一下 C++20 带来的一些新的很有意思的新机制，或者说是新轮子。
用来解决库函数或者一些通用函数定制用户类型的行为的抽象。
比如，我现在要实现一个通用的算法：
```
template<typename T>
void foo(T& vec);
```
我可能需要我的参数 `vec` 的类型 `T`。可以拿到他的两个对应迭代器和大小。（这里只是举个例子）
在这个时候，就是我的通用函数需要定制用户类型的行为。或者说，需要用户的类型提供我需要的能力。
对于这样的每一个对用户能力的要求，被称为一个 **定制点**。

<!-- more -->

# 现在都有哪些方案？

## 继承
第一个办法显然是继承嘛，考虑这个例子：
```c++
class ConnectionBase {
  void on_buffer_received(std::span<char> buffer) {
    if (handle_buffer(buffer)) {
      // ...
    }
  }

 protected:
  virtual bool handle_buffer(std::span<char> buffer) = 0;
};

class TlsConnection : public ConnectionBase {
 protected:
  bool handle_buffer(std::span<char> buffer) {
    // ssl...
  }
};
```
基类的纯虚函数 `ConnectionBase::handle_buffer(std::span<char> buffer)` 就是一个**定制点**。它在这里需要用户类型，也就是它的子类定义如何处理收到的 buffer 的行为。

## CRTP（Curiously Recurring Template Pattern）
还是考虑上面那个例子：
```c++
template<typename D>
class ConnectionBase {
  void on_buffer_received(std::span<char> buffer) {
    if (static_cast<D*>(this)->handle_buffer(buffer)) {
      // ...
    }
  }
};

class TlsConnection : public ConnectionBase<TlsConnection> {
  bool handle_buffer(std::span<char> buffer) {
    // ssl...
  }
};
```
这样基类可以直接访问子类的功能和实现，而且绕过了依赖虚表实现的多态调用有更好的性能。
缺点是在这样的情况下，**定制点**变的非常不明显，他可以不依靠任何的在基类中的声明来表达子类需要实现哪些**定制点**。

## ADL（Argument-Dependent Lookup）
依旧是上面那个例子：
```c++
namespace tls {
  class TlsConnection {};

  bool handle_buffer(TlsConnection* conn, std::span<char> buffer); // #1
}

namespace tcp {
  class TcpConnection {};

  bool handle_buffer(TcpConnection* conn, std::span<char> buffer); // #2
}

tls::TlsConnection* tls;
tcp::TcpConnection* tcp;

handle_buffer(tls);  // #1
handle_buffer(tcp);  // #2
```
在这种方案下，通过在对应参数的 `namespace` 来实现对应的定制功能，然后通过 `ADL` 来找到正确的实现。
在这样的方案下带来的一个问题就是，对于这个 `handle_buffer`，我们使用带 `namespace` 和不带 `namespace` 的版本可能会带来不一样的结果。

# 新的方案是什么样的？
在 C++20 里，其实 ranges 也面临了类似的问题，需要兼容各种类型的容器就要为每个类型的容器定制对应的功能。ranges 给出的方案就是 CPO，customization point object。

> A customization point object is a function object with a literal class type that interacts with program-defined types while enforcing semantic requirements on that interaction.

CPO 有很好的泛型的兼容性，而且也可以弥补上面 ADL 所提到的问题。
考虑一个取一个任意类型容器的 `begin iterator` 的问题：
```c++
namespace _Begin {
  class _Cpo {
    enum class _St { _None, _Array, _Member, _Non_member };

    template <class _Ty>
    static _CONSTEVAL _Choice_t<_St> _Choose() noexcept {
      if constexpr (is_array_v<remove_reference_t<_Ty>>) {
        return {_St::_Array, true};
      } else if constexpr (_Has_member<_Ty>) {
        return {_St::_Member, noexcept(_Fake_decay_copy(_STD declval<_Ty>().begin()))};
      } else if constexpr (_Has_ADL<_Ty>) {
        return {_St::_Non_member, noexcept(_Fake_decay_copy(begin(_STD declval<_Ty>())))};
      } else {
        return {_St::_None};
      }
    }

    template <class _Ty>
    static constexpr _Choice_t<_St> _Choice = _Choose<_Ty>();

   public:
     template <_Should_range_access _Ty>
       requires (_Choice<_Ty&>._Strategy != _St::_None)
      _NODISCARD constexpr auto operator()(_Ty&& _Val) const {
          constexpr _St _Strat = _Choice<_Ty&>._Strategy;
          if constexpr (_Strat == _St::_Array) {
            return _Val;
          } else if constexpr (_Strat == _St::_Member) {
            return _Val.begin();  // #1: via member function
          } else if constexpr (_Strat == _St::_Non_member) {
            return begin(_Val);   // #2: via ADL
          } else {
            static_assert(_Always_false<_Ty>, "Should be unreachable");
          }
        }
  };
}

inline namespace _Cpos {
  inline constexpr _Begin::_Cpo begin;
}
```
这个是 ranges 库里面的 `begin` 的实现，我只留下了为了说明问题的关键的部分。在这个实现里，用 `if constexpr` 处理了类型选择的大部分的逻辑。对于对一个容器类型求 `begin` 的操作被分成了三种情况，数组、成员函数、非成员函数。数组是 builtin 的类型就不聊了嘛；成员函数的调用类似上面的 CRTP 的用法，因为通过模板是明确拿到当前容器的类型的，可以直接调用对应自定义类型的成员；非成员函数的调用因为是直接用的 `begin` 这个名字，所以这里使用了上面的 ADL 的方式来找到对应容器自定义类型正确的处理函数。

为什么是一个 function object 而不是一个模板函数，是因为 function object 在这个情况下是不会被应用 ADL 的，也就是说不会被 ADL 找到的，避免了在 `#2` 那个地方的 ADL 递归调用的问题。

----
references:
1. [C++ Draft: customization point object](https://eel.is/c++draft/customization.point.object#def:customization_point_object)
2. [Cppreference: ranges](https://en.cppreference.com/w/cpp/ranges)
3. [Niebloids and Customization Point Objects](https://brevzin.github.io/c++/2020/12/19/cpo-niebloid/)
