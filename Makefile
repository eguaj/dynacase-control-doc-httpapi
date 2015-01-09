all: website

web:
	/Volumes/SCM/git/anakeen/doc-builder/doc-builder -e $@ -s

website:
	/Volumes/SCM/git/anakeen/doc-builder/doc-builder -e $@ -s

clean:
	rm -Rf output
