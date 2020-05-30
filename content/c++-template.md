+++
date = 2015-12-09
slug = "cpp-template"
title = "C++ Template"

[taxonomies]
tags = [ "c++", "template" ]
categories = ["Post"]
+++

# 函数模板

## 使用模板

模板被编译了两次，分别发生在：

1. 实例化之前，先检查模板代码本身，查看语法是否正确。
2. 在实例化旗舰，检查模板代码，查看是否所有的调用都有效。

## 模板的推导

在模板推导的过程中，不会进行自动的类型转换，每个类型都必须正确的匹配。

```c++
template<typename T>
inline T const& max (T const& a, T const& b);

max(4, 7); // OK: 两个实参的烈性都是int
max(4, 4.2); // ERROR: 第二个实参的类型是double，这里没有把第一个int自动升级成了double
```
有三种方法来处理：

1. 对实参进行强制类型转换，使它们可以相互匹配。`max(static_cast<double>(4), 4.2);`
2. 显示制定T的类型。`max<double>(4, 4.2);`
3. 制定两个参数可以有不同的类型。

## 模板参数

在函数模板内部，不能制定缺省的模板实参。

## 重载函数模板

函数的所有重载版本的声明都应该位于该函数被调用的位置之前。

# 类模板

## 类模板的特化

如果要特化一个类模板，还要特化该类模板的所有成员函数。虽然也可以只特化某个成员函数，但这个做法并没有特化整个类，也就没有特化整个类模板。

## 局部特化

```c++
template<typename T>
class MyClass<T, T>;

template<typename T>
class MyClass<T, int>;

template<typename T1, typename T2>
class MyClass<T1*, T2*>;
```

有多个局部特化同等程度的匹配某个声明的时候，那么该声明具有二义性：
```c++
MyClass<int, int> m;
// MyClass<T, T>, MyClass<T, int>
MyClass<int*, int*> m;
// MyClass<T, T>, MyClass<T1*, T2*>
```
为了解决第二种二义性，可以提供一个指向相同类型指针的特化：
```c++
template<typename T>
class MyClass<T*, T*>;
```

## 缺省模板实参

像指定一个函数的缺省实参一样。

# 非类型模板参数

对于函数模板和类模板，模板参数并不局限于类型，普通纸也可以作为模板参数。

## 非类型模板参数的限制

非类型模板参数可以是常整数（包括枚举值），或者指向外部链接对象的指针。

**浮点数和类对象** 是不允许作为非类型模板参数的。

# 技巧性基础知识

## 关键字 `typename`

当某个依赖于模板参数的名称是一个类型时，就应该使用 `typename`。

### `.template` 构造

```c++
template <int N>
void printBitset (std::bitset<N> const& bs) {
    std::cout << bs.template to_string<char, char_traits<char>, allocator<char> >();
}
```

用 `template` 去修饰后面的 `to_string` 的显式实例化模板版本的 `<` ，不是数学上的小于号，而是模板实参列表的起始符号。

## 使用 `this->`
对于具有基类的类模板，自身使用名称 `x` 并不一定等于 `this->x`。即使该 `x` 是从基类继承获得的。

> 对于那些在基类中声明，并且依赖于模板参数的符号（函数或者变量等），你应该在他们前面使用`this->`或者`Base<T>::`。如果希望完全避免不确定性，你可以限定所有的成员的访问。

## 成员模板

```c++
template<typename T>
class Stack {
    ...
    template <typename T2>
    Stack<T>& operator = (Stack<T2> const&);
}
```

> 对于类模板而言，只有被调用的函数才会被实例化。

## 模板的模板参数

```c++
template<typename T, template <typename ELEM> class CONT = std::deque>
class Stack;
```
* 在上面那段代码中第一行的 `class` 是不能和 `typename` 互换的，因为这里是为了定义一个类，而不是表示一个类型。
* 没有用到上面的 `ELEM` 参数，所以可以省略不写。
* **函数模板不支持模板的模板参数。**
* **模板的模板实参**必须精确的匹配。匹配时并不会考虑“模板的模板实参”的缺省模板实参。

### 模板的实参匹配

```c++
template<typename T,
            template <typename ELEM,
                        typename ALLOC = std::allocator<ELEM> > class CONT = std::deque>
class Stack;
```

## 零初始化

希望对所有的对象都用缺省构造函数初始化。
```c++
template <typename T>
void foo() {
    T x = T();
}
```
对于类模板，需要把所有数据成员的缺省构造函数在这个类的缺省构造函数中调用。

## 字符串作为函数模板的实参

由于长度的区别，有些字符串属于不同的数据类型。`apple` 和 `peach`，具有相同的类型 `char const[6]`，然而 `tomato` 的类型是 `char const[7]`。如果使用的是引用类型的话，在实例化模板的时候，就会出现类型不同的问题。
```c++
template <typename T>
inline T const& max (T const& a, T const& b) {
    return a < b ? b : a;
}

::max("apple", "peach"); // ok
::max("apple", "tomato");
```

但是在这里使用非引用类型的参数，就是可以的。因为如果使用非引用类型的参数，在这里会进行一个数组到指针类型的转换（这个转型过程通常被叫做decay）。

字符数组和字符串指针不匹配的问题，根据不同的情况，可以：
* 使用非引用参数，取代引用参数。**（可能会导致无用的拷贝。）**
* 进行重载。编写接受引用和非引用参数的两个版本。**（可能导致二义性）**
* 对具体类型进行重载。
* 重载数组类型。比如：
```c++
template <typename T, int N, int M>
T const * max (T const (&a)[N], T const (&b)[M]) {
    return a < b ? b : a;
}
```
* 强制要求应用使用显式的类型转换。