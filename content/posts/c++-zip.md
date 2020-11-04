+++
date = 2016-04-05
slug = "zip-implementtation-for-cpp"
title = "C++ zip实现"
[taxonomies]
categories =  ["Post"]
tags = [
  "c++", "c++11", "template", "zip", "python"
]
+++

最近心血来潮想在C++里实现一些像在python里一样好用的小组件，主要是希望充分发挥`C++11`里`for`循环的威力。在完成了`enumerate`之后，在`zip`的完成上用了比较久的时间。

在这里记录下来自己对`zip`的简单实现。

主要就用了模板递归，结合了一些`C++11`的新特性完成的。

<!-- more -->

```c++
#pragma once

namespace twistoy {
	template<typename first, typename... last>
	class zip_iterator {
	public:
		using value_type = std::tuple<typename first::reference, typename last::reference...>;
		using rebind = zip_iterator<first, last...>;
		using sub_iterator = zip_iterator<last...>;
	private:
		first it_;
		sub_iterator sub_it_;
	public:

		zip_iterator(first it, sub_iterator sub_it) : it_(it), sub_it_(sub_it) {}

		rebind& operator++() {
			++it_;
			++sub_it_;
			return *this;
		}

		value_type operator *() {
			return std::tuple_cat(std::tuple<typename first::reference>(*it_), *sub_it_);
		}

		bool operator != (const rebind& others) const {
			return (it_ != others.it_) && (sub_it_ != others.sub_it_);
		}

	};

	template<typename first>
	class zip_iterator<first> {
	public:
		using value_type = std::tuple<typename first::reference>;
		using rebind = zip_iterator<first>;
	private:
		first it_;
	public:
		zip_iterator(first it) : it_(it) {}
		value_type operator *() {
			return value_type(*it_);
		}
		rebind& operator++() {
			++it_;
			return *this;
		}
		bool operator != (const rebind& others) const {
			return it_ != others.it_;
		}
	};

	template<typename first, typename... last>
	class zip_impl : zip_impl<last...> {
	public:
		using iterator = zip_iterator<typename first::iterator, typename last::iterator...>;
	private:
		first& value_;
	public:
		zip_impl(first& value, last&... args) : value_(value), zip_impl<last...>(args...) {}
		iterator begin() {
			return iterator(value_.begin(), zip_impl<last...>::begin());
		}
		iterator end() {
			return iterator(value_.end(), zip_impl<last...>::end());
		}
	};

	template<typename first>
	class zip_impl<first> {
	public:
		using iterator = zip_iterator<typename first::iterator>;
	private:
		first& value_;
	public:
		zip_impl(first& value) : value_(value) {}
		iterator begin() {
			return iterator(value_.begin());
		}
		iterator end() {
			return iterator(value_.end());
		}
	};

	template<typename... args_t>
	zip_impl<typename std::decay<args_t>::type...> zip(args_t&... args) {
		zip_impl<typename std::decay<args_t>::type...> tmp(args...);
		return tmp;
	}
}
```