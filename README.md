# ultimc

A Forth written in FreePascal with the following variants:
* vanilla - works on any OS, any CPU
* pi - a bare-metal version for the Raspberry Pi using Ultibo

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

## Macrology

The Forth standard has a smorgasbord of compilation words, and it is difficult to know what to do when. Most Forth words have run-time behaviour. But what if you need compile-time behaviour? In this section, I want you to think "Lisp macros", where you get to manipulate how words are compiled, and what they do.

The way we achieve this is through the (`` ` ``) word, which is equivalent to ANSI Forth's `POSTPONE` word. I chose the backtick (aka grave) symbol inspired by Lisp. The grave works a little bit similar to the ', but different.

Let's try things without "macros", first. Let me define the word double `: double dup + ;`, which simply doubles a number on the stack. Let's decompile the word, using `see double` to see how it's defined. Forth gives the result `DUP + ;`. No surprises there, it's just what we defined it as. Now let me define another word, `quad`, which multiplies a number by 4: `: quad double double ;`. Let's decompile it (`see quad`), and we obtain, once again, the obvious: `DOUBLE DOUBLE ;`.

Now let's mix things up a bit. Although this is a contrived and not-very-useful example, we're going to inline the double word into quad. We're going to define double as a "macro". Macros should be defined as IMMEDIATE words, because they'll need to "do their stuff" when you are defining words. The way we "escape" words within the macro so that they are "embedded" within other words is to use the `` ` `` word. So let's define DOUBLE as a macro:
```
: double ` dup ` + ; IMMEDIATE
```
Now do `see double`:
```
LIT 140287997130304 COMPILE, LIT 140287997129984 COMPILE, ; IMMEDIATE
```
Oh, not so obvious now. Your results will probably have different numbers. That's OK. So what's going on? Well the "LIT 140287997130304" is a number corresponding to the word pointer. The first one should relate to the DUP word, and the second to the + word. Let's check:
```
' dup . \ output is 140287997130304
' +   . \ output is 140287997129984
```
So `double` now pushes the pointer to dup on the stack, does "COMPILE,", and likewise for +. What does `compile?` do? Well, during runtime, it pops a number off the stack, and writes it to the heap. If you're defining `quad`, then this becomes incorporated into the word. So let's define `quad`:
```
: quad double double ;
```
It's exactly the same as before. Let's decompile it using `see quad`:
```
DUP + DUP + ; 
```
As if by magic, double has been embedded within quad.


## `CREATE DOES>`

`DOES>` is an immediate word, which I have not successfully implemented yet.

### `CREATE`

gforth implementation: `: create header reveal dovar: cf, ;`

pforth implements it as a primitive 

### `DOES>`

gforth has quite a complex construction involving two nonames.

In pforth : `: lv.finish postpone does> ;`


### Words dereived from CREATE-DOES

pforth defines 
	: constant create , 1980 (DOES>) ; 
where 1980 is the constant word.

gforth defines 
	: constant (constant) , ; 
where 
	: (constant) header reveal decon: cfa, ;

More traditionally is is defined as 
	: constant create , DOES> @ ;

Also useful is:
	: VALUE VARIABLE DOES> @ ;
with typical usage
	10 VALUE TEN

## `:NONAME`

Implemented 16-Sep-2018. Documented [here](http://lars.nocrew.org/forth2012/core/ColonNONAME.html).

## See also

* [GPIO](GPIO.md)
