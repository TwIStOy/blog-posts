+++
title = "编译时期常量数组及常用操作"
date = 2018-01-07
slug = "compile-time-const-array"

[taxonomies]
categories = ["Post"]
tags = [
  "c++",
  "c++11",
  "compile time",
  "string"
]
+++

文中所有的代码均遵循C++11的标准并编译通过。

## `const_array` 的实现
在 C++11 标准中的使用`constexpr`修饰的函数的要求比较严格，只允许在函数体内有一个`return`语句。那么在这样的限制下，很多的表达式就只能使用递归来完成。
```c++
#include <iostream>
#include <cstddef>

template<typename T>
using Invoke = typename T::type;

template<size_t...>
struct index_sequence {
  using type = index_sequence;
};

template<typename S1, typename S2>
struct _concat_sequence;
template<size_t... I1, size_t... I2>
struct _concat_sequence<index_sequence<I1...>, index_sequence<I2...>>
    : index_sequence<I1..., (sizeof...(I1) + I2)...> {};
template<typename S1, typename S2>
using concat_sequence = Invoke<_concat_sequence<S1, S2>>;

template<size_t Length>
struct _make_index_sequence;
template<size_t Length>
using make_index_sequence = Invoke<_make_index_sequence<Length>>;
template<size_t Length>
struct _make_index_sequence
    : concat_sequence<make_index_sequence<Length/2>, make_index_sequence<Length - Length / 2>> {};
template<>
struct _make_index_sequence<0> : index_sequence<> {};
template<>
struct _make_index_sequence<1> : index_sequence<0> {};
template<size_t offset, typename S>
struct _make_offset;
template<size_t offset, size_t... I>
struct _make_offset<offset, index_sequence<I...>> : index_sequence<(I + offset)...> {};
template<size_t offset, typename S>
using make_offset = Invoke<_make_offset<offset, S>>;

template<typename ValueType, size_t Size>
class const_array {
  ValueType data_[Size];
  template<size_t SZ1, size_t SZ2>
  constexpr const_array(const_array<ValueType, SZ1> first, ValueType second, const_array<ValueType, SZ2> third)
      : const_array(first, second, third, make_index_sequence<SZ1>(), make_index_sequence<SZ2>()) {}
  template<size_t... I1, size_t... I2>
  constexpr const_array(const_array<ValueType, sizeof...(I1)> first, ValueType second, const_array<ValueType, sizeof...(I2)> third, index_sequence<I1...>, index_sequence<I2...>)
      : data_{ first[I1]..., second, third[I2]... } {}
  template<size_t... I>
  constexpr const_array(const_array<ValueType, Size - 1> arr, ValueType value, index_sequence<I...>)
      : data_{ arr[I]..., value } {}
  constexpr const_array(const_array<ValueType, Size - 1> arr, ValueType value)
      : const_array(arr, value, make_index_sequence<Size - 1>()) {}
  template<size_t L1, size_t L2, size_t... I1, size_t... I2>
  constexpr const_array(const_array<ValueType, L1> arr1,
                        const_array<ValueType, L2> arr2,
                        index_sequence<I1...>,
                        index_sequence<I2...>)
      : data_{ arr1[I1]..., arr2[I2]... } {};
  template<size_t... I>
  constexpr const_array(ValueType (&arr)[Size], index_sequence<I...>)
      : data_{ arr[I]... } {}

  friend class const_array<ValueType, Size - 1>;
public:
  // construct const_array from only one element
  constexpr explicit const_array(ValueType value) : data_{ value } {}
  constexpr explicit const_array(ValueType (&arr)[Size])
      : const_array(arr, make_index_sequence<Size>()) {}

  template<size_t length, size_t... I>
  constexpr const_array(const_array<ValueType, length> rhs, index_sequence<I...>)
      : data_{ rhs[I]... } {}
  template<size_t L1, size_t L2>
  constexpr const_array(const_array<ValueType, L1> arr1, const_array<ValueType, L2> arr2)
      : const_array(arr1, arr2, make_index_sequence<L1>(), make_index_sequence<L2>()) {};

  template<size_t length, size_t st = 0>
  constexpr const_array<ValueType, length> sub_array() const {
    return const_array<ValueType, length>(*this, make_offset<st, make_index_sequence<length>>());
  }

  template<size_t i>
  constexpr const_array<ValueType, Size> set(ValueType value) const {
    return const_array<ValueType, Size>(
        sub_array<i>(), value, sub_array<Size - i - 1, i + 1>()
    );
  }
  template<size_t length>
  constexpr const_array<ValueType, Size + length> append(const_array<ValueType, length> rhs) const {
    return const_array<ValueType, Size + length>(*this, rhs);
  };

  constexpr const_array<ValueType, Size + 1> append(ValueType value) const {
    return const_array<ValueType, Size + 1>(*this, value);
  }
  constexpr ValueType operator[] (size_t i) const {
    return data_[i];
  }
  constexpr size_t size() const {
    return Size;
  }
};
```
在实现的过程中，借助了一个部分实现类。使用二分递归的方式实现了一个用于生成制定长度的数列的辅助类，避免了当 `N` 过大的时候递归过深的问题。

```c++
template<typename T>
using Invoke = typename T::type;

template<size_t...>
struct index_sequence {
  using type = index_sequence;
};

template<typename S1, typename S2>
struct _concat_sequence;
template<size_t... I1, size_t... I2>
struct _concat_sequence<index_sequence<I1...>, index_sequence<I2...>>
    : index_sequence<I1..., (sizeof...(I1) + I2)...> {};
template<typename S1, typename S2>
using concat_sequence = Invoke<_concat_sequence<S1, S2>>;

template<size_t Length>
struct _make_index_sequence;
template<size_t Length>
using make_index_sequence = Invoke<_make_index_sequence<Length>>;
template<size_t Length>
struct _make_index_sequence
    : concat_sequence<make_index_sequence<Length/2>, make_index_sequence<Length - Length / 2>> {};
template<>
struct _make_index_sequence<0> : index_sequence<> {};
template<>
struct _make_index_sequence<1> : index_sequence<0> {};
template<size_t offset, typename S>
struct _make_offset;
template<size_t offset, size_t... I>
struct _make_offset<offset, index_sequence<I...>> : index_sequence<(I + offset)...> {};
template<size_t offset, typename S>
using make_offset = Invoke<_make_offset<offset, S>>;
```
接下来就是借助上面的辅助类，来生成对应的数组下标帮助完成 `const_array` 的拷贝。我们并不能修改一个编译时期常量的类，所以这里有关于修改的操作都是通过返回一个新的对象来完成的，比如 `append` 和 `set`。