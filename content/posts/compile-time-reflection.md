+++
title = "Compile Time Reflection in C++11"
date = 2018-04-15
slug = "compile-time-reflection"

[taxonomies]
categories =  ["Post"]
tags = [
  "c++",
  "c++11",
  "compile-time",
  "reflection",
  "macro",
  "template"
]
+++



# 故事背景
故事发生在遥远的我在使用C++来处理JSON和对象绑定的时候，我厌倦了写这样的代码:

<!-- more -->

```c++
class Foo {
  int bar1;
  int bar2;
  int bar3;
  std::string bar4;
  int bar5;
  std::string ToJsonString();
};
std::string Foo::ToJsonString() {
  Document doc;
  doc.SetObject();
  doc.AddMember("bar1", Value(bar1), doc.GetAllocator());
  doc.AddMember("bar2", Value(bar2), doc.GetAllocator());
  doc.AddMember("bar3", Value(bar3), doc.GetAllocator());
  doc.AddMember("bar4", Value(bar4), doc.GetAllocator());
  doc.AddMember("bar5", Value(bar5), doc.GetAllocator());
  ...
}
```
这样的代码又复杂又容易出错，所以我就在考虑一种可以自动的将这些东西都完成好的绑定方法。所以就有了文章写的内容。

# 预备部分
## 模板类
我们需要一个可以在编译时期被构造的字符串类，用于保存我们需要反射的类的类名和成员名。在C++17之后，我们可以使用标准库中提供的`std::string_view`来实现，但是在C++11中，我们没有这样的实现，就只能用`constexpr`的构造函数来实现一个我们自己的`std::string_view`类。
这部分在C++11中的实现可以参考我在另一篇文章中的实现。[https://twistoy.com/post/compile-time-const-array](https://twistoy.com/post/compile-time-const-array)
这里给出一个简单的实现：
```c++
class ConstString {
 public:
  template<uint32_t N>
  constexpr ConstString(const char (&arr)[N]) : begin_(arr), size_(N-1) {
    static_assert(N >= 1, "const string literal should not be empty");
  }

  constexpr ConstString(const char* buf, uint32_t len)
    : begin_(buf), size_(len) {}

  constexpr char operator[](uint32_t i) const {
    return begin_[RequiresInRange(i, size_)];
  }

  constexpr const char* Begin() const {
    return begin_;
  }

  constexpr const char* End() const {
    return begin_ + size_;
  }

  constexpr uint32_t Size() const {
    return size_;
  }

  constexpr ConstString SubString(int pos, int len) const {
    return RequiresInRange(pos, size_), RequiresInRange(pos + len, size_),
           ConstString(begin_ + pos, len);
  }

 private:
  const char* const begin_;
  uint32_t size_;
};

constexpr bool operator==(ConstString a, ConstString b) {
  return a.Size() != b.Size() ? false
       : StringEqual(a.Begin(), b.Begin(), a.Size());
}
```
这个实现提供了在字符串上的几个基本操作，后面的实现中可以根据自己的需要扩展。
## 宏（macro）
### 宏参数个数
我们都知道，在C++11中提供了变长参数模板，可以让我们接受任意个任意类型的参数：
```c++
template<typename... Args>
void fuck(Args... args);
```
还有技巧可以帮助我们写出类型处理正确的、零开销的完美转发；有扩展的用法`sizeof...(Args)`来帮助我们获得参数包中参数的个数。
但是，如果我们想得到一个宏的变长参数包中参数的个数呢？有什么宏展开的技巧可以帮助我们做到这一点呢。答案显然是有的，我们用两个宏来配合我们做到这一点：
```c++
#define __RSEQ_N() 5, 4, 3, 2, 1, 0
#define __ARG_N(_1, _2, _3, _4, _5, N, ...) N
```
上面的宏考虑其展开的过程：
```c++
__ARG_N(a, b, c, __RSEQ_N())  // 1：调用 
__ARG_N(a, b, c, 5, 4, 3, 2, 1, 0)  // 2：展开1
```
考虑展开后的形式：
```c++
   __ARG_N( a,  b,  c,  5,  4, 3, 2, 1, 0)
// __ARG_N(_1, _2, _3, _4, _5, N, ...) N
```
我们可以明显的得到`__ARG_N`这个宏在这种情况下展开的结果为`3`。我们再对这个宏进行简单的包装，就得到了一个易用的获得宏参数个数的宏。
```c++
#define __GET_ARG_COUNT_INNER(...) __ARG_N(__VA_ARGS__)
#define __GET_ARG_COUNT(...) __GET_ARG_COUNT_INNER(__VA_ARGS__, __RSEQ_N())
```
对这个宏进行一些简单的测试：
```c++
assert(__GET_ARG_COUNT(a,), 1);
assert(__GET_ARG_COUNT(a, b), 2);
assert(__GET_ARG_COUNT(a, b, c), 3);
assert(__GET_ARG_COUNT(a, b, c, d), 4);
assert(__GET_ARG_COUNT(a, b, c, d, e), 5);
```
通过扩展宏`__RSEQ_N()`和宏`__ARG_N`来扩展其所支持的参数个数。简单的增加宏里的参数个数和数值即可。
### 构造字符串序列
我们都知道，在宏里面可以通过使用`#`来将一个宏参数用引号来括起来，形成字符串的形式。那么利用这个特性，我们就可以得到一个参数的字符串形式和我们上面完成的常量字符串对象。
```c++
#define __ADD_VIEW(str) ConstString(#str)
```
并且通过宏的递归来实现生成一个常量字符串对象的序列：
```c++
#define __CONST_STR_1(str, ...) __ADD_VIEW(str)
#define __CONST_STR_2(str, ...) __ADD_VIEW(str), __CONST_STR_1(__VA_ARGS__)
#define __CONST_STR_3(str, ...) __ADD_VIEW(str), __CONST_STR_2(__VA_ARGS__)
...
```
以此类推可以得到你想要的个数的形式。【如果你在使用VIM的话，这里的代码可以简单的使用VIM的宏功能来完成。（使用q来录制一个宏，C-A来自增当前位置的数字）。VIM最棒啦。我就是这么完成的UoU】
上面的宏，将被展开成这样：
```c++
// __CONST_STR_3(a, b, c)
ConstString("a"), ConstString("b"), ConstString("c")
```

## 将参数序列转成字符串序列
先搞一个简单的宏把两个名字连起来成为一个名字：
```c++
#define __MACRO_CONCAT(m1, m2) __MACRO_CONCAT_IMPL(m1, m2)
#define __MACRO_CONCAT_IMPL(m1, m2) m1##_##m2
```
然后结合我们上面完成的两个宏，就可以啦：
```c++
#define __MAKE_STR_LIST(...) __MACRO_CONCAT(__CONST_STR, __GET_ARG_COUNT(__VA_ARGS__))(__VA_ARGS)
```
将`__CONST_STR`这个名字和参数个数连起来，就是其在我们上面实现的第二个宏的名字，比如：`__CONST_STR_1`、`__CONST_STR_2`等等。然后再调用这个宏即可。

## 将一个操作写入所有的宏参数
在这里使用类似字符串转换那里的技巧，可以很容易的得到一个宏：
```c++
#define __MAKE_ARG_LIST_1(op, arg, ...) op(arg)
#define __MAKE_ARG_LIST_2(op, arg, ...) op(arg), __MAKE_ARG_LIST_1(op, __VA_ARGS__)
...
```
上面的宏被使用时，将这样被展开：
```c++
#define __FIELD(t) t
// __MAKE_ARG_LIST_3(&Name::__FIELD, a, b, c)
&Name::a, &Name::b, &Name::c
```

# 使用一个类来保存这些宏信息
在这里我希望构造一个类似这样的结构体来保存一个类的成员的宏信息：
```c++
struct Name {
  char* rname;
};

struct __reflect_struct_Name {
  using size_type = std::integral_constant<size_t, 1>;
  constexpr static ConstString Name() {
    return ConstString("Name");
  }
  constexpr static size_t Value() {
    return size_type::value;
  }
  constexpr static std::array<ConstString, size_type::value> MembersName() {
    return std::array<ConstString, 1>{{ ConstString("rname") }};
  }
  constexpr decltype(std::make_tuple(&Name::rname)) static MembersPointer() {
    return std::make_tuple(&Name::rname);
  }
};
```
观察我们上面的几个宏，可以显然得到这样的一种写法：
```c++
#define __MAKE_REFLECT_CLASS(StructName, ...) \
  struct __reflect_struct_##StructName { \
    using size_type = std::integral_constant<size_t, __GET_ARG_COUNT(__VA_ARGS__)>; \
    constexpr static ConstString Name() { \
      return ConstString(#StructName); \
    } \
    constexpr static size_t Value() { \
      return size_type::value; \
    } \
    constexpr static std::array<ConstString, size_type::value> MembersName() { \
      return std::array<ConstString, size_type::value>{{ \
        __MACRO_CONCAT(__CONST_STR, __GET_ARG_COUNT(__VA_ARGS__))(__VA_ARGS__) \
      }}; \
    } \
    constexpr static decltype(std::make_tuple()) static MembersPointer() {
      return std::make_tuple( \
        __MACRO_CONCAT(__MAKE_ARG_LIST, &StructName::__FIELD, __VA_ARGS__) \
      ); \
    } \
  };
```
上面的这个宏可以帮助我们构造一个结构体，在结构体里的分别用`Name()`方法来返回其保存的元信息类型名，用`MembersName()`返回保存类型的所有成员名，用`MembersPointer()`返回保存类型的所有成员指针。
然后利用函数的重载来返回这个结构体:
```c++
__reflect_struct_##StructName __reflect_structs(StructName const&) { \
  return __reflect_struct##StructName{}; \
}
```
# 使用模板函数来获取这些元信息
```c++
template<typename T>
constexpr const ConstString GetName() {
  return decltype(__reflect_structs(std::declval<T>()))::Name();
}

template<typename T>
constexpr const ConstString GetName(size_t i) {
  return decltype(__reflect_structs(std::declval<T>)))::MembersName()[i];
}
```
后面的思想基本就都和这个类似，利用模板和函数重载来获取这些类型的元信息。

# 结合其他宏使用
在使用这种操作的时候，我们需要使用一个宏来构造我们上面提到的所有元信息，这个应该是一个没有办法的事情了。为了这个功能这些多出来的代码，我也是可以接受的。
当然如果这个类型本来就是使用宏构造出来的话，就可以把这两个宏很舒服的结合在一起啦~所以我也推荐你这么用哦。