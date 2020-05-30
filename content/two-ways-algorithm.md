+++
title = "Two Ways Algorithm"
date = 2016-09-16
slug = "two-ways-algorithm"
[taxonomies]
categories = ["Post"]
tags = [
  "algorithm",
  "string",
]
+++

Two Ways Algorithm 是一个用于字符串匹配的算法，算法类似 KMP 会返回所有 pattern 出现在 text 里的位置。但是和 KMP 不同的是 two ways algorithm 只使用常数大小的额外空间。

算法使用 \\(O(m)\\) 的时间预处理，并且可以在 \\(O(n)\\) 时间完成匹配，在最差的情况下会遍历 text 串两次。

## 算法细节
模式串 \\(x\\) 被分成两个部分，\\(x\_l\\) 和 \\(x\_r\\)。在匹配的过程中先从左向右匹配 \\(x\_r\\)，如果没有失配再从右向左匹配 \\(x\_l\\)。

所以算法的关键就在于怎么找到一个合理的划分，把模式串划分成两个不相交的子串。

### 预处理部分
**定义**：*period of pattern \\(x\\)*，有整数 \\(p\\) 满足：\\[x[i]=x[i+p]\\]
换句话说，就是在模式串中任意两个相距为 *period* 的字符都相同。

所有满足上面条件的 \\(p\\) 中最小的一个，叫做这个串的 *period*，记做 \\(p(x)\\)。

**定义**：对于任意一个位置 \\(l\\)（这里指的是字母之间的位置，包括最开始和最后，所以一共有 \\(m+1\\) 个。）有整数 \\(r\\) 满足 \\[x[i]=x[i+r],l-r+1\\le i \\le l\\]
所有满足上面条件的 \\(r\\) 中最小的一个，叫做在位置 \\(l\\) 上的 *local period*，记做 \\(r(x,l)\\)。

这里显然可以知道的是，对于在所有位置上的 *local period* 都应该有：\\(1 \\le r(x,l) \\le |x|\\)

![](http://7vijdo.com1.z0.glb.clouddn.com/image/blog/two-ways-algorithm/fig1.png)

一个位置叫做 *critical position* 当且仅当 \\[r(x,l)=p(x)\\]

把这个串以这些 *critical position* 分开都是可以的。

### 匹配部分

。。。TODO。。