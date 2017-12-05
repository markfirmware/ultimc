all : GimpPpmTest

clean :
	rm -f *.ppu *.o GimpPpmTest

%.o : %.pas

GimpPpm.o : GimpPpm.pas

GimpPpmTest.o : GimpPpmTest.pas

GimpPpmTest : GimpPpm.pas GimpPpmTest.pas
	fpc  $^
