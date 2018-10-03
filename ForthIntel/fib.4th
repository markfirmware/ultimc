\ fibonacci number

: fib
  dup 1 > if 
  1- dup 1- fib swap fib + then
;

31 fib .s cr
s" Expected: 1346269" type cr
