\ a little test suite
\ 1 includes the file
\ 0 ignores it

: run-file cr cr s" Running " type 2dup type cr included ;
: incl rot if run-file else 2drop then ;

1 s" fib.4th" incl
1 s" begin-again.4th" incl
1 s" if-then-else.4th" incl

.s
bye
