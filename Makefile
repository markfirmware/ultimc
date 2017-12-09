all : GimpPpmTest GluteTest

clean :
	rm -f *.ppu *.o GimpPpmTest

%.o : %.pas

GimpPpm.o : GimpPpm.pas

GimpPpmTest.o : GimpPpmTest.pas

GimpPpmTest : GimpPpm.pas GimpPpmTest.pas
	fpc  $^

#Glute.o : Glute.pas

#GluteTest.o : GluteTest.pas

GluteTest : Glute.pas  Edi.pas EdiGlute.pas GluteTest.pas
	fpc $^
