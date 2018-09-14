# ultimc
Me fooling around with Ultibo

## Implementation

' P_tick useful for debugging ( -- xt )
execute P_execute ( xt -- )
and ensuring that CREATE creates a header correctly

So now you can do a long-handed 1 2 + as 1 2 ' + execute

This is how you can implement comments:
: \ 10 parse 2drop ; immediate


We can test the BRANCH word as follows:
	: test branch [ cell , ] exit dup ;
Then
	clearstack 22 test .s
should output:
	22 22

Test the ?BRANCH word as follows:
	: test ?branch [ cell , ] exit dup ;
Then
	clearstack 22 0 test .s
should output:
	22 22
whilst
	clearstack 22 1 test .s
will output:
	22

## See also

* [GPIO](GPIO.md)
