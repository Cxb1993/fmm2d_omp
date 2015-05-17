SHELLSC = compChSize.sh
AVG = search_time_aver.py
PY = python3
OUTDIR = output

chunk: compChSize.sh ../examples/int2
	chmod +x compChSize.sh
	./compChSize.sh
	$(PY) $(AVG)

strong: sscale.sh ../examples/int2
	chmod +x sscale.sh
	./sscale.sh
	$(PY) $(AVG)


clean: 
	rm $(OUTDIR)/*
	rm result.txt
