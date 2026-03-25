%.html: %.md
	pandoc --toc -s -o $@ $<

serve:
	python3 -m http.server 8000

.PHONY: serve
