\ : LIFE 		42 . ;
: VARIABLE 	create 0 , ;
: CELLS 	cell * ; \ n1 -- n2
: 2VARIABLE	create 0 , 0 , ;
: CELL+		cell + ;
: 2@		dup cell+ @ swap @ ;
: 2!		swap over ! cell+ ! ;
\ : CONSTANT	<BUILDS , DOES> @ ;

: !0exit ` 0branch 2 cells , ` exit ; immediate
: 0exit  ` not ` 0branch 2 cells , ` exit ; immediate

\ testing the framebuffer
\ variable RGB 
\ : RECT	 >rgb16 rgb ! 0 0 500 500 rgb @ fbrect ;
\ : RED	100  0  0 rect ;
\ : GREEN	 0 100  0 rect ;
\ : BLUE	 0  0 100 rect ;

