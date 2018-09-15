# ultimc
Me fooling around with Ultibo

## Implementation

' P_tick useful for debugging ( -- xt )
execute P_execute ( xt -- )
and ensuring that CREATE creates a header correctly

So now you can do a long-handed 1 2 + as 1 2 ' + execute

This is how you can implement comments:
```
: \ 10 parse 2drop ; immediate
```


We can test `BRANCH` and `0BRANCH` (branch.4th) as follows:
```
: 2cells cell cell + , ; IMMEDIATE
: test branch 2cells exit dup ;
clearstack 10 test .s \ expected output: 10 10

: 0test 0branch 2cells exit dup ;
clearstack 11 0 0test .s \ expected output: 11 11
clearstack 12 1 0test .s \ expected output: 12
```

## See also

* [GPIO](GPIO.md)
