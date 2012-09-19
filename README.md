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
    30         # タイプ 1 のインスタンス数
    30         # タイプ 2 のインスタンス数
    1          # 関係の種類 (1 -> unknown, 0 の2種類)
    3 0 0      # タイプ 1 のインスタンス 3 とタイプ 2 のインスタンス 0 の関係は 0
    3 0 0      # 以下同様
    ...

関係が記載されていない組み合わせに関しては勝手に unknown という関係を与えます。   
よって上の例では関係は unknown, 0 の 2種類になります。

### 出力ファイル
sbm.rb はファイルにクラスタリングの結果と \eta の推定値が出力します。  
例えば以下を実行したとします。

    ./sbm.rb -i test.dat -o test.out -n 100 -N 2

そのとき test.out の内容が以下であったとします。

    lp = -437.5091841451689
    z[0] = {1, 1, 1, 2, 2, 0, 2, 0, 2, 2, 0, 2, 1, 1, 0, 0, 2, 2, 2, 0, 1, 0, 2, 1, 2, 1, 2, 2, 2, 2}
    z[1] = {1, 2, 1, 1, 1, 0, 0, 2, 0, 1, 2, 1, 1, 2, 2, 1, 2, 0, 2, 1, 2, 2, 2, 2, 0, 0, 0, 0, 1, 1}
    {0, 0}, {0.9827586206896551, 0.017241379310344827}
    {0, 1}, {0.012658227848101266, 0.9873417721518988}
    {0, 2}, {0.9873417721518988, 0.012658227848101266}
    {1, 0}, {0.015151515151515152, 0.9848484848484849}
    {1, 1}, {0.9888888888888889, 0.011111111111111112}
    {1, 2}, {0.011111111111111112, 0.9888888888888889}
    {2, 0}, {0.9918032786885246, 0.00819672131147541}
    {2, 1}, {0.005988023952095809, 0.9940119760479041}
    {2, 2}, {0.005988023952095809, 0.9940119760479041}


1 行目はクラスタリング結果の最もらしさを示す周辺対数尤度です。   
この値は大きいほどよいのですが、必ずしもクラスタリングの結果の善し悪しを反映するものではありません。   
2, 3 行目はそれぞれタイプ 1, 2 の各インスタンスのクラス番号です。   
4 行目以降は各クラスの組み合わせにおける関係の起こりやすさを確率で表しています。   
確率は前から順に unknown, 0 となっています。
例えば、タイプ 1, 2 の双方がクラス 0 であるとき、関係 unknown の起こる確率は 0.98.. です。

### 使用例

テストデータ生成用のプログラム test.rb もいれときました。   
クラスタリングが出来ているか不安なので実験してみましょう。    
以下のようにテストデータを作り、クラスタリングを実行しました。

    ./test.rb > test.out
    ./sbm.rb -i test.dat -o test.out


この時のクラスタリング前後の行列を見比べてみましょう。    
自動的にグラフを出力するスクリプトも書いたのですが、ダサいのでここには載せません。    

![before](https://github.com/masakazu-ishihata/sbm/blob/master/test/test.png)
![after](https://github.com/masakazu-ishihata/sbm/blob/master/test/test.res.png)
