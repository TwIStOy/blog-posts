+++
title = "一个关于 private member function detect 的 SFINAE 模板"
date = 2019-12-05
slug = "private-member-function-detect-template-with-sfinae"

[taxonomies]
categories =  ["Tech"]
tags = [ "c++", "sfinae" ]
+++


# 问题的开始
问题起源于，我要搞一个模板，来检查一个类，是不是有一个特定的回调接口 `OnAlarm()`。我显然希望在我的模板类里面，直接调用这个 `OnAlarm` 回调的。但是问题，就这么出现了。我需要一个模板，来检查一个传给构造函数的指针指向的类型，是不是有我需要的 `OnAlarm` 方法。如果没有的话，我需要使用另一套回调的机制。
问题就出在了这个检查上面。

<!-- more -->

# 问题的最初的样子
最开始的时候，我是写成了这个样子的。
```cpp
template <typename T, typename = void>
struct HasAlarmCallback : std::false_type {};

template <typename T>
struct HasAlarmCallback<T, decltype(std::declval<T>().OnAlarm())>
    : std::true_type {};
```
这样看起来是没问题的（其实也是没问题的），但是我遇到了第一个问题。
```c++
class B {
  void OnAlarm() {}
};
```
这个模板在 `T = B` 的时候，会有编译错误，并不能成功的使用 SFINAE。错误的内容大概就是，这里用了一个 private 的函数，然后是不可见的。

# 曙光
（虽然也不知道为什么）
```c++
template <typename T, typename = void>
struct HasAlarmCallback : std::false_type {};

template <typename T>
struct HasAlarmCallback<T, decltype(static_cast<T*>(nullptr)->OnAlarm())>
    : std::true_type {};

struct A {
  void OnAlarm(){};
};

class B {
  void OnAlarm(){};
};

int main() {
  HasAlarmCallback<A> a;
  HasAlarmCallback<B> b;
}
```
在我这样写的时候，代码是可以完美通过编译，并且可以完美运行的。结果也是完美符合预期的。那我就会想呀，为啥我直接像下面样子写就不对了呢～
```c++
std::cout << HasAlarmCallback<A>::value << std::endl;
std::cout << HasAlarmCallback<B>::value << std::endl;
```
！！！这是我百思不得其解的要点！！！
在我这么写的时候，就不 work，会报像最开始那样的编译问题。
# 最后的方案
```c++
template<typename T, typename = void>
struct _HasAlarmCallback {
  static constexpr bool value = false;
};

template<typename T>
struct _HasAlarmCallback<T, decltype(static_cast<T *>(nullptr)->OnAlarm())> {
  static constexpr bool value = true;
};

template<typename T>
struct HasAlarmCallback {
 private:
  static constexpr _HasAlarmCallback<T> foo{};

 public:
  static constexpr bool value = _HasAlarmCallback<T>::value;
};
```
我最后发现，如果需要我构造一个实例才能解决这个问题的话，那我就构造一个。
嗯… 虽然… 不知道为啥…
反正是 work 了…

如果有人看到，然后知道为什么的话… 请告诉我！谢谢了！






