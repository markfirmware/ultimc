\ : LIFE 		42 . ;
: VARIABLE 	create 0 , ;
: CELLS 	cell * ; \ n1 -- n2
: 2VARIABLE	create 0 , 0 , ;
: CELL+		cell + ;
: 2@		dup cell+ @ swap @ ;
: 2!		swap over ! cell+ ! ;
: CONSTANT	<BUILDS , DOES> @ ;
