+++
title = "模板实例化对成员函数的要求"
date = 2015-09-01
slug = "template-instantiation"
[taxonomies]
categories =  ["Post"]
tags = [
  "c++",
  "c++11",
  "template",
]
+++

<div class="article_content" id="article_contents_inner_4931453178" dir="ltr">
						<h1>问题的背景</h1>

<p>假如想写一个类模板C，能够实例化此模板的类型必须具有一个名为<code>Clone()</code>的<code>const</code>成员函数，此函数不带参数，返回值为指针，指向同类型的对象。 <br>
就像这样：</p>

<!-- more -->

<pre style="max-width: 1241px; overflow: auto;"><code>template&lt;typename T&gt;
class C
{
    // ...
};
</code></pre>

<h1>思考的过程</h1>

<p>我们可以在模板C中写一段代码，让它去调用函数<code>Clone()</code>，那么如果实例化的类型T没有这个函数的话，就不能通过编译。可是在模板类中只有被使用到的函数才会被实例化，所以我们只能去考虑一定会被实例化的函数。</p>

<ul><li>构造函数</li>
<li>析构函数</li>
</ul><p>我们首先就会考虑到这两个函数，然后再考虑一下，一个类可能有很多个构造函数，但是一定只会有一个析构函数，所以写在析构函数里会更划算一些。</p>

<p>首先就会写出这样的代码来：</p>

<pre style="max-width: 1241px; overflow: auto;"><code>template&lt;typename T&gt;
class C
{
pulibc:
    ~C()
    {
        // ...
        T t;
        t.Clone();
        // ...
    }
};
</code></pre>

<p>但是这样的实现会造成一定程度的浪费，因为不但构造了一个T的实体，还要调用T的默认构造函数，最后还要析构一次。 <br>
经过仔细的思考之后我们发现，其实我们并不需要真的去调用这个函数，只要对这样的函数提出一个要求就可以了。就会发现了下面这段更好的代码。</p>

<pre style="max-width: 1241px; overflow: auto;"><code>template&lt;typename T&gt;
class C
{
pulibc:
    ~C()
    {
        // ...

        T* (T::*test) () const = &amp;T::Clone;
        test;

        // ...
    }
};
</code></pre>

<p>在这里只是对这样的一个函数提出的一个需求的要求，并没有实例化这个类型。</p>

<p>这样做的好处同时还有，会有一个漂亮很多的很明显的报错。</p>