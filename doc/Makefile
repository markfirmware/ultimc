TARG=fip.ps

.PHONY: clean

$(TARG) : fip.3
	tbl $^ | groff -m mom | psselect -p 1,_1,2-_2 > $@

clean: 
	rm -f $(TARG)

