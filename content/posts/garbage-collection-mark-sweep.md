+++
date =  2016-08-27
title = "Garbage Collection: Mark-Sweep"
slug = "garbage-collection-mark-sweep"
[taxonomies]
categories =  ["Post"]
tags = [ 'reading', 'garbage collection', ]
+++

#### 1.2 Automatic dynamic memory management
原则上，回收器最终都会将所有不可达对象回收。

1. *追踪式回收* 引入 **垃圾** 这一具有明确判定标准的概念，但它不一定包含所有不再使用的对象。
2. 出于效率原因，某些对象可能不会被回收。

<!-- more -->

#### 1.3 Comparing garbage collection algorithms
用什么来衡量各种垃圾回收算法的好坏呢：

1. 安全性。在任何时候都不能回收活的对象。
2. 吞吐量。**标记 / 构造率（mark / cons ratio）**来衡量，它表示回收器（对存活对象进行标记）与赋值器（创建或者构造新的链表单元）活跃度的比值。
3. 完整性和及时性。完整性即所有的垃圾被回收的情况，及时性就是垃圾产生之后多久被回收。
4. 停顿时间。在进行垃圾回收的时候中断赋值器线程的时间。【最小赋值器使用率（MMU）和界限赋值器使用率（BMU）的概念，去衡量停顿时间的分布。】
5. 空间开销。
6. 针对结构的特别优化。
7. 可扩展性和可移植性。

#### 2.1 The mark-sweep algorithm
- 如果将标记位白存在对象中，那么`mark`方法处理的将是那些刚刚被标记的对象，因此这些对象可能还在缓存中。那么回收过程的高速缓存相关行文会影响到回收器的性能。
- 标记-清扫回收器要求堆布局满足一定的条件：
1. 标记-清扫回收器不会移动对象，因此内存管理器必须能够控制堆内存碎片，过多的内存碎片可能会导致分配器无法满足新分配请求，从而增加垃圾回收的频率，甚至于根本无法分配。
2. 清扫器必须能够遍历堆中的每一个对象，不管是否存在一定用于对齐的字节，`sweep`方法必能够准确的找到下一个对象。

<center>Mark-Sweep: Allocate</center>

```
New():
	ref <- allocate()
	if ref == null:
		collect()
		ref <- allocate()
		if ref == null:
			error "Out of memory."
	return ref
atomic collect():
	markFromRoots()
	sweep(HeapStart, HeapEnd)
```

<center>Mark-Sweep: Mark</center>

```
markFromRoots():
	initialise(work_list)
	for each fld in Roots:
		ref <- *fld
		if ref != null and not isMarked(ref):
			setMarked(ref)
			add(work_list, ref)
			mark()

initialise(work_list):
	work_list <- empty

mark():
	while not isEmpty(work_list):
		ref <- remove(work_list)
		for each fld in Pointers(ref):
			child <- *fld
			if child != null and not isMarked(child):
				setMarked(child)
				add(work_list, child)
```

<center>Mark-Sweep: Sweep</center>

```
sweep(start, end):
	scan <- start
	while scan < end:
		if isMarked(scan):
			unsetMarked(scan)
		else:
			free(scan)
		scan <- nextObject(scan)
```

#### 2.4 Bitmap marking
- 可以应用于保守式回收器（conservative collector）。
- 减少回收过程中的换页次数。

```
mark():
	cur <- nextInBitmap()
	while cur < HeapEnd:
		add(work_list, cur)
		markStep(cur)
		cur <- nextBitmap()

markStep(start):
	while not isEmpty(work_list):
		ref <- remove(work_list)
		for each fld in Pointers(ref):
			child <- *fld
			if child != null and not isMarked(child):
				setMarked(child)
				if child < start:
					add(work_list, child)
```

#### 2.5 Lazy sweeping
<ul>
<li>优化清扫阶段高速缓存行为的一种方案是使用对象预取。回收器可以按照固定步幅对大小相同的对象进行清扫。</li>
<li>对象及其标志位存在两个特征：
<ol>
<li>一旦某个对象成为垃圾，它将一直都是垃圾，不可能再被赋值器访问或者复活。</li>
<li>赋值器永远不会访问对象的标记位。</li>
</ol>
</li>
</ul>


<center>Block structure heep: lazy sweeping</center>

```
atomic collect():
	markFromRoots()
	for each block in Blocks:
		if not isMarked(block):
			add(blockAllocator, block)
		else:
			add(reclaimList, block)
atomic allocate(sz):
	result <- remove(sz)
	if result == null:
		lazySweep(sz)
		result <- remove(sz)
	return result

lazySweep(sz):
	repeat
		block <- nextBlock(reclainmList, sz)
		if block != null:
			sweep(start(block), end(block))
			if spaceFound(block):
				return
	until block == null
	allocSlow(sz)

allocSlow(sz):
	block <- allocateBlock()
	if block != null:
		initialise(block, sz)
```

#### 2.6 Cache misses in the marking loop

<center>mark procedure base on FIFO prefetch buffer</center>

```
add(work_list, item):
	markStack <- getStack(work_list)
	push(markStack, item)

remove(work_list):
	markStack <- getStack(work_list)
	addr <- pop(markStack)
	prefetch(addr)
	fifo <- getFifo(work_list)
	prepend(fifo, addr)
	return remove(fifo)
```
<center>Mark edge not node in object graph</center>

```
mark():
	while not isEmpty(work_list):
		obj <- remove(work_list)
		if not isMarked(obj):
			setMarked(obj)
			for each fld in Pointers(obj):
				child <- *fld
				if child != null:
					add(work_list, child)
```
