.PHONY: all web website dot clean

all: website

web: dot
	/Volumes/SCM/git/anakeen/doc-builder/doc-builder -e $@ -s --ignore-id-errors

website: dot
	/Volumes/SCM/git/anakeen/doc-builder/doc-builder -e $@ -s --ignore-id-errors

%.png: %.dot
	dot -Tpng -o"$@" "$<"

dot: Contents/images/transactions-states.png

clean:
	rm -Rf output
