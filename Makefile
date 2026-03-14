.PHONY: run fmt clean utop

run:
	dune exec ./bin/main.exe -- -log inputs/xensource.log -db inputs/state.xml

fmt:
	dune fmt

clean:
	dune clean

utop:
	dune utop
