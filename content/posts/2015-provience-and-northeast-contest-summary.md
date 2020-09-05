+++
date = 2015-09-01
slug = "2015-provience-and-northeast-contest-summary"
title = "2015 省赛、东北赛总结"

[taxonomies]
tags = [ "acm" ]
+++

<div class="article_content" id="article_contents_inner_5127461383" dir="ltr">
						<h1>Part1. 省赛  </h1>

<p>先来吐槽下工大，热身赛之前大家都在外面站着连个休息的地方都没有，整个人都被冻傻了…正赛那天早上还好（其实我感觉主要是天比较给力，比较暖和，也可能是我机智的穿上了棉袄的原因…2333。） <br>
然后就是题目的部分了，所有题目主要就是题面比较难读吧，绝对是的。我们一致认为着出题人的英语绝对有问题，然后脑洞有点大…（绝对脑洞巨大…）</p>

<ul><li>A题，直到现在我依旧没能看懂题目在说什么，如何通过题面得到样例的…</li>
<li>B题，大概貌似是一个贪心吧，我们队按照这个思路写了挺长时间的，，然后WA了，，感觉小问题小坑很多…</li>
<li>C题，我们队也开了，主要是前面三个小时就已经A了五个题了，后面就一起开了B题和C题，结果都坑掉了。
题目大概是说一个连连看，当前状态有多少种合法的选择消去的方案。暴力的用优先队列+BFS尝试了一下，结果T掉了。</li>
<li>D题，其实是一个很简单的贪心啦，题意上面也没有什么难度和坑。很容易1A，我记得。</li>
<li>E题，这道题我读题意读了挺长时间的，然后样例上还有点小问题。（英语太烂23333）读懂题意以后也会很简单的。</li>
<li>F题，我们队用的方法是数位DP，当然由于数据范围的关系暴力好像也是可以过的。</li>
<li>G题，这道题真正的坑点在脑洞上…我至今都是这么认为的。虽然这道题是我们夺冠的关键，，，但是依旧改变不了这是一个脑洞题的事实。只要记得，并不是一个联通块周围有白子和黑子是一人0.5，而是按照白子和黑子的个数按权分配的！就可以了。</li>
<li>H题，斗地主，给你三家牌，问第一家能不能春天…并没有仔细的思考下去…</li>
<li>I题，给三张牌算得分，很简单的模拟。</li>
<li>J题，裸的二分图匹配。WA了一次居然是因为数组忘记清空了…23333。</li>
</ul><p>如实的说，能夺冠这件事完全就是恰好我们的脑洞开到了出题人的脑洞上去，和我们队本来的实力没有那么大的关系。</p>

<h1>Part2. 东北赛  </h1>

<p>到了东北赛感觉好了很多啊，进门也不要排队了，也不要在外面傻傻的冻着了。顿觉幸福…</p>

<ul><li>A题，水题不多说。1A。</li>
<li>B题，二维树状数组模板。1A。</li>
<li>C题，题意是说求一个三角形结构中选k个的最大权。读到这道题的时候，我们还在卡着其他的两个题，所以就没有多想下去，而且那么时间想下去也不知道能不能想出来…</li>
<li>D题，类似树形DP的东西，没什么坑点。1A。</li>
<li>E题，说道E题就要说，我很愧对我的高数和大物老师，嗯…还有我高中的数学老师。思路卡了一次，错了一次，然后才发现应该如何的简单处理，最后还卡了一下精度处理上。傻的不行…</li>
<li>F题，没读，现在写总结的时候，，也不想读。</li>
<li>G题，对x做质因子分解求出所有的质因子，然后对于每一个查询m，只要做一个优先队列+BFS就可以了。因为只会找第5个大的。所以结果会很少的。WA了几次都WA在了重复数字的处理上。处理掉了就没问题了。</li>
<li>H题，很简单的一个BFS，坑在了起点就在一个除了1之外的触发器上。嗯…由于忘记了这里，WA了一个半小时。</li>
<li>I题，水题。最开始数据错了，应该是，最后rejudge了，不过也听说有好多小伙伴被坑了。</li>
<li>J题，同F。</li>
<li>K题，我们最后时刻在写的五子棋的问题。我们的想法就是对于有人胜利的情况，来判断局面是否合法，方法就是尝试删掉每一个棋子，看会不会让整个棋局上没有人胜利了，如果有这样的棋子，那么就代表是合法的，否则就不合法。</li>
</ul><p>总结起来我们一共过了7个题，在7个题里好像也不算速度很快的，要不排名还能再上升一些的。感觉这次比较还是比较能反映出我们队的水平吧。 <br>
在比赛里也学到了好多东西，嗯…亮哥说比完赛要去实习了，祝亮哥实习愉快喽~</p>