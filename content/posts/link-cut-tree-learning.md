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

动态树（Dynamic Tree Problems）是一类要动态维护森林连通性问题的总称。一般要维护森林中某个点到根结点的某些数据，应该支持一棵树切割成两棵树，或者两棵树合并成一棵树的操作。而解决这一类问题的基础数据结构就是LCT。

整体维护的过程有点类似于树链剖分的维护过程，不过树链剖分里维护的重链由于是静态的，可以用线段树去维护。对于动态的，我们可以用splay来维护。

Structure
---------

我们用操作`access(x)`来表示访问节点x。那么定义：

* **Preferred Child**：对于一个节点P，如果最后被访问的节点x在以其子节点Q为根的子树中，那么就称Q为P的_Preferred Child_。
* **Preferred Edge**：每个点到自己的Preferred Child之间的边，叫做_Preferred Edge_。
* **Preferred Path**：由Preferred Edge组成的一条不可延伸的路径，叫做_Preferred Path_。

这样我们发现，每个点仅会属于一个preferred path。这样，一棵树就可以由几个preferred path来表示。对于每个preferred path，我们都维护一个splay，维护和的key值，就是每个点在preferred path中的深度。我们把这个splay称作：_Auxiliary Tree_（辅助树？这名字好难听……）。每个辅助树的根节点都保存着和上一个辅助树的哪一个点是相连的，这个指向被称作：path-parent pointer。

Operations
----------

### access

当我们访问了节点_v_之后，它将没有preferred child，并且应该是一条preferred path的最后一个节点（at the end of the path）。在我们的辅助树中节点都是按照深度排序的，也就是说，这时候所有在点_v_右侧的点都是应该被断开的。这个操作在splay上是很容易的。我们只要对_v_做一次splay操作，把它转到根节点上，然后断开它的右子树，然后右子树的根的path-parent pointer指向_v_就可以了。  
然后我们继续向上遍历直到这条path的根，调整需要调整的部分。我们只要跟着path-parent pointer走就可以了，因为_v_节点现在是根了。这一定是有序的。如果我们发现当前点不是根的话，我们会顺着path-parent pointer走到另一条path上的一个点_w_上。接下来，我们对_w_进行一次splay，然后断掉它的右子树，维护这个右子树的path-parent pointer。然后把_v_放在_w_右子树的位置上。（这里相当于把两个splay合并起来了。可以合并的原因是因为所有在_v_所在的辅助树里的点的深度都应该比_w_大。因为一直的有序可以保证这一点。）对_v_再做一次splay。重复这个过程，直到我们走到了根上。

PS：这里都用`child[x][0]`来表示x的左子树，`child[x][1]`来表示x的右子树。

```
    int access(int x) {
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
```
    

### FindRoot

_FindRoot_操作用来寻找点_v_在所在树的根节点。这个操作很简单，我们只要对_v_做一次access操作，这样_v_和它的根就应该在一个splay中了。那么此时的根就应该是这个splay最左边的节点。

### Cut

断掉_v_和其父亲节点之间的边。首先access节点_v_。然后讲_v_旋转到所在辅助树的根节点上。断掉左子树。维护好path-parent pointer就可以了。

```
    void cut(int v) {
        access(v);
        splay(v);
        father[child[v][0]] = 0;
        root[child[v][0]] = true;
        child[v][0] = 0;
    }
```
    

PS：如果要断掉两个点之间的边呢？会比这个麻烦一点。

```
    void cut(int u, int v) {
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
```
    

### Link

如果_v_是一个树的根，而_w_是另一个树里的点的话。只要让_w_成为_v_的父亲。我们可以同时对_w_和_v_都做一次access操作。让_w_成为_v_的左子树。

```
    void link(int u, int v) {
        access(u);
        splay(u);
        reverse(child[u][0]);
        access(v);
        splay(v);
        child[v][1] = u;
        father[u] = v;
        root[u] = false;
    }
```
    

这是一个例题。（我才不会说我是看到这道题才来学的LCT呢…）  
[传送门：NOI2014 魔法森林](http://www.lydsy.com:808/JudgeOnline/problem.php?id=3669)