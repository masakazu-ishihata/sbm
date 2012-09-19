# Stochastic Block Model (SBM)

Bayesian SBM の Collapsed Gibbs Sampling を試しに実装してみる。   
A を M^1 * M^2 行列とし、A_ij ２つのインスタンス i,j の関係(etc 0/1, non/good/bad) を表す。   
SBM は A の生成過程を以下の様に仮定する。   

    \pi^n ~ Dir(\alpha)    (n = 1,2)
    c^n ~ Cat(\pi^n)       (n = 1,2)
    \eta_{kl} ~ Dir(\beta) (1 \leq k \leq N^1, 1 \leq l \leq N^2)
    A_{ij} ~ Cat(\eta_{k]) s.t. c_i^1 = k, c_j^2 = l

    N^n = n 番目の属性のクラスタ数
    
これより Bayesian SBM の同時分布は以下のようにかける。

    p(A, c^1, c^2, \pi^1, \pi^2, \eta | \alpha, \beta)
    = p(A | c^1, c^2, \eta) 
      \prod_{n=1,2} p(c^n | \pi^n)p(\pi^n | \alpha)
      \prod_{k,l} p(\eta_{kl} | \beta)

## 入力ファイル

入力は関係データです。  
フォーマットは以下です。

    2          # データの次元(タイプ数)
    10         # タイプ 1 のインスタンス数
    10         # タイプ 2 のインスタンス数
    2          # 関係の種類 (2 -> 0,1 の2種類)
    0 0 0      # タイプ 1 のインスタンス 0 とタイプ 2 のインスタンス 0 の関係は 0
    0 2 1      # 以下同様
    ...

関係が記載されていない組み合わせに関しては勝手に unknown という関係を与えます。   
よって上の例では関係は 0, 1, unknown の 3種類になります。

### 出力ファイル
sbm.rb はファイルにクラスタリングの結果と \eta の推定値が出力します。  
例えば以下を実行したとします。

    ./sbm.rb -i test.dat -o test.out -n 100 -N 2

そのとき test.out の内容が以下であったとします。

    lp = -91.15883102861561
    z[0] = {1, 0, 0, 0, 1, 1, 0, 0, 1, 0}
    z[1] = {0, 0, 0, 1, 1, 1, 1, 1, 1, 0}
    {0, 0}, {0.6625514403292181, 0.08641975308641975, 0.2510288065843621}
    {0, 1}, {0.7190082644628099, 0.1955922865013774, 0.08539944903581266}
    {1, 0}, {0.3742331288343559, 0.2515337423312884, 0.3742331288343559}
    {1, 1}, {0.7448559670781892, 0.12757201646090532, 0.12757201646090532}

1 行目はクラスタリング結果の最もらしさを示す周辺対数尤度です。   
この値は大きいほどよいのですが、必ずしもクラスタリングの結果の善し悪しを反映するものではありません。   
2, 3 行目はそれぞれタイプ 1, 2 の各インスタンスのクラス番号です。   
4 行目以降は各クラスの組み合わせにおける関係の起こりやすさを確率で表しています。   
確率は前から順に unknown, 0, 1 となっています。
例えば、タイプ 1, 2 の双方がクラス 0 であるとき、関係 unknown の起こる確率は 0.66 です。