+++
title = "Link Cut Tree"
date = 2015-09-01
slug = "link-cut-tree-learning"
[taxonomies]
categories =  ["Tech"]
tags = [
  "acm",
  "data structure",
]
+++

<div class="article_content" id="article_contents_inner_4362677851" dir="ltr">
						<p>动态树（Dynamic Tree Problems）是一类要动态维护森林连通性问题的总称。一般要维护森林中某个点到根结点的某些数据，应该支持一棵树切割成两棵树，或者两棵树合并成一棵树的操作。而解决这一类问题的基础数据结构就是LCT。</p>

<p>整体维护的过程有点类似于树链剖分的维护过程，不过树链剖分里维护的重链由于是静态的，可以用线段树去维护。对于动态的，我们可以用splay来维护。</p>

<!-- more -->

<h2>Structure  </h2>

<p>我们用操作<code>access(x)</code>来表示访问节点x。那么定义：</p>

<ul><li><strong>Preferred Child</strong>：对于一个节点P，如果最后被访问的节点x在以其子节点Q为根的子树中，那么就称Q为P的<em>Preferred Child</em>。</li>
<li><strong>Preferred Edge</strong>：每个点到自己的Preferred Child之间的边，叫做<em>Preferred Edge</em>。</li>
<li><strong>Preferred Path</strong>：由Preferred Edge组成的一条不可延伸的路径，叫做<em>Preferred Path</em>。</li>
</ul><p>这样我们发现，每个点仅会属于一个preferred path。这样，一棵树就可以由几个preferred path来表示。对于每个preferred path，我们都维护一个splay，维护和的key值，就是每个点在preferred path中的深度。我们把这个splay称作：<em>Auxiliary Tree</em>（辅助树？这名字好难听……）。每个辅助树的根节点都保存着和上一个辅助树的哪一个点是相连的，这个指向被称作：path-parent pointer。</p>

<h2>Operations  </h2>

<h3>access</h3>

<p>当我们访问了节点<em>v</em>之后，它将没有preferred child，并且应该是一条preferred path的最后一个节点（at the end of the path）。在我们的辅助树中节点都是按照深度排序的，也就是说，这时候所有在点<em>v</em>右侧的点都是应该被断开的。这个操作在splay上是很容易的。我们只要对<em>v</em>做一次splay操作，把它转到根节点上，然后断开它的右子树，然后右子树的根的path-parent pointer指向<em>v</em>就可以了。 <br>
然后我们继续向上遍历直到这条path的根，调整需要调整的部分。我们只要跟着path-parent pointer走就可以了，因为<em>v</em>节点现在是根了。这一定是有序的。如果我们发现当前点不是根的话，我们会顺着path-parent pointer走到另一条path上的一个点<em>w</em>上。接下来，我们对<em>w</em>进行一次splay，然后断掉它的右子树，维护这个右子树的path-parent pointer。然后把<em>v</em>放在<em>w</em>右子树的位置上。（这里相当于把两个splay合并起来了。可以合并的原因是因为所有在<em>v</em>所在的辅助树里的点的深度都应该比<em>w</em>大。因为一直的有序可以保证这一点。）对<em>v</em>再做一次splay。重复这个过程，直到我们走到了根上。</p>

<p>PS：这里都用<code>child[x][0]</code>来表示x的左子树，<code>child[x][1]</code>来表示x的右子树。  </p>

<pre style="max-width: 1241px; overflow: auto;"><code>int access(int x) {
    int y = 0;
    do {
        splay(x);
        root[child[x][1]] = true;
        root[child[x][1] = y] = false;
        pushUp(x);
        x = father[y = x];
    } while(x);
    return y;
}
</code></pre>

<h3>FindRoot</h3>

<p><em>FindRoot</em>操作用来寻找点<em>v</em>在所在树的根节点。这个操作很简单，我们只要对<em>v</em>做一次access操作，这样<em>v</em>和它的根就应该在一个splay中了。那么此时的根就应该是这个splay最左边的节点。</p>

<h3>Cut</h3>

<p>断掉<em>v</em>和其父亲节点之间的边。首先access节点<em>v</em>。然后讲<em>v</em>旋转到所在辅助树的根节点上。断掉左子树。维护好path-parent pointer就可以了。</p>

<pre style="max-width: 1241px; overflow: auto;"><code>void cut(int v) {
    access(v);
    splay(v);
    father[child[v][0]] = 0;
    root[child[v][0]] = true;
    child[v][0] = 0;
}
</code></pre>

<p>PS：如果要断掉两个点之间的边呢？会比这个麻烦一点。  </p>

<pre style="max-width: 1241px; overflow: auto;"><code>void cut(int u, int v) {
    access(u);
    splay(u);
    reserse(u);
    access(v);
    splay(v);
    father[child[v][0]] = father[v];
    father[v] = 0;
    root[child[v][0]] = true;
    child[v][0] = 0;
}
</code></pre>

<h3>Link</h3>

<p>如果<em>v</em>是一个树的根，而<em>w</em>是另一个树里的点的话。只要让<em>w</em>成为<em>v</em>的父亲。我们可以同时对<em>w</em>和<em>v</em>都做一次access操作。让<em>w</em>成为<em>v</em>的左子树。</p>

<pre style="max-width: 1241px; overflow: auto;"><code>void link(int u, int v) {
    access(u);
    splay(u);
    reverse(child[u][0]);
    access(v);
    splay(v);
    child[v][1] = u;
    father[u] = v;
    root[u] = false;
}
</code></pre>

<p>这是一个例题。（我才不会说我是看到这道题才来学的LCT呢…） <br><a href="http://www.lydsy.com:808/JudgeOnline/problem.php?id=3669" target="_blank" class="underlink bluelink" tabindex="-1">传送门：NOI2014 魔法森林</a></p>