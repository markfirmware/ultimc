: var create , ;

10 var 'counter ;

: -- dup @ 1 - swap ! ;
: countdown begin 'counter @ dup . 0exit  'counter -- again ;

see countdown
countdown
'counter --
s" value of counter is " type 'counter @ .
s" stack is " type .s
