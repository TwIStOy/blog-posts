+++
title =  "编译时期计算数组"
date = 2015-09-01
slug = "compute-array-in-compile-time"
[taxonomies]
categories =  ["Post"]
tags = [
  "c++",
  "template",
  "tips",
  "c++11",
]
+++

<div class="article_content" id="article_contents_inner_5327597442" dir="ltr">
						<pre style="max-width: 1241px; overflow: auto;"><code>#include &lt;iostream&gt;
#include &lt;array&gt;
using namespace std;

constexpr int N = 1000000;
constexpr int f(int x) { return x*2; }

typedef array&lt;int, N&gt; A;

template&lt;int... i&gt; constexpr A fs() { return A{{ f(i)... }}; }

template&lt;int...&gt; struct S;

template&lt;int... i&gt; struct S&lt;0,i...&gt;
{ static constexpr A gs() { return fs&lt;0,i...&gt;(); } };

template&lt;int i, int... j&gt; struct S&lt;i,j...&gt;
{ static constexpr A gs() { return S&lt;i-1,i,j...&gt;::gs(); } };

constexpr auto X = S&lt;N-1&gt;::gs();

int main()
{
        cout &lt;&lt; X[3] &lt;&lt; endl;
}
</code></pre>

<p>在编译时期计算一个数组里面的元素，这种方法在\(N\)较大的时候会出现<code>constexpr</code>递归深度较大的问题。这种线性的求法似乎不能很好的处理当\(N\)较大的情况。所以这时候可以通过二分所求的\(N\)来解决这个问题。这样最大的递归深度就从\(N\)变成了\(logN\)了。
排名第一的回答中代码是这样写的：</p>

<pre style="max-width: 1241px; overflow: auto;"><code>template&lt;class T&gt; using Invoke = typename T::type;

template&lt;unsigned...&gt; struct seq{ using type = seq; };

template&lt;class S1, class S2&gt; struct concat;

template&lt;unsigned... I1, unsigned... I2&gt;
struct concat&lt;seq&lt;I1...&gt;, seq&lt;I2...&gt;&gt;
  : seq&lt;I1..., (sizeof...(I1)+I2)...&gt;{};

template&lt;class S1, class S2&gt;
using Concat = Invoke&lt;concat&lt;S1, S2&gt;&gt;;

template&lt;unsigned N&gt; struct gen_seq;
template&lt;unsigned N&gt; using GenSeq = Invoke&lt;gen_seq&lt;N&gt;&gt;;

template&lt;unsigned N&gt;
struct gen_seq : Concat&lt;GenSeq&lt;N/2&gt;, GenSeq&lt;N - N/2&gt;&gt;{};

template&lt;&gt; struct gen_seq&lt;0&gt; : seq&lt;&gt;{};
template&lt;&gt; struct gen_seq&lt;1&gt; : seq&lt;0&gt;{};

// example

template&lt;unsigned... Is&gt;
void f(seq&lt;Is...&gt;);

int main(){
  f(gen_seq&lt;6&gt;());
}
</code></pre>

<p>原文： <a href="http://stackoverflow.com/questions/13072359/c11-compile-time-array-with-logarithmic-evaluation-depth" target="_blank" class="underlink bluelink" tabindex="-1">http://stackoverflow.com/questions/13072359/c11-compile-time-array-with-logarithmic-evaluation-depth</a></p>
					<div style="clear:both;">
					</div>