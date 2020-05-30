+++
title = "matplotlib基础"
date = 2016-08-16
slug = "matplotlib-basic"
[taxonomies]
categories = ["Post"]
tags = [
  "python",
  "module",
  "note",
]
+++

# Introduction
matplotlib是一个很好用的可以画2D图的Python模块。它提供了很方便进行可视化数据的方案。下面是对matplotlib的使用进行了一个简单的记录。

# Simple plot
```python
import numpy as np

X = np.linspace(-np.pi, np.pi, 256,endpoint=True)
C,S = np.cos(X), np.sin(X)
```
这里的`X`是一个数组，里面有256个数，范围是\\([-\pi,\pi]\\)。接下来的`C`和`S`是分别是cos值和sin值。

## 基础绘图
```python
import numpy as np
import matplotlib.pyplot as plt

X = np.linspace(-np.pi, np.pi, 256, endpoint=True)
C,S = np.cos(X), np.sin(X)

plt.plot(X,C)
plt.plot(X,S)

plt.show()
```
![](http://www.labri.fr/perso/nrougier/teaching/matplotlib/figures/exercice_1.png)

## 对图进行一些设置
```python
# Imports
import numpy as np
import matplotlib.pyplot as plt

# Create a new figure of size 8x6 points, using 100 dots per inch
plt.figure(figsize=(8,6), dpi=80)

# Create a new subplot from a grid of 1x1
plt.subplot(111)

X = np.linspace(-np.pi, np.pi, 256,endpoint=True)
C,S = np.cos(X), np.sin(X)

# Plot cosine using blue color with a continuous line of width 1 (pixels)
plt.plot(X, C, color="blue", linewidth=1.0, linestyle="-")

# Plot sine using green color with a continuous line of width 1 (pixels)
plt.plot(X, S, color="green", linewidth=1.0, linestyle="-")

# Set x limits
plt.xlim(-4.0,4.0)

# Set x ticks
plt.xticks(np.linspace(-4,4,9,endpoint=True))

# Set y limits
plt.ylim(-1.0,1.0)

# Set y ticks
plt.yticks(np.linspace(-1,1,5,endpoint=True))

# Save figure using 72 dots per inch
# savefig("../figures/exercice_2.png",dpi=72)

# Show result on screen
plt.show()
```
![](http://www.labri.fr/perso/nrougier/teaching/matplotlib/figures/exercice_2.png)
## 改变颜色和线的粗细
```python
plt.figure(figsize=(10,6), dpi=80)
plt.plot(X, C, color="blue", linewidth=2.5, linestyle="-")
plt.plot(X, S, color="red",  linewidth=2.5, linestyle="-")
```
![](http://www.labri.fr/perso/nrougier/teaching/matplotlib/figures/exercice_3.png)

## 设置X轴和Y轴的范围
```python
plt.xlim(X.min()*1.1, X.max()*1.1)
plt.ylim(C.min()*1.1, C.max()*1.1)
```
![](http://www.labri.fr/perso/nrougier/teaching/matplotlib/figures/exercice_4.png)
## 设置坐标轴的刻度
```python
plt.xticks( [-np.pi, -np.pi/2, 0, np.pi/2, np.pi])
plt.yticks([-1, 0, +1])
```
![](http://www.labri.fr/perso/nrougier/teaching/matplotlib/figures/exercice_5.png)

## 设置坐标轴刻度上的字
```python
plt.xticks([-np.pi, -np.pi/2, 0, np.pi/2, np.pi],[r'$-\pi$', r'$-\pi/2$', r'$0$', r'$+\pi/2$', r'$+\pi$'])

plt.yticks([-1, 0, +1],[r'$-1$', r'$0$', r'$+1$'])
```
![](http://www.labri.fr/perso/nrougier/teaching/matplotlib/figures/exercice_6.png)


## 移动坐标轴
```python
ax = plt.gca()
ax.spines['right'].set_color('none')
ax.spines['top'].set_color('none')
ax.xaxis.set_ticks_position('bottom')
ax.spines['bottom'].set_position(('data',0))
ax.yaxis.set_ticks_position('left')
ax.spines['left'].set_position(('data',0))
```
![](http://www.labri.fr/perso/nrougier/teaching/matplotlib/figures/exercice_7.png)


## 为图添加说明
```python
plt.plot(X, C, color="blue", linewidth=2.5, linestyle="-", label="cosine")
plt.plot(X, S, color="red",  linewidth=2.5, linestyle="-", label="sine")

plt.legend(loc='upper left', frameon=False)
```
![](http://www.labri.fr/perso/nrougier/teaching/matplotlib/figures/exercice_8.png)

## 添加注释
```python
t = 2*np.pi/3
plt.plot([t,t],[0,np.cos(t)], color ='blue', linewidth=1.5, linestyle="--")
plt.scatter([t,],[np.cos(t),], 50, color ='blue')

plt.annotate(r'$\sin(\frac{2\pi}{3})=\frac{\sqrt{3}}{2}$',
             xy=(t, np.sin(t)), xycoords='data',
             xytext=(+10, +30), textcoords='offset points', fontsize=16,
             arrowprops=dict(arrowstyle="->", connectionstyle="arc3,rad=.2"))

plt.plot([t,t],[0,np.sin(t)], color ='red', linewidth=1.5, linestyle="--")
plt.scatter([t,],[np.sin(t),], 50, color ='red')

plt.annotate(r'$\cos(\frac{2\pi}{3})=-\frac{1}{2}$',
             xy=(t, np.cos(t)), xycoords='data',
             xytext=(-90, -50), textcoords='offset points', fontsize=16,
             arrowprops=dict(arrowstyle="->", connectionstyle="arc3,rad=.2"))
```
![](http://www.labri.fr/perso/nrougier/teaching/matplotlib/figures/exercice_9.png)

# See also
[Numpy](http://www.labri.fr/perso/nrougier/teaching/numpy/numpy.html)
[100 Numpy exercises](http://www.labri.fr/perso/nrougier/teaching/numpy.100/index.html)
[Ten simple rules for better figures](http://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1003833)