
sparkPage.R - 文字雲程式<br>
sparkPage.txt - Apache Sprak 首頁原始碼<br>
<br>
問題: https://www.facebook.com/photo.php?fbid=738637809645193&set=gm.822569537893762&type=3&theater

<br><br>實作要點:
<ul>
<li>parsing 對象為網頁原始碼，而非網頁文字內容(參考sparkPage.txt)</li>
<li>全文轉小寫後，先remove stopwords，否則corpus中會出現很多像enginea(原文為engine&gt;&lt;/a&gt;)這種干擾</li>
                                                    <li>removeWords函式中，stopWords是可以自訂的，最後再把不想要在結果中出現的字元remove掉(好吧，我承認這招是偷吃步)</li>
</ul>
