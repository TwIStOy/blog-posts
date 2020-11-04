+++
title = "c++11 完美转发+变长参数"
date = 2015-09-01
slug = "c++11-perfect-forward"
[taxonomies]
categories =  ["Post"]
tags = [
  "c++",
  "c++11",
  "template",
  "tips",
]
+++

<div class="article_content" id="article_contents_inner_4362677855" dir="ltr">
						<p><strong>完美转发</strong>(argument forwarding):</p>

<blockquote>
  <p>给定一个函数<code>F(a1, a2, ..., an)</code>，要写一个函数G，接受和F相同的参数并传递给F。 <br>
  这里有三点要求： <br>
  1. 能用F的地方，G也一定能用。 <br>
  2. 不能用F的敌方，G也一定不能用。 <br>
  3. 转发的开销应该是线性增长的。</p>
</blockquote>

<p>这里在C++11出现之前，人们做了很多尝试。就出现了很多的替代方案，直到C++11出现之后，才有了一个完美的解决方案。</p>

<h3>非常量左值引用转发</h3>

<pre style="max-width: 1241px; overflow: auto;"><code>template&lt;typename T&gt;
void g(T1&amp; t) {
    return f(t);
}

void f(int t) {}
</code></pre>

<p>这里不能传入<strong>非常量右值</strong>（<code>g(1)</code>）。</p>

<h3>常量左值引用</h3>

<pre style="max-width: 1241px; overflow: auto;"><code>template&lt;typename T&gt;
void g(const T1&amp; t) {
    return f(t);
}

void f(int&amp; t) {}
</code></pre>

<p>常量左值引用在这里也挂掉了，这里函数<em>g</em>是没法把常量左值引用传递给非常量左值引用的。</p>

<h3>非常量左值引用+常量左值引用</h3>

<p>这种方案就是给每个参数写常量左值和非常量左值两个版本的，这个方案的重载函数个数是指数型增长的，在参数多的时候会挂掉的。而且，在传入非常量参数的时候，可能会引发二义性。</p>

<h3>常量左值引用+const_cast</h3>

<pre style="max-width: 1241px; overflow: auto;"><code>template&lt;class T&gt;
void g(const T&amp; t) {
    return f(const_cast&lt;T&amp;&gt;(t));
}
</code></pre>

<p>这里看起来好像解决了方案2里的问题。可是这种转发变量被修改了，不是我们想要的结果。</p>

<h3>非常量左值引用+修改的参数推导规则</h3>

<pre style="max-width: 1241px; overflow: auto;"><code>template&lt;typename T&gt;
void f(T&amp; t){
    std::cout &lt;&lt; 1 &lt;&lt; std::endl;
}

void f(const long &amp;){
    std::cout &lt;&lt; 2 &lt;&lt; std::endl;
}

int main(){
    f(5);// prints 2 under the current rules, 1 after the change
    int const n(5);
    f(n);// 1 in both cases
}
</code></pre>

<p>这里会对原有代码有破坏。</p>

<h3>右值引用</h3>

<pre style="max-width: 1241px; overflow: auto;"><code>template&lt;typename T&gt;
void g(T&amp;&amp; t) {
    return f(t);
}
</code></pre>

<p>这里不能g不能接受一个左值，因为不能把一个左值传递给一个右值引用。</p>

<h3>右值引用+修改的参数推导规则转发</h3>

<p>引用叠加原则：</p>

<table><tbody><tr><th>TR的类型定义</th><th>声明v的类型</th><th>v的实际类型</th></tr><tr><th>T&amp;</th><th>TR</th><th>A&amp;</th></tr><tr><th>T&amp;</th><th>TR&amp;</th><th>A&amp;</th></tr><tr><th>T&amp;</th><th>TR&amp;&amp;</th><th>A&amp;</th></tr><tr><th>T&amp;&amp;</th><th>TR</th><th>A&amp;&amp;</th></tr><tr><th>T&amp;&amp;</th><th>TR&amp;</th><th>A&amp;</th></tr><tr><th>T&amp;&amp;</th><th>TR&amp;&amp;</th><th>A&amp;&amp;</th></tr></tbody></table><p>这里如果只去修改对右值引用推导规则，这样就避免对原有的代码的破坏。</p>

<pre style="max-width: 1241px; overflow: auto;"><code>template&lt;typename T&gt;
void g(T&amp;&amp; t) {
    return f(std::forward&lt;T&gt;(t));
}
</code></pre>

<p>这里已经可以处理好转发部分了。可是我还是不满意，我希望可以更完美一点，就是无论什么参数，多少参数都可以。这里要结合C++11的变长参数模板来完成。</p>

<pre style="max-width: 1241px; overflow: auto;"><code>template&lt;typename... Args&gt;
void g(Args... arg) {
    return f(std::forward(arg)...);
}
</code></pre>

<p>这里包括了变长参数包的展开，这里还可以用<code>sizeof...(Args)</code>来获取变长参数的个数。</p>

<hr><p>参考：</p>

<p>1.<a href="http://stackoverflow.com/questions/6486432/variadic-template-templates-and-perfect-forwarding" target="_blank" class="underlink bluelink" tabindex="-1">c++ - How would one call std::forward on all arguments in a variadic function? - Stack Overflow</a> <br>
2. <a href="http://stackoverflow.com/questions/6829241/perfect-forwarding-whats-it-all-about" target="_blank" class="underlink bluelink" tabindex="-1">c++11 - Perfect forwarding - what's it all about? - Stack Overflow</a> <br>
3. <a href="http://stackoverflow.com/questions/6486432/variadic-template-templates-and-perfect-forwarding" target="_blank" class="underlink bluelink" tabindex="-1">c++ - Variadic template templates and perfect forwarding - Stack Overflow</a> <br>
4. <a href="http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2002/n1385.htm" target="_blank" class="underlink bluelink" tabindex="-1">The Forwarding Problem: Arguments</a> <br>
5. <a href="http://zh.wikipedia.org/wiki/C%2B%2B11#.E5.8F.B3.E5.80.BC.E5.BC.95.E7.94.A8.E5.92.8Cmove.E8.AA.9E.E6.84.8F" target="_blank" class="underlink bluelink" tabindex="-1">C++11维基百科</a></p>