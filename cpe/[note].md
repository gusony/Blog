#### 絕對值
```int ABS(int x) {return x<0 ? -x : x}```

#### 最大公因數
```int GCD(int a, int b) { return b==0 ? a : GCD(b, a%b)}```


#### c++  STL Map
```#include <map>```
##### 宣告
```map< datatype, datatype> variable_name```
example:
```map< string, int> table;```

##### 給值
example:
```
table["hello"] = 1;
table['a'] = "hello";
table[1]=10;
```


#### C++ STL Set
```#include <set>```
```
set<int> t1;
set<string> t2;
```

```
//iterator
set<string>::iterator iter;
```

```
//output
cout << *iter << endl;
```

