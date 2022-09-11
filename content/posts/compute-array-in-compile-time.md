+++
title =  "编译时期计算数组"
date = 2015-09-01
slug = "compute-array-in-compile-time"
[taxonomies]
categories =  ["Tech"]
tags = [
  "c++",
  "template",
  "tips",
  "c++11",
]
+++

```
    #include <iostream>
    #include <array>
    using namespace std;
    
    constexpr int N = 1000000;
    constexpr int f(int x) { return x*2; }
    
    typedef array<int, N> A;
    
    template<int... i> constexpr A fs() { return A{{ f(i)... }}; }
    
    template<int...> struct S;
    
    template<int... i> struct S<0,i...>
    { static constexpr A gs() { return fs<0,i...>(); } };
    
    template<int i, int... j> struct S<i,j...>
    { static constexpr A gs() { return S<i-1,i,j...>::gs(); } };
    
    constexpr auto X = S<N-1>::gs();
    
    int main()
    {
            cout << X[3] << endl;
    }
```
    

在编译时期计算一个数组里面的元素，这种方法在\\(N\\)较大的时候会出现`constexpr`递归深度较大的问题。这种线性的求法似乎不能很好的处理当\\(N\\)较大的情况。所以这时候可以通过二分所求的\\(N\\)来解决这个问题。这样最大的递归深度就从\\(N\\)变成了\\(logN\\)了。 排名第一的回答中代码是这样写的：

```
    template<class T> using Invoke = typename T::type;
    
    template<unsigned...> struct seq{ using type = seq; };
    
    template<class S1, class S2> struct concat;
    
    template<unsigned... I1, unsigned... I2>
    struct concat<seq<I1...>, seq<I2...>>
      : seq<I1..., (sizeof...(I1)+I2)...>{};
    
    template<class S1, class S2>
    using Concat = Invoke<concat<S1, S2>>;
    
    template<unsigned N> struct gen_seq;
    template<unsigned N> using GenSeq = Invoke<gen_seq<N>>;
    
    template<unsigned N>
    struct gen_seq : Concat<GenSeq<N/2>, GenSeq<N - N/2>>{};
    
    template<> struct gen_seq<0> : seq<>{};
    template<> struct gen_seq<1> : seq<0>{};
    
    // example
    
    template<unsigned... Is>
    void f(seq<Is...>);
    
    int main(){
      f(gen_seq<6>());
    }
```
    

原文： [http://stackoverflow.com/questions/13072359/c11-compile-time-array-with-logarithmic-evaluation-depth](http://stackoverflow.com/questions/13072359/c11-compile-time-array-with-logarithmic-evaluation-depth)