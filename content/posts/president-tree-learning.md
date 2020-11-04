+++
title = "主席树"
date = 2015-08-31
[taxonomies]
categories =  ["Post"]
tags = [
    'acm',
    'data structure',
]
+++

<div class="article_content" id="article_contents_inner_5677460198" dir="ltr">
						<p>主席树我的理解是可持久化线段树的一种应用吧。本质上就是可持久化线段树，不过我们在查询的时候用到了他们之间可以相减的性质。</p>

<!-- more -->

<p>首先介绍一下可持久化线段树。</p>

<h3>可持久化线段树</h3>

<p>可持久化线段树是可持久化数据结构中的一种，主席树的实现就是利用了可持久化线段树的。</p>

<h4>可持久化数据结构</h4>

<p>所谓的可持久化数据结构，就是保存这个数据结构的历史版本，同时应该公用他们的公有部分来减少内存上的消耗。</p>

<h4>可持久化线段树</h4>

<p>在每次更新的时候，我们保存下来每次更新的历史版本，以便我们之后查阅。在主席树中我们用到的线段树是保存当前范围内位置有多少个数的。以下都用这个当例子。</p>

<p>下面图中点的表示：
</p><div class="pin_container" style="float:none"><div id="pc_291489" class="pin_chiclet pc_first" title="将图片保存到 Pinterest。 点按右键可以关闭此功能。"><span class="icon-service_pinterest-16x16"></span></div><img src="http://7vijdo.com1.z0.glb.clouddn.com/pt-node.svg" alt="" style="max-width: 1241px; height: auto; object-fit: contain;"></div><p></p>

<h5>建树</h5>

<p>建立一颗空树，这里只要递归的建立就可以了。和普通的线段树是一样的。<code>build(1, 5)</code>
</p><div class="pin_container" style="float:none"><div id="pc_221762" class="pin_chiclet pc_first" title="将图片保存到 Pinterest。 点按右键可以关闭此功能。"><span class="icon-service_pinterest-16x16"></span></div><img src="http://7vijdo.com1.z0.glb.clouddn.com/pt-1.svg" alt="" style="max-width: 1241px; height: auto; object-fit: contain;"></div><p></p>

<h5>更新</h5>

<p>我们这里的更新操作是不改变原有的点，对于所有的修改我们都会建立新的点出来。 <br><code>insert(root, 1, 5, 3)</code>：在3位置插入了一个值。
</p><div class="pin_container" style="float:none"><div id="pc_298247" class="pin_chiclet pc_first" title="将图片保存到 Pinterest。 点按右键可以关闭此功能。"><span class="icon-service_pinterest-16x16"></span></div><img src="http://7vijdo.com1.z0.glb.clouddn.com/pt-2.svg" alt="" style="max-width: 1241px; height: auto; object-fit: contain;"></div><code>insert(root, 1, 5, 4)</code>：在4位置插入了一个值。
<div class="pin_container" style="float:none"><div id="pc_342396" class="pin_chiclet pc_first" title="将图片保存到 Pinterest。 点按右键可以关闭此功能。"><span class="icon-service_pinterest-16x16"></span></div><img src="http://7vijdo.com1.z0.glb.clouddn.com/pt-3.svg" alt="" style="max-width: 1241px; height: auto; object-fit: contain;"></div><p></p>

<p>我们可以看到，在修改线段树上维护的数据的时候我们都没有改变原本的点，只是建立了一个新点出来。这样我们可以放心的复用以前的点（因为他们根本就没有变过），这样来达到节省空间的目的。</p>

<h5>查询</h5>

<p>查询的方法和普通的线段树一样，还是根据所查信息来决定是走左孩子还有右孩子就可以了。</p>

<h3>主席树</h3>

<p>主席树中我们处理任意区间第K大的方法，有点像在处理任意区间和的时候我们用的求好前缀和再相减的过程。这里我们在查询的时候就是把两个线段树相减。 <br>
如果查询区间(s, t)的第K大，我们首先可以找到他们两个所对应的数字插入的时候的线段树，（我们把数组里的元素按顺序插入，并且把插入后的根保存起来。因为这些根一定都是不同的，假定我们保存在了数组T中。即当前的查询可以表示为：<code>query(s, t, ln, rn, k)</code>） <br>
那么如果\(T[t].left.data - T[s-1].left.data &lt;= k\)，就证明了这个第K小的数应该在左边。我们递归的处理<code>
query(s.left, t.left, ln, mid, k)</code>，否则第K小的数就应该在右边，我们递归处理<code>query(s.right, t.right, mid+1, rn, k-(t.left.data-s.left.data))</code>（注意更新右侧不是第K小，应该减去左侧数字的个数。）</p>

<h4>代码实现和例题</h4>

<p>例题<a href="http://poj.org/problem?id=2104" target="_blank" class="underlink bluelink" tabindex="-1">poj2104</a>
代码：</p>

<pre style="max-width: 1241px; overflow: auto;"><code>#include &lt;iostream&gt;
#include &lt;cstdio&gt;
#include &lt;algorithm&gt;
#include &lt;vector&gt;
using namespace std;  
const int maxn = 1000100;

struct node {  
    node *ls, *rs;
    int data;
} _pool[maxn * 20], *current;


void init() {  
    current = _pool;
}

node* allocNode() {  
    return current++;
}

node* build(int ln, int rn) {  
    node* now = allocNode();
    now-&gt;data = 0;
    now-&gt;ls = NULL;
    now-&gt;rs = NULL;
    if (ln &lt; rn) {
        int mid = (ln + rn) / 2;
        now-&gt;ls = build(ln, mid);
        now-&gt;rs = build(mid + 1, rn);
    }
    return now;
}

node* insert(node* root, int ln, int rn, int val) {  
    node* now = allocNode();
    *now = *root;
    now-&gt;data++;
    if (ln != rn) {
        int mid = (ln + rn) / 2;
        if (val &lt;= mid) {
            now-&gt;ls= insert(now-&gt;ls, ln, mid, val);
        }
        else {
            now-&gt;rs= insert(now-&gt;rs, mid+1, rn, val);
        }
    }
    return now;
}

int query(node* s, node* t, int ln, int rn, int k) {  
    //printf("&gt;&gt;&gt; [%d, %d], (%d, %d), %d\n", s-_pool, t-_pool, ln, rn, k);
    //printf("--- &lt;%d, %d&gt;, &lt;%d, %d&gt;\n", s-&gt;ls-_pool, s-&gt;rs-_pool, t-&gt;ls-_pool, t-&gt;rs-_pool);
    if (ln == rn) return ln;
    int delta = t-&gt;ls-&gt;data - s-&gt;ls-&gt;data;
    int mid = (ln + rn) / 2;
    if (delta &gt;= k) {
        return query(s-&gt;ls, t-&gt;ls, ln, mid, k);
    }
    else {
        return query(s-&gt;rs, t-&gt;rs, mid+1, rn, k - delta);
    }
}

void treeShow(node* root) {  
    if (root != NULL) {
        printf("%d: &lt;(%d, %d), %d&gt;\n", root-_pool, root-&gt;ls-_pool, root-&gt;rs-_pool, root-&gt;data);
        treeShow(root-&gt;ls);
        treeShow(root-&gt;rs);
    }
}

node* T[maxn];  
int ori[maxn];  
int dis[maxn];  
int main() {  
    int n, q;
    while (scanf("%d%d", &amp;n, &amp;q) != EOF) {
        init();
        for (int i = 1; i &lt;= n; i++) {
            scanf("%d", &amp;ori[i]);
            dis[i] = ori[i];
        }
        sort(dis + 1, dis + n + 1);
        int m = unique(dis + 1, dis + 1 + n) - dis - 1;
        T[0] = build(1, m);

        for (int i = 1; i &lt;= n; i++) {
            int pos = lower_bound(dis + 1, dis + m + 1, ori[i]) - dis;
            T[i] = insert(T[i-1], 1, m, pos);
        }
        //treeShow(T[2]);

        for (int i = 0; i &lt; q; i++) {
            int s, t, k;
            scanf("%d%d%d", &amp;s, &amp;t, &amp;k);
            printf("%d\n", dis[query(T[s-1], T[t], 1, m, k)]);
        }
    }
    return 0;
}
</code></pre>