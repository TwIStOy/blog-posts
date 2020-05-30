+++
title = "在C++17中的部分新特性"
date = 2018-02-25
slug = "changes-in-cpp-17"
[taxonomies]
categories = ["Post"]
tags = [
  "c++",
  "c++17",
  "constexpr",
  "template",
]
+++
C++17已经发布了有一些时候，并且很多的编译器已经完成了对C++17的支持，那对于C++17中的新特性，我也好奇的玩了一些，其中的几个新特性特别吸引我的注意。
# if-init
## Grammar
**if** **(** *init-statement* *condition* **)**
*init-statement* 可以是：
- 表达式语句（可以是空语句，仅`;`）
- 声明语句
## Thinking
if-init 这个 feature 尝试着让我们的代码更可读和干净，并且可以帮助我们更好的控制对象的生命周期。在从前的 `if` 语句中，我们经常会做类似的事情：
```c++
void foo(int a) {
    auto iter = a_map.find(a);
    if (iter != a_map.end()) {
        // do_something
    } else {
        // do_something_else
    }
    // do_something_next
}
```
这个叫做`iter`的变量其实我们除了用于这个`if`判断和语句块中的操作之外，我们可能再也不会用到它。它的生命周期其实无形的被延长到了整个函数的结束。就像我们在`for`语句中做的一样，我们为什么不把这个对象的生命周期限定在一个`if`语句块中呢？所以就有了 if-init 这个 feature。
```c++
void foo(int a) {
    if (auto iter = a_map.find(a); iter != a_map.end()) {
        // do_something
    } else {
        // do_something_else
    }
    // do_something_next
}
```
这里的写法就像在`for`语句中的那样自然，我们在一个`if`中初始化一个对象，并且使用它，当离开`if`语句的时候，这个对象就被销毁了。
一些更多的用法：
```c++
// with temporary read buffer
if (char buf[64]; std::fgets(buf, 64, stdin)) { m[0] += buf; }

// with lock
if (std::lock_guard<std::mutex> lock(mx); shared_flag) { unsafe_ping(); shared_flag = false; }

// with temporary input param
if (int s; int count = ReadBytesWithSignal(&s)) { publish(count); raise(s); }
```
# structured-bingds
## Grammar
*attr*(optional) *cv-auto* *ref-operator*(optional) **[** *indentifier-list* **] =** *expression* **;**
*attr*(optional) *cv-auto* *ref-operator*(optional) **[** *indentifier-list* **] {** *expression* **};**
*attr*(optional) *cv-auto* *ref-operator*(optional) **[** *indentifier-list* **] \(** *expression* **\);**
这里在绑定时候的基本规则是：（这里用 *Expression* 来表示 *expression* 表达式的类型）
1. 如果 *Expression* 是数组类型，则一次绑定到数组元素
2. 如果 *Expression* 是非联合体类型，且`std::tuple_size<Expression>`是完整类型，则使用类tuple绑定
3. 如果 *Expression* 是非联合体类型，且`std::tuple_size<Expression>`不是完整类型，则以此绑定到类的公开数据成员
### Case 1：Binding an array
每个 *indentifier-list* 中的标识符绑定到数组的每一个元素，标识符数量必须和数组大小一致。
```c++
int a[2] = {1,2};
 
auto [x,y] = a;
auto& [xr, yr] = a;
```
### Case 2: Binding a tuple-like type
`std::tuple_size<Expression>::value`必须是一个合法的编译时期常量，并且标识符的数量和`std::tuple_size<Expression>::value`的值相等。
在 *ref-operator* 为`&`或者`&&`时：
对于每一个标识符，若其对应的初始化表达式是左值，则为左值引用；若为右值则为右值引用。
每个标识符对应的初始化表达式使用如下规则：
- `expression.get<i>()`，表达式包含了一个如此的声明
- `get<i>(expression)`，仅按照 ADL[^ADL] 规则查找对应的声明（在这种使用中，如果 *expression* 对象是一个左值，那么传入的参数也为左值；如果 *expression* 对象是一个右值，那么传入的对象也为右值）
```c++
float x{};
char  y{};
int   z{};
 
const auto& [a,b,c] = std::tuple<float&,char&&,int>(x,std::move(y),z);
```
### Case 3: Binding to public data members
每个 *Expression* 的非静态公开成员变量都会被依次绑定，并且标识符个数要和非静态公开成员变量个数相等。
所以的非静态公开成员都应该是无歧义的，且不能有任何的匿名联合体成员。
标识符最后的类型的 CV限定符会合并其类成员变量的类型中的CV限定符和声明中的的CV限定符。
```c++
struct S {
    int x1 : 2;
    volatile double y1;
};
S f();
 
const auto [x, y] = f();
```
## Thinking
structured-binding 带给我们在书写上方便的同时也带来了相应的更大的心智负担，它让我们不仅要关注一个变量的类型，我们还要关注它所指向的对象的类型。因为在这里创建的不是一个引用，也不是对象的拷贝，而是一个既存对象的别名。
比如下面这个例子：
```c++
BarBar foo(Bar bar) {
    // do_something
    return bar.bar;
}
```
如果我们如此明显的书写的话，我们都知道，返回一个 sub-object 是不能触发 RVO[^RVO] 的。那么我们如果用了结构化绑定的方式之后呢？
```c++
BarBar foo(Bar bar) {
    auto [..., b, ...] = bar;
    // do_something
    return b;
}
```
很遗憾的是，这里依旧不能触发 RVO 的，因为这里的`b`是一个对象的别名，既不是引用也不是什么别的，它依旧会被认为是一个 sub-object。
# if-init with structured-bindings
将 if-init 和 structured-bindings 可以帮助我们在很多地方缩减我们的代码：
```c++
if (auto [iter, inserted] = m.insert({"foo", "bar"}); inserted) {
    // do_something
} else {
    // do_other_things
}
```
# if-constexpr
if-constexpr 可以帮助我们简化原本很多需要用 SFINAE 来实现的代码，用来模板中使用哪一部分的实现。
## Sample 1
### Before C++17
```c++
#include <type_traits>

template<typename T>
auto get_value_impl(T t, std::false_type) {
    return t;
}
template<typename T>
auto get_value_impl(T t, std::true_type) {
    return *t;
}
template<typename T>
auto get_value(T t) {
    return get_value_impl(t, std::is_pointer<T>());
}
```
### After C++17
```c++
template <typename T>
auto get_value(T t) {
    if constexpr (std::is_pointer_v<T>)
        return *t;
    else
        return t; 
}
```
## Sample 2
### Before C++17
```c++
template<int  N>
constexpr int fibonacci() {return fibonacci<N-1>() + fibonacci<N-2>(); }
template<>
constexpr int fibonacci<1>() { return 1; }
template<>
constexpr int fibonacci<0>() { return 0; }
```
### After C++17
```c++
template<int N>
constexpr int fibonacci()
{
    if constexpr (N>=2)
        return fibonacci<N-1>() + fibonacci<N-2>();
    else
        return N;
}
```
## Summary
if-constexpr 的出现我感觉不是为了解决什么特别的问题，而是为了简化我们的代码，让我们在写的时候可以更自然，更符合直觉。
# fold expression
## Grammar
**(** *pack* *op* **... )**
**( ...** *op* *pack* **)**
**(** *pack* *op* **...** *op* *init* **)**
**(** *init* *op* **...** *op* *pack* **)**
上面四个分别对应了一元右折叠、一元左折叠、二元右折叠、二元左折叠。
## Explain
上面的四种折叠，分别会被展开成：
```mathjax
\text{一元右折叠:} E_1 \  \text{op}\ (\dots\ \text{op}\ (E_{N-1}\ \text{op}\ E_N))\\
\text{一元左折叠:} ((E_1\ \text{op}\ E_2)\ \text{op}\ \dots)\ \text{op}\ E_N)\\
\text{二元右折叠:} E_1 \  \text{op}\ (\dots\ \text{op}\ (E_{N-1}\ \text{op}\ (E_N\ \text{op}\ I)))\\
\text{二元左折叠:} (((I\ \text{op}\ E_1)\ \text{op}\ E_2)\ \text{op}\ \dots)\ \text{op}\ E_N)
```
在使用二元折叠的时候，注意两个运算符必须是一样的，并且 *init* 如果是一个表达式的话，优先级必须低于 *op*，如果一定要高于的话，可以用括号括起来。

## Example
端序交换：
```c++
template<class T, std::size_t... N>
constexpr T bswap_impl(T i, std::index_sequence<N...>) {
  return (((i >> N*CHAR_BIT & std::uint8_t(-1)) << (sizeof(T)-1-N)*CHAR_BIT) | ...);
}
template<class T, class U = std::make_unsigned_t<T>>
constexpr U bswap(T i) {
  return bswap_impl<U>(i, std::make_index_sequence<sizeof(T)>{});
}
```

## Thinking
折叠表达式是在参数包的展开上面的又一次进步和改进，弥补了原本的参数包展开不易计算的问题。

# noexcept
noexcept 成为了类型系统的一部分，这也是C++17对以前代码的唯一影响，可能会导致以前的代码不能通过编译。
`void f();` 和 `void f() noexcept;` 不再被认为是同一个类型，所以可能要为从前的实现提供额外的模板，或者提供额外的重载，再或者可以在模板中使用C++17中的新特性指定模板类型推导（template type deduction guide）。
# template type deduction
为了实例化一个类模板，我们必须清楚的知道每个模板的类型，并且显示的写出他们，但是很多时候这是不必要的。
## Thinking
这个新特性看起来似乎并没有那么吸引我：在类成员定义的时候，我没法使用到这个特性，可是这是我使用模板类最多的地方；在其他的很多地方，我似乎又可以使用`auto`来替代写出一个变量的类型来。

- - - - -
**References:**
1. [http://en.cppreference.com/w/cpp/language/if](http://en.cppreference.com/w/cpp/language/if)
2. [http://en.cppreference.com/w/cpp/language/structured_binding](http://en.cppreference.com/w/cpp/language/structured_binding)
3. [http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/p0144r0.pdf](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/p0144r0.pdf)

[^ADL]: ADL: Argument-dependent lookup
[^RVO]: RVO: Return Value Optimization