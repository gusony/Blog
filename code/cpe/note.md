#### 絕對值
```int ABS(int x) {return x<0 ? -x : x}```

#### 最大公因數
```int GCD(int a, int b) { return b==0 ? a : GCD(b, a%b)}```


#### iterator
```
map< datatype, datatype>::iterator iter1;
set<int>::iterator iter2;
vector<int>::iterator iter3;
```
```
//移動iter
std::advance (iter,5); // iter增加某個值
iter++;
```

```
//由iter取值
map_iter->first, map_iter->second;
*set_iter;
*vector_iter;
```


#### Map
```#include <map>```
```
//宣告
map< datatype, datatype> variable_name
map< string, int> table;
map< int, int> table2;
```
```
//給值
table["hello"] = 1;
table['a'] = "hello";
table[1]=10;
```
```
//取值
cout << iter->first << iter->second << endl; //用iter
cout << table["hello"] << endl; //直接取值
cout << table2[10] << endl;
```


#### Set
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

#### C++ STL Vector
```#include <vector>```
```
vector<int> vec;
vec.push_back(1); // 放進到最後
vec.pop_back(); // 刪掉最後一個 回傳最後一個
```
