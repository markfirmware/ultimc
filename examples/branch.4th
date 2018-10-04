: 2cells cell cell + , ; IMMEDIATE
: test branch 2cells exit dup ;
clearstack 10 test .s \ expected output: 10 10

: 0test 0branch 2cells exit dup ;
clearstack 11 0 0test .s \ expected output: 11 11
clearstack 12 1 0test .s \ expected output: 12


see test
see 0test
bye
