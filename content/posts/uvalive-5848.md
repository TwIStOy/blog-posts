+++
date = 2015-08-31
slug = "uvalive-5848"
title = "UVALive 5848. Soju"

[taxonomies]
categories =  ["Tech"]
tags = [ "acm", "uvalive" ]
+++

# 题目大意

给定两个平面上的点集，求两个点集中距离最近的两个点的距离。（这里的距离说的是曼哈顿距离。）题目中保证了左边点集的点都一定在右侧的点集的左侧。也就是任意一个在左侧集合的点的横坐标都小于任意一个在右侧集合的点。

<!-- more -->

## 分析

题目中反复的提示了左侧的点一定在左侧。那么来分析曼哈顿距离的式子：
\[|x_1-x_2|+|y_1-x_2|\]
其中令\(x_1, y_1\)是处于左侧的点的话，其中的第一项一定是小于0的，可以去掉绝对值符号。那么我们如果令我们枚举的右侧点在左侧点的下面的话，右侧的绝对值就也可以去掉了。那么式子就可以变成如下的形式：
\[(y_1-x_1)-(y_2-x_2)\]那么这个时候只要维护后一项的值最大就好了。对于右侧点再上方的情况，类似处理。

## 代码

```c++
#include <bits/stdc++.h>
using namespace std;
const int maxn = 100100;
const int inf = INT_MAX;

struct point {
    int x, y;
    point() {}
    point(int x, int y) : x(x), y(y) {}
    void input() {
        scanf("%d%d", &x, &y);
    }
} a[maxn], b[maxn];

bool operator < (const point& a, const point& b) {
    return a.y < b.y;
}

int main() {
    int T;
    scanf("%d", &T);
    while (T--) {
        int n;
        scanf("%d", &n);
        for (int i = 0; i < n; i++) {
            a[i].input();
        }
        int m;
        scanf("%d", &m);
        for (int i = 0; i < m; i++) {
            b[i].input();
        }
        sort(a, a+n);
        sort(b, b+m);

        int ans = inf;

        for (int i = 0, j = 0, tmp = -inf; i < n; i++) {
            for (; j < m; j++) {
                if (a[i].y < b[j].y) {
                    break;
                }
                tmp = max(tmp, b[j].y - b[j].x);
            }
            ans = min(ans, a[i].y - a[i].x - tmp);
        }

        reverse(a, a+n);
        reverse(b, b+m);

        for (int i = 0, j = 0, tmp = inf; i < n; i++) {
            for (; j < m; j++) {
                if (a[i].y > b[j].y) {
                    break;
                }
                tmp = min(tmp, b[j].y + b[j].x);
            }
            ans = min(ans, tmp - a[i].x - a[i].y);
        }

        printf("%d\n", ans);
    }
    return 0;
}
```