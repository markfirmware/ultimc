: print type cr ;
: say s" Ultibo!" print ;

s" Printing Ultibo 10 times the 'Forth way'" print
: say10 say say say say say say say say say say ;
\ say10

s" Using looping constructs:" print
: sayn begin say 1 - dup 0exit again ;
\ 10 sayn
\ .s 

s" Let's do meta:" print
: again? 1 - dup not ;
: <times here ; immediate
\ : times> ` exit? ` 0exit  ` again ; immediate
: times>  ` again?  here - cell -  ` 0BRANCH ,   ; immediate

: saym <times say say times> ;
see saym
5 saym

s" Insanity:" print
: wtf 5 <times 2 <times say times> times> ;
see wtf 
\ wtf
 
bye
