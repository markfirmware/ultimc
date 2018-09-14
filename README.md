# ultimc
Me fooling around with Ultibo

## Implementation

' P_tick useful for debugging ( -- xt )
execute P_execute ( xt -- )
and ensuring that CREATE creates a header correctly

So now you can do a long-handed 1 2 + as 1 2 ' + execute

This is how you can implement comments:
: \ 10 parse 2drop ; immediate


## See also

* [GPIO](GPIO.md)
