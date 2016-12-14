all: website

web:
	/Volumes/SCM/git/anakeen/doc-builder/doc-builder -e $@ -s --ignore-id-errors

website:
	/Volumes/SCM/git/anakeen/doc-builder/doc-builder -e $@ -s --ignore-id-errors

clean:
	rm -Rf output
