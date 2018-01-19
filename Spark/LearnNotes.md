### RDD aggregate: aggregate(zero Value)(func1, func2)
  * zero value: single value or tuple (ex: (0,0,1))
  * func1: reduce function for same partation, two parameters: (tuple map to zero value, content of RDD)
  * func2: reduce function for different partation, two parameters: (tuple in current partation, tuple in next partation)
  ```
  ##### use aggregate to calculate (sum, mutiple, count) of a Int RDD
  val nums=sc.parallelize(List(1,2,3,4,5,6),3)
  val (acc, mut, num)=nums.aggregate((0,0,1))((acc, number) => 
      (acc._1+number, acc._2+1, acc._3 * number), (p1,p2)=>(p1._1+p2._1, p1._2+p2._2, p1._3*p2._3))
  ```
  
### Implicit Conversion In Scala
refer to [this article](https://ithelp.ithome.com.tw/articles/10186437)

### Currying In Scala
refer to [this article](https://ithelp.ithome.com.tw/articles/10187406)
