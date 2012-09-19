# Stochastic Block Model (SBM)

Bayesian SBM の Collapsed Gibbs Sampling を試しに実装してみる。   
A を M^1 * M^2 行列とし、A_{ij} はカテゴリ(etc 0/1, non/good/bad)  
SBM では A の確率を以下の様に定義する。   

    \pi^n ~ Dir(\alpha)    (n = 1,2)
    c^n ~ Cat(\pi^n)       (n = 1,2)
    \eta_{kl} ~ Dir(\beta) (1 \leq k \leq N^1, 1 \leq l \leq N^2)
    A_{ij} ~ Cat(\eta_{k]) s.t. c_i^1 = k, c_j^2 = l

    N^n := n 番目の属性のクラスタ数
    
これより

   p(A, c^1, c^2, \pi^1, \pi^2, \eta | \alpha, \beta)
   = p(A | c^1, c^2, \eta) 
     \prod_{n=1,2} p(c^n | \pi^n)p(\pi^n | \alpha)
     \prod_{k,l} p(\eta_{kl} | \beta)
