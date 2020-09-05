+++
title = "cJSON代码阅读（parse）部分"
date = 2015-09-01
slug = "cjson-code-reading-parser"

[taxonomies]
tags = [ "c++", "reading", "parser" ]
+++

<div class="article_content" id="article_contents_inner_4362677854" dir="ltr">
						<pre style="max-width: 1241px; overflow: auto;"><code>static const char *skip(const char *in) {while (in &amp;&amp; *in &amp;&amp; (unsigned char)*in&lt;=32) in++; return in;}
</code></pre>

<p>跳过<strong>空白字符</strong>。空白字符即ASCII小于等于32的字符。（我还特意查了ascii的表…）。<em>这里我可能会用isspace（掩面逃…）</em></p>

<pre style="max-width: 1241px; overflow: auto;"><code>static const char *parse_value(cJSON *item,const char *value)
{
    if (!value)                     return 0;
    if (!strncmp(value,"null",4))   { item-&gt;type=cJSON_NULL;  return value+4; }
    if (!strncmp(value,"false",5))  { item-&gt;type=cJSON_False; return value+5; }
    if (!strncmp(value,"true",4))   { item-&gt;type=cJSON_True; item-&gt;valueint=1;  return value+4; }
    if (*value=='\"')               { return parse_string(item,value); }
    if (*value=='-' || (*value&gt;='0' &amp;&amp; *value&lt;='9'))    { return parse_number(item,value); }
    if (*value=='[')                { return parse_array(item,value); }
    if (*value=='{')                { return parse_object(item,value); }

    ep=value;return 0;
}
</code></pre>

<p>这里是parser的核心。判断该读入的元素类型。null，true，false这三个简单类型可以直接处理。其他的分别交给parse<em>number，parse</em>array和parse_object处理。ep是这里用于错误处理的指针，当出错的时候，ep指针里保存的就是当前出现错误的位置。</p>

<p>首先是parse_string部分：</p>

<pre style="max-width: 1241px; overflow: auto;"><code>static const unsigned char firstByteMark[7] = { 0x00, 0x00, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC };
static const char *parse_string(cJSON *item,const char *str)
{
    const char *ptr=str+1;char *ptr2;char *out;int len=0;unsigned uc,uc2;
    if (*str!='\"') {ep=str;return 0;}

    while (*ptr!='\"' &amp;&amp; *ptr &amp;&amp; ++len) if (*ptr++ == '\\') ptr++;

    out=(char*)cJSON_malloc(len+1);
    if (!out) return 0;

    ptr=str+1;ptr2=out;
    while (*ptr!='\"' &amp;&amp; *ptr)
    {
        if (*ptr!='\\') *ptr2++=*ptr++;
        else
        {
            ptr++;
            switch (*ptr)
            {
                case 'b': *ptr2++='\b'; break;
                case 'f': *ptr2++='\f'; break;
                case 'n': *ptr2++='\n'; break;
                case 'r': *ptr2++='\r'; break;
                case 't': *ptr2++='\t'; break;
                case 'u':
                    uc=parse_hex4(ptr+1);ptr+=4;

                    if ((uc&gt;=0xDC00 &amp;&amp; uc&lt;=0xDFFF) || uc==0)    break;

                    if (uc&gt;=0xD800 &amp;&amp; uc&lt;=0xDBFF)
                    {
                        if (ptr[1]!='\\' || ptr[2]!='u')    break;
                        uc2=parse_hex4(ptr+3);ptr+=6;
                        if (uc2&lt;0xDC00 || uc2&gt;0xDFFF)       break;
                        uc=0x10000 + (((uc&amp;0x3FF)&lt;&lt;10) | (uc2&amp;0x3FF));
                    }

                    len=4;if (uc&lt;0x80) len=1;else if (uc&lt;0x800) len=2;else if (uc&lt;0x10000) len=3; ptr2+=len;

                    switch (len) {
                        case 4: *--ptr2 =((uc | 0x80) &amp; 0xBF); uc &gt;&gt;= 6;
                        case 3: *--ptr2 =((uc | 0x80) &amp; 0xBF); uc &gt;&gt;= 6;
                        case 2: *--ptr2 =((uc | 0x80) &amp; 0xBF); uc &gt;&gt;= 6;
                        case 1: *--ptr2 =(uc | firstByteMark[len]);
                    }
                    ptr2+=len;
                    break;
                default:  *ptr2++=*ptr; break;
            }
            ptr++;
        }
    }
    *ptr2=0;
    if (*ptr=='\"') ptr++;
    item-&gt;valuestring=out;
    item-&gt;type=cJSON_String;
    return ptr;
}
</code></pre>

<p>首先是遍历了一次整个string，统计出一共的字符个数，存在了len里，中间遇到转义的部分跳过了后面的字符。个数统计好之后，申请内存。这里的<code>cJSON_malloc</code>就是原本的<code>malloc</code>。在这个函数的定义出可以找到：</p>

<pre style="max-width: 1241px; overflow: auto;"><code>static void *(*cJSON_malloc)(size_t sz) = malloc;
</code></pre>

<p>重新从头遍历整个string，不转义的部分是不用处理的。需要特殊处理的就是转义的部分，其实这部分也只有utf-16到utf-8的编码转换问题。（这里的magic number实在是太多了，我还没不知道utf-16和utf-8的编码方式。实在是看不懂了。）</p>

<pre style="max-width: 1241px; overflow: auto;"><code>static const char *parse_number(cJSON *item,const char *num)
{
    double n=0,sign=1,scale=0;int subscale=0,signsubscale=1;

    if (*num=='-') sign=-1,num++;
    if (*num=='0') num++;
    if (*num&gt;='1' &amp;&amp; *num&lt;='9') do  n=(n*10.0)+(*num++ -'0');   while (*num&gt;='0' &amp;&amp; *num&lt;='9');
    if (*num=='.' &amp;&amp; num[1]&gt;='0' &amp;&amp; num[1]&lt;='9') {num++;        do  n=(n*10.0)+(*num++ -'0'),scale--; while (*num&gt;='0' &amp;&amp; *num&lt;='9');}
    if (*num=='e' || *num=='E')
    {   num++;if (*num=='+') num++; else if (*num=='-') signsubscale=-1,num++;
        while (*num&gt;='0' &amp;&amp; *num&lt;='9') subscale=(subscale*10)+(*num++ - '0');
    }

    n=sign*n*pow(10.0,(scale+subscale*signsubscale));

    item-&gt;valuedouble=n;
    item-&gt;valueint=(int)n;
    item-&gt;type=cJSON_Number;
    return num;
}
</code></pre>

<p>这里数字的处理就简单很多了。
sign表示有没有负号，如果有的话sign是-1，否则sign为1。 <br>
去掉前导0之后，读入每位存在n里。
发现有"."，并且下一位是数字的话，就说明这是一个小数，开始读入小数点之后的部分。这里用scale来表示当前的数的小数点应该向左移动几位。（这样是不是也同样保证了精度呢？）
读入E，科学计数法表示。处理方式和前面一样。
最后计算出n就可以了。这里把浮点数和整数放在一起处理了。只要在最后valueint只取n的整数部分就可以了。（我自己尝试实现的时候，把整数和小数分开读的，在存类型的时候也尝试把他们分开了。）这种方式需要在输出的时候做一个特殊处理，判断一下valuedouble和valueint之间的差，如果小于给定的eps那就认为这个数字是一个整数，否则认为是小数。</p>

<pre style="max-width: 1241px; overflow: auto;"><code>static const char *parse_array(cJSON *item,const char *value)
{
    cJSON *child;
    if (*value!='[')    {ep=value;return 0;}

    item-&gt;type=cJSON_Array;
    value=skip(value+1);
    if (*value==']') return value+1;

    item-&gt;child=child=cJSON_New_Item();
    if (!item-&gt;child) return 0;
    value=skip(parse_value(child,skip(value)));
    if (!value) return 0;

    while (*value==',')
    {
        cJSON *new_item;
        if (!(new_item=cJSON_New_Item())) return 0;
        child-&gt;next=new_item;new_item-&gt;prev=child;child=new_item;
        value=skip(parse_value(child,skip(value+1)));
        if (!value) return 0;
    }

    if (*value==']') return value+1;
    ep=value;return 0;
}
</code></pre>

<p>接下来是关于数组的处理。和其他时候一样，先判断起始字符合法性。然后重复：
1. 新建cJSON对象 <br>
2. 读掉空白字符 <br>
3. 读入这个对象 <br>
4. 读掉空白字符 <br>
5. 判断这个字符是否是“,“。如果是，转到1，如果不是判断结尾字符合法性，退出。 <br>
数组里面的元素，是用了一个双向链表实现的。具体的定义在cJSON这个结构体的定义处给出了。</p>

<pre style="max-width: 1241px; overflow: auto;"><code>static const char *parse_object(cJSON *item,const char *value)
{
    cJSON *child;
    if (*value!='{')    {ep=value;return 0;}

    item-&gt;type=cJSON_Object;
    value=skip(value+1);
    if (*value=='}') return value+1;

    item-&gt;child=child=cJSON_New_Item();
    if (!item-&gt;child) return 0;
    value=skip(parse_string(child,skip(value)));
    if (!value) return 0;
    child-&gt;string=child-&gt;valuestring;child-&gt;valuestring=0;
    if (*value!=':') {ep=value;return 0;}
    value=skip(parse_value(child,skip(value+1)));
    if (!value) return 0;

    while (*value==',')
    {
        cJSON *new_item;
        if (!(new_item=cJSON_New_Item()))   return 0;
        child-&gt;next=new_item;new_item-&gt;prev=child;child=new_item;
        value=skip(parse_string(child,skip(value+1)));
        if (!value) return 0;
        child-&gt;string=child-&gt;valuestring;child-&gt;valuestring=0;
        if (*value!=':') {ep=value;return 0;}
        value=skip(parse_value(child,skip(value+1)));
        if (!value) return 0;
    }

    if (*value=='}') return value+1;
    ep=value;return 0;
}
</code></pre>

<p>最后有关于parse的就是关于object对象的parse了。常规的判断其实字符，读掉空白字符。这里先判断了一次结束字符来看是不是空的。
因为一旦有了元素之后，在判断下一个元素是否存在的时候，判断的条件就变成了“,”。这部分在数组中有一样的处理。
这里整体的过程其实和数组的区别只在读入单个元素的方法上：
先读入一个string，读冒号“:”，读value。然后每个child的属性里的string部分保存了这个value的名字。（这里这个保存方式，是不是在get的时候的效率会出现问题呢。感觉这里如果多处理一点，对string串做一个hash可能效果会好一点。）</p>

<p>这样parse细节的部分就都看完了。cJSON<em>Parse函数是对cJSON</em>ParseWithOpts的一个封装。cJSON_ParseWithOpts函数处理了读入一个value之外的就是判断了是否需要null作为结束，和返回值存到哪里的问题。代码也很简单：</p>

<pre style="max-width: 1241px; overflow: auto;"><code>cJSON *cJSON_ParseWithOpts(const char *value,const char **return_parse_end,int require_null_terminated)
{
    const char *end=0;
    cJSON *c=cJSON_New_Item();
    ep=0;
    if (!c) return 0;

    end=parse_value(c,skip(value));
    if (!end)   {cJSON_Delete(c);return 0;}

    if (require_null_terminated) {end=skip(end);if (*end) {cJSON_Delete(c);ep=end;return 0;}}
    if (return_parse_end) *return_parse_end=end;
    return c;
}
</code></pre>