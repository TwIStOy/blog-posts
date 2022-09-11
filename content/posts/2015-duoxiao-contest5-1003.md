+++
date = 2015-08-31
slug = "2015-duoxiao-contest5-1003"
title = "2015多校Contest 5. 1003. Hotaru's problem"

[taxonomies]
categories =  ["Tech"]
tags = [ "acm", "string" ]
+++

### 题目大意

一个N-sequence由三个部分组成，并符合：

1. 第一部分和第三部分相同。  
2. 第一部分和第二部分回文。

求最长的N-sequence的长度。

<!-- more -->

### 分析

N-sequence的特征是第一部分和第三部分相同，并且第一部分和第二部分回文。那么条件可以转化成：**第一部分**和**第二部分** _回文_，并且**第二部分**和**第三部分** _回文_。那么问题就转化成了：两个回文串的重合问题。

先用manacher求出任意一个位置作中心的最长回文串的长度。因为第一部分和第二部分组成的回文串`s1`一定是一个偶数长度的串，所以一定是我们添加的`#`位置。每个中间位置`i`可以覆盖左边的`i-rad[i]`到右边的`i+rad[i]`的范围。我们存下来能覆盖的最大右侧，这样我们在枚举每一个第二个端点的时候，去找到第一个端点。

在枚举到每个端点2的时候，我们可以算出来最大合法的端点1的位置，就是：`i-rad[i]`。那么我们就要找一个在合法范围内的最小的做端点。显然可以存下来当前所有右侧合法的端点，然后二分查找。然后就结束了。

### 代码

比赛的时候蠢在了好几个不一样的地方。真是…

```c++
#include <cstdio>
#include <cstring>
#include <vector>
#include <set>
#include <algorithm>
using namespace std;

const int maxn = 200100;
vector<int> a;
int rad[maxn];
vector<int> del[maxn];
set<int> fuck;

void manacher() {
    memset(rad, 0, sizeof(rad));
    int n = a.size();
    int i,j,k;
    i=0;
    j=1;
    while(i<n)
    {
        while(i-j>=0 && i+j<n && a[i-j]==a[i+j])
            j++;
        rad[i]=j-1;
        k=1;
        while(k<=rad[i] && rad[i]-k!=rad[i-k])
        {
            rad[i+k]=min(rad[i-k],rad[i]-k);
            k++;
        }
        i += k;
        j = max(j-k,0);
    }
}

int main() {
    int T;
    scanf("%d", &T);
    for (int cas = 1; cas <= T; cas++) {
        int n;
        scanf("%d", &n);
        a.clear();

        for (int i = 0; i < n; i++) {
            int x;
            scanf("%d", &x);
            a.push_back(-1);
            a.push_back(x);
        }
        a.push_back(-1);

        manacher();
    //    for (int i = 0; i < a.size(); i++) {
    //        printf("%2d ", i);
    //    }puts("");
    //    for (int i = 0; i < a.size(); i++) {
    //        printf("%2d ", a[i]);
    //    }puts("");
    //    for (int i = 0; i < a.size(); i++) {
    //        printf("%2d ", rad[i]);
    //    }puts("");
        int len = a.size();

        for (int i = 0; i < len; i++) {
            del[i].clear();
        }

        for (int i = 0; i < len; i++) {
            if (a[i] == -1) {
                if (i+rad[i] < len) {
                    del[i+rad[i]].push_back(i);
    //                printf("del %d at %d\n", i, i+rad[i]);
                }
            }
        }

        int ans = 0;
        fuck.clear();
        for (int i = 0; i < len; i++) {
            if (a[i] != -1) continue;

            set<int>::iterator iter = fuck.lower_bound(i-rad[i]);
            if (iter != fuck.end()) {
    //            printf("find %d at %d\n", *iter, i);
                ans = max(ans, (i-*iter) / 2);
            }

            fuck.insert(i);
            for (int j = 0; j < (int) del[i].size(); j++) {
                fuck.erase(del[i][j]);
            }
        }
        printf("Case #%d: %d\n", cas, ans * 3);
    }
    return 0;
}

/*
idx:  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
raw: -1  2 -1  3 -1  4 -1  4 -1  3 -1  2 -1  2 -1  3 -1  4 -1  4 -1
rad:  0  1  0  1  0  1  6  1  0  1  0  1  8  1  0  1  0  1  2  1  0
*/
```