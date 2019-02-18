---
title: 基数估计算法(Flajolet-Martin算法)
date: 2019-02-18 16:59:37
tags: algorithm
---

**简介**

说起基数估计算法的始祖，或许就是由Flajolet和Martin大佬发表的论文《  [**Probabilistic counting algorithms for data base applications**](https://www.sciencedirect.com/science/article/pii/0022000085900418)》开始的吧。他们提出在大数据中基于概率来估计基数的算法，江湖人称 FM-sketch算法。

# **基础版**

首先定义一个hash函数：

* $function \ hash(x): ->[0,1,2,...,2^L−1]$该函数能将元素均匀地映射到该区间内。

再定义bit函数：$bit(y, k) ​$表示 y的二进制表示第k个bit数值（0或1）.

即

$y=∑_\limits{k≥0}bit(y,k)2^k​$.​

定义tail(y)表示y的二进制表示中末尾出现第一个1的位置(从0开始计数)，即连续0的个数：

$tail(y)=\begin{cases}minbit(y,k)≠0 &\text{if } y>0 \\ L &\text{if } y=0\end{cases}$

定义BITMAP[0…L-1]数组，BITMAP[i] 表示在可重复集合M中有一个数经过hash后呈现

$...1,0^i​$，即该hash值的二进制表示中末尾有连续i个0.

具体BITMAP的计算如下：

```
for i :=0 to L- 1 do BITMAP[i] :=0; 
	for all x in M do 
		begin
		index := tail(hash(x)); 
		if BITMAP[index] = 0 then BITMAP[index] := 1; 
		end;
```

好了定义了这么多，重点来了！

$BITMAP[i] =(i==tail(y) ,\exist y$)

如果M中的基数为n，按照概率，BITMAP[0]大约有$n/2$次会被访问到（想一下一半是奇数一半是偶数）,

同理BITMAP[1]大约有$n/2^2$次被访问到… 

因此BITMAP[i]大约有$n/2^i$次被访问到。

可以得出结论，当

* $i≫log_2n$ 时，BITMAP[i]几乎没被访问过，即BITMAP[i]几乎确定为0；
* 相反的，如果$i≪log_2⁡n$时，BITMAP[i]很大概率上为1。

**设BITMAP里最右边的1的位置为R**

> BITMAP左边代表低位，右边代表高位，因此我们可以用R来近似$log_2⁡n$。

比如一个24bits(L=24)的BITMAP如下：

111111111111001100000000

则左边的0出现的位置为14，即R=14.

**在确保hash值是均匀分布的条件下，R的数学期望值为：**

$E(R)≈log_2φn,φ=0.77351...$

可以证明R的方差为：σ(R)≈1.12。估计值偏离准确值。

# **标准版**

很明显，在上述介绍的方法中，估计值很不精确。

**因此实际中，为了减小误差提高精度，通常会采用多组hash方法。**

具体可以利用m组不同的hash方法，生成m个BITMAP，然后对每个BITMAP采用同样的方法计算出对应的R值，然后求平均。

有：

$R=R1+R2+...+Rmm$

$E(R)≈log_2φn;$

更进一步，还可以设计A组hash函数,其中每组B个hash函数，这些hash函数各不相同且映射结果均匀分布。然后利用每组中的B个哈希函数计算出B个估计值，求出B个估计值的算术平均数作为该组的估计值；最后将所有组的结果进行排序，取中位数作为最终的输出结果。

显然这种做法精度会进一步提高。

但是，这种做法却有些缺点。首先要设计这么多个不同且hash结果分布均匀的hash函数是困难的，其次这么做显然既耗时也耗空间。

显然F和M两位大佬看出了这个问题，所以他们采用的还是用一个hash函数来处理，不同的是BITMAP却是有m组。具体做法是，当一个数y进行hash之后，首先mod m，即

$α=h(x)mod (m)$

得到组号；组里的下标为：

$index=⌊h(x)/m⌋.​$

所以理想状态下均匀分布，则m个组中每个组都有

n/m个数，因此可以用$\overline R$来近似$log_2(φnm)$.

得出结论 ：$ n≈mφ2^\overline R$ φ=0.77351...,R¯=R1+R2+...+Rmm

。