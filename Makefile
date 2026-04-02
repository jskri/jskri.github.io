SRC                := $(wildcard src/posts/*.md)
POSTS              := $(patsubst src/posts/%.md, dist/posts/%.html, $(SRC))
ASSETS             := dist/assets
TEMPLATE_INDEX     := templates/index.html
TEMPLATE_ABOUT     := templates/about.html
TEMPLATE_POST      := templates/post.html
TEMPLATE_META      := templates/meta.html
TEMPLATE_TOPHEADER := templates/topheader.html
CSS_INDEX   		   := templates/index.css
CSS_ABOUT   		   := templates/about.css
CSS_POST    		   := templates/post.css
METADATA_SITE      := metadata/site.yaml
SCRIPT_FIGURE      := assets/scripts/figure_to_img.lua
SCRIPT_EQUATION    := assets/scripts/equation_to_tex.lua

.PHONY: all clean

all: $(POSTS) dist/index.html dist/about.html dist/sitemap.xml dist/robots.txt $(ASSETS)

dist/posts/%.html: src/posts/%.md $(TEMPLATE_POST) $(CSS_POST) $(TEMPLATE_META) $(TEMPLATE_TOPHEADER) $(METADATA_SITE) $(SCRIPT_FIGURE) $(SCRIPT_EQUATION)
	mkdir -p dist/posts
	pandoc $< \
		--toc --toc-depth=2 --standalone --katex=/assets/katex/ --template=$(TEMPLATE_POST) \
		--metadata-file $(METADATA_SITE) \
		--metadata=url:"$(patsubst dist/%,/%,$@)" \
		--lua-filter=$(SCRIPT_FIGURE) \
		--lua-filter=$(SCRIPT_EQUATION) \
		-o $@

dist/index.html: $(TEMPLATE_INDEX) $(CSS_INDEX) $(TEMPLATE_META) $(TEMPLATE_TOPHEADER) $(METADATA_SITE)
	mkdir -p dist
	pandoc /dev/null \
		--template $(TEMPLATE_INDEX) \
		--metadata-file $(METADATA_SITE) \
		--metadata=url:"$(patsubst dist/%,/%,$@)" \
		-o $@

dist/about.html: src/about.md $(TEMPLATE_ABOUT) $(CSS_ABOUT) $(TEMPLATE_META) $(TEMPLATE_TOPHEADER)
	mkdir -p dist
	pandoc $< \
		--template $(TEMPLATE_ABOUT) \
		--metadata-file $(METADATA_SITE) \
		--metadata=url:"$(patsubst dist/%,/%,$@)" \
		-o $@

dist/sitemap.xml: templates/sitemap.xml $(METADATA_SITE)
	mkdir -p dist
	pandoc /dev/null \
	  --template $< \
	  --metadata-file $(METADATA_SITE) \
	  -t plain \
	  -o $@

dist/robots.txt: robots.txt
	mkdir -p dist
	cp $< $@

$(ASSETS): assets/
	mkdir -p dist
	cp -r assets dist/

clean:
	rm -rf dist/
