TARG=fip.ps

.PHONY: clean

$(TARG) : fip.3
	groff -m mom $^ | psselect -p 1,_1,2-_2 > $@
	#groff -m mom $^  > $@

clean: 
	rm -f $(TARG)

