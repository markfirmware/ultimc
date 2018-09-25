variable fh
variable buf 10 allot 
s" files.4th" r/o fileopen fh !
s" fh is " type fh @ .
: echo begin fh @ buf 10 fileread 0exit buf 10 type again ;
echo
fh @ fileclose
