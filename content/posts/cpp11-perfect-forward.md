+++
title = "c++11 完美转发+变长参数"
date = 2015-09-01
slug = "c++11-perfect-forward"
[taxonomies]
categories =  ["Tech"]
tags = [
  "c++",
  "c++11",
  "template",
  "tips",
]
+++

**完美转发**(argument forwarding):

> 给定一个函数`F(a1, a2, ..., an)`，要写一个函数G，接受和F相同的参数并传递给F。  
> 这里有三点要求：  
> 1\. 能用F的地方，G也一定能用。  
> 2\. 不能用F的敌方，G也一定不能用。  
> 3\. 转发的开销应该是线性增长的。

这里在C++11出现之前，人们做了很多尝试。就出现了很多的替代方案，直到C++11出现之后，才有了一个完美的解决方案。

### 非常量左值引用转发

```
    template<typename T>
    void g(T1& t) {
        return f(t);
    }
    
    void f(int t) {}
```
    

这里不能传入**非常量右值**（`g(1)`）。

### 常量左值引用

```
    template<typename T>
    void g(const T1& t) {
        return f(t);
    }
    
    void f(int& t) {}
```
    

常量左值引用在这里也挂掉了，这里函数_g_是没法把常量左值引用传递给非常量左值引用的。

### 非常量左值引用+常量左值引用

这种方案就是给每个参数写常量左值和非常量左值两个版本的，这个方案的重载函数个数是指数型增长的，在参数多的时候会挂掉的。而且，在传入非常量参数的时候，可能会引发二义性。

### 常量左值引用+const_cast

```
    template<class T>
    void g(const T& t) {
        return f(const_cast<T&>(t));
    }
```
    

这里看起来好像解决了方案2里的问题。可是这种转发变量被修改了，不是我们想要的结果。

### 非常量左值引用+修改的参数推导规则

```
    template<typename T>
    void f(T& t){
        std::cout << 1 << std::endl;
    }
    
    void f(const long &){
        std::cout << 2 << std::endl;
    }
    
    int main(){
        f(5);// prints 2 under the current rules, 1 after the change
        int const n(5);
        f(n);// 1 in both cases
    }
```
    

这里会对原有代码有破坏。

### 右值引用

```
    template<typename T>
    void g(T&& t) {
        return f(t);
    }
```
    

这里不能g不能接受一个左值，因为不能把一个左值传递给一个右值引用。

### 右值引用+修改的参数推导规则转发

引用叠加原则：

| TR的类型定义 | 声明v的类型 | v的实际类型 |
| --- | --- | --- |
| T&  | TR  | A&  |
| T&  | TR& | A&  |
| T&  | TR&& | A&  |
| T&& | TR  | A&& |
| T&& | TR& | A&  |
| T&& | TR&& | A&& |

这里如果只去修改对右值引用推导规则，这样就避免对原有的代码的破坏。

```
    template<typename T>
    void g(T&& t) {
        return f(std::forward<T>(t));
    }
```
    

这里已经可以处理好转发部分了。可是我还是不满意，我希望可以更完美一点，就是无论什么参数，多少参数都可以。这里要结合C++11的变长参数模板来完成。

```
    template<typename... Args>
    void g(Args... arg) {
        return f(std::forward(arg)...);
    }
```
    

这里包括了变长参数包的展开，这里还可以用`sizeof...(Args)`来获取变长参数的个数。

-----

参考：

1. [c++ - How would one call std::forward on all arguments in a variadic function? - Stack Overflow](http://stackoverflow.com/questions/6486432/variadic-template-templates-and-perfect-forwarding)  
2. [c++11 - Perfect forwarding - what's it all about? - Stack Overflow](http://stackoverflow.com/questions/6829241/perfect-forwarding-whats-it-all-about)  
3. [c++ - Variadic template templates and perfect forwarding - Stack Overflow](http://stackoverflow.com/questions/6486432/variadic-template-templates-and-perfect-forwarding)  
4. [The Forwarding Problem: Arguments](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2002/n1385.htm)  
5. [C++11维基百科](http://zh.wikipedia.org/wiki/C%2B%2B11#.E5.8F.B3.E5.80.BC.E5.BC.95.E7.94.A8.E5.92.8Cmove.E8.AA.9E.E6.84.8F)