# ultimc

A Forth written in FreePascal with the following variants:
* [fipq](fipq/README.md) - a bare-metal generic ARM version using Ultibo and runnable on QEMU
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

This Forth uses the Pre ANS standard. When you use `DOES>` you should use `<BUILDS`. The general rule is that wherever you use `DOES>`, you must also use `<BUILDS` instead of `CREATE`. So a typical definition of `CONSTANT` is: `: constant create , DOES> @ ;`

In this Forth, it is defined as:
```
: CONSTANT <BUILDS , DOES> @ ;
```

`DOES>` was successfully implemented on 18-Sep-2018.

### Implementation notes

`DOES>` is perhaps the most tricky feature to implement. Here's what atlast Forth has to say about the matter:

> O.K., we were compiling our way through this definition and we've
       encountered the Dreaded and Dastardly Does.  Here's what we do
       about it.  The problem is that when we execute the word, we
       want to push its address on the stack and call the code for the
       DOES> clause by diverting the IP to that address.  But...how
       are we to know where the DOES> clause goes without adding a
       field to every word in the system just to remember it.  Recall
       that since this system is portable we can't cop-out through
       machine code.  Further, we can't compile something into the
       word because the defining code may have already allocated heap
       for the word's body.  Yukkkk.  Oh well, how about this?  Let's
       copy any and all heap allocated for the word down one stackitem
       and then jam the DOES> code address BEFORE the link field in
       the word we're defining.


My solution to the problem is to make use of the old-fashioned `<BUILDS` word. `<BUILDS` is a compiled word, `DOES>` is an immediate word. So how does my system work?

When you call `<BUILDS`, it creates a new word with a `DOCOL` action, and then extends that word by adding a literal 777, and `ABRANCH` jumpt to address 888, and finally it added a `;`. The 777 and 888 are just placeholder values. The 777 needs to be replaced with an address which is equivalent to what CREATE does. This 777 points just beyond the `;` address. 

The `DOES>` is an immediate word that marks out the continuation of the word, a `(DOES>)`, which performs run-time stuff, and `EXIT`, which prevents the post-DOES code from running.

When `(DOES>)` is called, it overwrites the 777 with the address beyond the `;`, and replaces the 888 with the top of the stack shifted to the post-EXIT cell.

Here's how it works ...

Define `CONSTANT` as shown previously: ` constant <BUILDS , DOES> a ;`. If you `see constant`, you'll get output something like this: `<BUILDS , LIT 297 (DOES>) EXIT @ ;`. That `LIT 297` points to the cell where the `@` is. 

Let's a define a constant: `10 constant foo`. And `see foo`: `LIT 353 ABRANCH 297 ;` The `LIT 353` is the cell just after the `;`. The `ABRANCH` is an unconditional branch. See that address of 297 again?

Now run foo: `foo .`, which prints 10, as expected. 


## `:NONAME`

Implemented 16-Sep-2018. Documented [here](http://lars.nocrew.org/forth2012/core/ColonNONAME.html).

## `SELF .NAME`

Implemented 17-Sep-2018

`SELF` puts the address of the header of the word currently beign executed onto the stack.

`.NAME` tales the top off the stack, assuming it to be a header value, and prints the name of the word.

Example 1:
```
: foo self .name cr ; foo \ prints 'FOO'
```

Example 2:
The "self" of a word is the same as the ' of the word
```
: bar self ; bar ' bar .s \ outputs identical numbers: 139685488604288 139685488604288
```

This paves the way for creating a working version of DOES>. 

The way 'self' works is that there is an execstack array in parser.pas, with the variable esp pointing to the top of the stack. When ExecHeader(ptr:THeaderPtr) is called, it pushes ptr to the execstack, called the function associated with ptr, then pops off the execstack. So when `SELF` is called, it looks at the penultimate entry of execstack (because the last one is a call to SELF itself, which we're not interested in), and pushes it to the stack.

`.NAME` then just pops the value off as a header, and gets its name from there.



## ARM-specific

* [frambuffer](framebuffer.md)
* [GPIO](GPIO.md)
