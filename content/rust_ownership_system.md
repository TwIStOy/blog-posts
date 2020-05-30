+++
slug = 'rust-ownership-system'
date = 2016-08-31
title = "Rust Ownership System"
[taxonomies]
categories = ["Post"]
tags = [
    "rust",
    "ownership system",
    "language",
]
+++


# Rust Ownership System

基于作用域和栈的内存管理是很符合直觉的，就像下面这样。
```rust
fn main() {
	let i = 5;
}
```
这里的变量 `i` 最后离开了作用域，然后内存被回收。

而在下面这个例子里，变量被析构了两次。
```rust
fn main() {
	let i = 5;
    foo(i);
}
fn foo(i: i64) {
	// do something...
}
```
第一次析构发生在 `foo` 结束的时候，第二次发生在 `main` 函数结束的时候。如果在 `foo` 中修改了这个变量的话，并不会影响到在 `main` 中的值。因为这里是的变量是被 **拷贝** 了一份，用于 `foo` 的。

在 Rust 中，使用了一套特别的基于 **Ownership** 的条件，除非一个类型被声明了具有`Copy`的特性。
## Copy Trait
声明一个类型具有 `Copy` 标记，会在赋值或者作为函数调用参数的时候，使用 **Copy** ，而非 **Move** 的方式。
```rust
#[derive(Copy, Clone)]
struct Info {
	value: i64,
}
```
## Ownership
Ownership rules 保证在任何的时间，对于一个非拷贝标记的对象，有且只有一个 `owner` 可以修改。

因此，当一个函数退出要清理变量的时候，可以保证在今后不会被访问，修改或者删除。

```rust
use std::io;
use std::fmt;

struct Fuck {
    shit: String,
}

impl Fuck {
    fn new (shit: &str) -> Fuck {
        println!("New... {}", shit);
        Fuck { shit: shit.to_string() }
    }
}

impl Drop for Fuck {
    fn drop(&mut self) {
        println!("Drop... {}", self.shit);
    }
}

impl fmt::Debug for Fuck {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "fuck shit:{:?}", self.shit)
    }
}

fn foo(fuck: Fuck) {
    println!("Call foo... {:?}", fuck);
}
```
对于一个简单的 `main` 函数：
```rust
fn main() {
	let mut a = Fuck::new("A");
}
```
结果是：
```
New... A
End Main...
Drop... A
```
对于这个复杂一点的版本：
```rust
fn main() {
    let mut a = Fuck::new("A");
    foo(a);
}
```
结果是：
```
New... A
Call foo... fuck shit:"A"
Drop... A
End Main...
```
会发现在函数 `foo` 结束的时候，对象就被回收了。这是因为这个对象的 `owner` 在函数调用这个过程中从 `main` 函数里的 `a` 变成了 `foo` 函数里的 `fuck`。

当尝试在调用一次 `foo` 之后再调用一次 `foo` 的话，就会报错。
```rust
fn main() {
    let mut a = Fuck::new("A");
    foo(a);
    foo(a);
    println!("End Main...");
}
```
```
src/main.rs:34:9: 34:10 error: use of moved value: `a` [E0382]
src/main.rs:34     foo(a);
                       ^
src/main.rs:33:9: 33:10 note: value moved here
src/main.rs:33     foo(a);
                       ^
```
通过这样的编译时期的检查，保证了同一时间只有一个变量拥有这个对象。

## Simple Rules
为了实现 *没有垃圾回收机制的内存安全*， 编译器不用去追踪每一个变量在代码中的使用，而是只要很简单的关注一个 **作用域** 就可以了。

其实可以总结成一个简单的规则：
- 不被使用的返回值会被销毁。
- 所有和变量绑定的对象在离开作用域的时候会被销毁，除非这个变量不再持有这个对象。

## Reference and Borrowing

上面说了，当一个变量作为函数调用的参数或者赋值操作的右值的时候，这个变量会失去这个对象的所有权。就像这样：
```rust
fn main() {
    let mut a = Fuck::new("A");
    foo(a);
    println!("HAHA... {}", a.shit);
    println!("End Main...");
}
```
```
src/main.rs:34:28: 34:34 error: use of moved value: `a.shit` [E0382]
src/main.rs:34     println!("HAHA... {}", a.shit);
                                          ^~~~~~
src/main.rs:33:9: 33:10 note: value moved here
src/main.rs:33     foo(a);
                       ^
```
如果希望拿回变量的所有权，我们可以把对象作为返回值传回来。就像这样：
```rust
fn foo(fuck: Fuck) -> Fuck {
    println!("Call foo... {:?}", fuck);
    fuck
}

fn main() {
    let mut a = Fuck::new("A");
    a = foo(a);
    println!("HAHA... {}", a.shit);
    println!("End Main...");
}
```
但是不能每次都这么做啊，所以就有了 `borrow` 和 `reference`。

一个`borrow`的变量绑定最大的区别就是，它只是暂时的获得对象的所有权，会在离开作用域或者更换绑定的时候归还。

规则：
- 一个引用的生命周期不能比它的拥有者还要长。
- 你可以有多个引用，但是必须满足：1. 可以有多个引用（`&T`，不可变）；2. 只能有一个可变的引用（`&mut T`）。

## Lifetime

每一个变量都有它自己的生命周期，而生命周期的不同是 `danging pointer` 发生的主要原因。当你仍然持有一个对象的引用，而这个对象的拥有者的生命周期结束了，那么这个引用就无效了。

所以，Rust 中不会允许这样的事情发生。Rust 通过整个所有权系统的 *生命周期*（lifetime） 这一概念来实现这个需求。它明确的指出了每一个引用有效的作用域。

当我们定义了一个形参为引用的函数，就涉及到了引用的生命周期。
```rust
fn foo(x: &i32) {
}
fn foo2<'a>(x: &'a i32) {
}
```
上面的例子中第一个写法省略了引用 `x` 的生命周期的声明，第二个例子是声明生命周期的显式写法。

这里的写法有点类似于 C++ 中的模板函数，需要先在函数名后面的 `<>` 中提到所用的生命周期，才能在后面的形参列表或者返回值中用到它。

生命周期并不会改变变量的类型，所以 `&i32` 和 `&'a i32` 拥有同样的类型。

同理，不光函数会涉及到生命周期，含有引用的结构体也会有生命周期的问题，显式声明的写法和函数类似。
```rust
struct Foo<'a> {
	x:&'a i32,
}
```

被省略了声明周期的函数会遵循着以下条件推导变量的生命周期：
- 每一个被省略的函数参数成为一个不同的生命周期参数；
- 如果刚好有一个生命周期，不管是否省略，这个生命周期都将成为被省略的返回值的生命周期；
- 如果有多个生命周期，并且没有 `&self` 或者 `&mut self` 的时候，省略返回值的生命周期是不允许的，如果有 `&self` 或者 `&mut self` 的话，被省略的返回值的生命周期将是 `self` 的生命周期。

## 总结
**Ownership**，**Borrow** 和 **Lifetime** 三个部分共同构成了 Rust 的 **Ownership System**。成为了它保证零运行成本的内存安全的关键。这也成为了 Rust 陡峭学习曲线的一个很重要的部分。慢慢熟悉起来之后，会越来越顺手的。