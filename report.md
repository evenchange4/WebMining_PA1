### install rvm

```
$ \curl -L https://get.rvm.io | bash -s stable --rails --autolibs=enabled # Or, --ruby=1.9.3

```

### create ngram & merge

```
$ make

$ bin/create-ngram -vocab data/vocab.all -o unigram -n 1 -encoding utf8 data/query-5.xml

$ bin/create-ngram -vocab data/vocab.all -o bigram -n 2 -encoding utf8 data/query-5.xml

$ bin/create-ngram -vocab data/vocab.all -o trigram -n 3 -encoding utf8 data/query-5.xml

$ bin/merge-ngram -o ngram.all unigram bigram trigram

```



```
$ ruby main.rb -r -i ./queries/query-5.xml -o ans -m ./model-files -d ./CIRB010
```




ssh b98705034@linux19.csie.ntu.edu.tw



$ which bash
=> /bin/bash

$ chmod +x compile.sh 
$ ./compile.sh
$ chmod +x execute.sh 
$ ./execute.sh -r -i ./queries/query-5.xml -o ans -m ./model-files -d ./CIRB010
$ ./execute.sh -r -i /tmp2/queries/query-5.xml -o ans -m /tmp2/model-dir -d /tmp2/CIRB010