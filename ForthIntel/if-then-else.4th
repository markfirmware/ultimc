: pr type cr ;
: t1 0 if s" this wont be printed" pr then ;  t1
: t2 1 if s" this will be printed" pr then ;  t2

: iet if s" true branch called" pr else s" false branch called" pr then ;
0 iet \ should print out true
1 iet \ should print out false

s" stack is:" type .s cr
