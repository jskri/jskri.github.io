SRC             := $(wildcard src/posts/*.md)
POSTS           := $(patsubst src/posts/%.md, dist/posts/%.html, $(SRC))
ASSETS          := dist/assets
TEMPLATE_INDEX  := templates/index.html
TEMPLATE_ABOUT  := templates/about.html
TEMPLATE_POST   := templates/post.html
METADATA_SITE   := metadata/site.yaml
SCRIPT_FIGURE   := assets/scripts/figure_to_img.lua
SCRIPT_EQUATION := assets/scripts/equation_to_tex.lua

.PHONY: all clean

all: $(POSTS) dist/index.html dist/about.html $(ASSETS)

dist/posts/%.html: src/posts/%.md $(TEMPLATE_POST) $(METADATA_SITE) $(SCRIPT_FIGURE) $(SCRIPT_EQUATION)
	# --filter pandoc-katex
	# --css /assets/katex/katex.min.css
	# -M classoption=fleqn
	mkdir -p dist/posts
	pandoc $< \
		--toc --toc-depth=3 --standalone --katex --template=$(TEMPLATE_POST) \
		--metadata-file $(METADATA_SITE) \
		--lua-filter=$(SCRIPT_FIGURE) \
		--lua-filter=$(SCRIPT_EQUATION) \
		-o $@

dist/index.html: $(TEMPLATE_INDEX) $(METADATA_SITE)
	mkdir -p dist
	pandoc /dev/null \
		--template $(TEMPLATE_INDEX) \
		--metadata-file $(METADATA_SITE) \
		-o $@

dist/about.html: src/about.md $(TEMPLATE_ABOUT)
	mkdir -p dist
	pandoc $< \
		--template $(TEMPLATE_ABOUT) \
		--metadata-file $(METADATA_SITE) \
		-o $@

$(ASSETS): assets/
	mkdir -p dist
	cp -r assets dist/

clean:
	rm -rf dist/

###############################################################################
# entity-protocol.html: entity-protocol.md template_post.html styles_post.css figure_to_img.lua equation_to_tex.lua metadata.yaml
# 	# --filter pandoc-katex
# 	pandoc --toc --standalone --katex --template=template_post.html \
#     --metadata-file metadata.yaml \
# 		--lua-filter=figure_to_img.lua \
# 		--lua-filter=equation_to_tex.lua \
# 		--css "assets/katex/katex.min.css" \
# 		-o $@ \
# 		$<
# 
# index.html: template_index.html metadata.yaml styles_index.css
# 	pandoc --template template_index.html \
#   	--metadata-file metadata.yaml \
#     -o $@ \
#     /dev/null
# 
# about.html: about.md template_about.html metadata.yaml styles_about.css
# 	pandoc --toc --standalone --template=template_about.html \
#   	--metadata-file metadata.yaml \
#     -o $@ \
# 		$<
# 
# serve:
# 	python3 -m http.server 8000
# 
# .PHONY: serve

