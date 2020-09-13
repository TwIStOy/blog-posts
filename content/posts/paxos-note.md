+++
title = "Paxos Note"
date = 2020-05-24
slug = "paxos-note"

[taxonomies]
tags = ["paxos", "distribute-system" ]
+++

## Symbols And Structure
- 表决 $B$
    ```rs
    struct Ballot {
      dec: Decree,      // 表决的内容
      vot: Set<Node>,   // 表决投票通过的节点
      qrm: Set<Node>,   // 表决参与的节点
      bal: u64,         // 表决编号
    }
    ```
    A ballot is said to be successful, if every quorum member voted. In math:
    $$ B_{qrm} \subseteq B_{vot} $$
- 投票 $v$
    ```rs
    struct Vote {
      pst: Node,        // 本投票的节点
      bal: u64,         // 本投票的表决编号
      dec: Decree,      // 本投票表决的内容
    }
    ```
- 表决的集合 $\beta$

## Define Some Useful functions
- $Votes(\beta)$：所有在 $\beta$ 中的表决的投票的集合
$$Votes(\beta) = \\{v:(v_{pst}\in B_{vot})\cap(v_{bal}=B_{bal}), B \in \beta\\}$$
- $Max(b, p, \beta)$：在由节点 $p$ 投给 $\beta$ 中的表决的投票中，编号小与等于 $b$ 的最大投票
$$Max(b, p,\beta)=max\\{v \in Votes(\beta):(v_{pst}=p)\land(v_{bal}<b)\\}\cup\\{null_{p}\\}$$
- $MaxVote(b, Q, \beta)$：在集合 $Q$ 中的任意一个节点投给 $\beta$ 中的表决的投票中，编号小于等于 $b$ 的最大投票
    $$MaxVote(b,Q,\beta)=max\\{v\in Votes(\beta):(v_{pst}\in Q)\cap(v_{val}<b)\\}\cup\\{null_p\\}$$

那么如果条件$B1(\beta)-B3(\beta)$满足的情况下，那么系统将满足一致性，并且是可进展的。
- $B1(\beta) \triangleq \forall B,B' \in \beta:(B \ne B') \implies (B_{bal} \ne B'_{bal})$
- $B2(\beta) \triangleq \forall B,B' \in \beta:B\_{qrm}\cap B'_{qrm} \ne \emptyset $
- $B3(\beta) \triangleq \forall B \in \beta: (MaxVote(B\_{bal},B_{qrm},\beta)\_{bal}\ne - \infty) \implies B\_{dec} = MaxVote(B\_{bal}, B\_{qrm}, \beta)\_{dec} $

### Lemma 1
如果 $\beta$ 中的表决 $B$ 是成功的，那么 $\beta$ 中更大编号的表决和 $B$ 的表决内容相同。
$$ ((B\_{qrm} \subseteq B\_{vot})\land(B'\_{bal}>B\_{bal})) \implies (B'\_{dec}=B\_{dec}) $$

### Proof
定义集合 $\Phi(B, \beta)$: $\Phi(B, \beta) \triangleq \\{B'\in \beta:(B'\_{bal}>B\_{bal})\land(B'\_{dec}\ne B\_{dec}) \\}$，表示 $\beta$ 中编号比 $B$ 大并且表决内容不相同的表决的集合。
1. $ C = min\\{B':B'\in \Phi(B, \beta)\\} $
2. $ C\_{bal} < B\_{bal} $
3. $ C\_{qrm} \cap B\_{bot} \ne \emptyset $
    因为 $B2$ 和 假设中的 $B$ 表决是成功的，也就是 $ B\_{qrm} \subseteq B\_{vot} $
4. $ MaxVote(C\_{bal},C\_{qrm},\beta)\_{bal} \ge B\_{bal} $
    因为 $C\_{qrm}$ 和 $B$ 的投票者一定有交集
1. $ MaxVote(C\_{bal}, C\_{qrm}, \beta)\in Votes(\beta)$
2. $ MaxVote(C\_{bal}, C\_{qrm}, \beta)\_{dec} = C\_{dec} $
3. $ MaxVote(C\_{bal}, C\_{qrm}, \beta)\_{dec} \ne B\_{dec} $
4. $ MaxVote(C\_{bal}, C\_{qrm}, \beta)\_{bal} > B\_{bal} $
5. $ MaxVote(C\_{bal}, C\_{qrm}, \beta) \in Votes(\Phi(B, \beta)) $
6. $ MaxVote(C\_{bal}, C\_{qrm}, \beta)\_{bal} < C\_{bal} $
7. 9, 10 和 1 矛盾。

### 定理 1
在满足 $B1(\beta)$，$B2(\beta)$，$B3(\beta)$ 的情况下，
$$((B\_{qrm} \subseteq B\_{vot})\land(B'\_{qrm}\subseteq B'\_{vot})) \implies (B'\_{dec} = B\_{dec}) $$

### 定理 2
$$ \forall B\in\beta, b > B\_{bal}, Q \cap B\_{qrm} \ne \emptyset $$ 如果 $B1(\beta)$，$B2(\beta)$，$B3(\beta)$ 满足，那么存在一个 $ B', B'\_{bal}=b, B'\_{qrm}=B'\_{vot}=Q $ 使得 $B1(\beta\cup\\{B'\\})$，$B2(\beta\cup\\{B'\\})$，$B3(\beta\cup\\{B'\\})$ 成立。
