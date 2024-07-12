#! /usr/bin/make
#
# Run various documentation related tasks, primarily creating images 
# from dsls.
#

C4_MODEL_FILE=ivcap.c4.dsl

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
# override when running in minikube
MNT_DIR=${ROOT_DIR}
DOT_TOUCH:=${ROOT_DIR}/dot/.built
MMD_TOUCH:=${ROOT_DIR}/svg/.mmd_built

.SUFFIXES: .dot .svg .mmd .mmd.svg

.PHONY: update clean

update: update-c4-model update-mmd update-puml
	@echo "If no data has been produced, make sure that docker can see your local directories"
	@echo "... this may require 'minikube mount ${ROOT_DIR}:/host' and 'make MNT_DIR=/host ...'"

clean:
	rm -r ${ROOT_DIR}/dot
	rm -r ${ROOT_DIR}/svg

# Create svg versions of the various C4 views in svg/
update-c4-model: ${DOT_TOUCH}
	@make -f ${ROOT_DIR}/Makefile update-dot

${DOT_TOUCH}: ${ROOT_DIR}/${C4_MODEL_FILE}
	@mkdir -p ${ROOT_DIR}/dot
	docker run -it --rm \
		-v ${MNT_DIR}:/usr/local/structurizr \
		structurizr/cli export \
		-w /usr/local/structurizr/${C4_MODEL_FILE} \
		-f dot \
		-o /usr/local/structurizr/dot 
	@touch ${DOT_TOUCH}

mmd_files := $(shell ls ${ROOT_DIR}/*.mmd 2>/dev/null)
mmd_svg_files := $(patsubst ${ROOT_DIR}/%.mmd,${ROOT_DIR}/svg/%.svg,${mmd_files})

update-mmd: ${mmd_svg_files}
	@echo "... done mermaid"

dot_gen_files := $(shell ls ${ROOT_DIR}/dot/*.dot)
dot_gen_svg_files := $(patsubst ${ROOT_DIR}/dot/%.dot,${ROOT_DIR}/svg/%.svg,${dot_gen_files})
dot_files := $(shell ls ${ROOT_DIR}/*.dot)
dot_svg_files := $(patsubst ${ROOT_DIR}/%.dot,${ROOT_DIR}/svg/%.svg,${dot_files})

update-dot: ${dot_svg_files} ${dot_gen_svg_files}
	@echo "... done dot"

puml_files := $(shell ls ${ROOT_DIR}/*.puml)
puml_svg_files := $(patsubst ${ROOT_DIR}/%.puml,${ROOT_DIR}/svg/%.svg,${puml_files})

update-puml: ${puml_svg_files}
	@echo "... done puml"

${ROOT_DIR}/svg/structurizr-%.svg: ${ROOT_DIR}/dot/structurizr-%.dot
	@echo build structurizer $@
	@mkdir -p ${ROOT_DIR}/svg
	@sed -e 's/&/&amp;/g' $< | grep -e '^  label' -v | dot -Tsvg > $@

${ROOT_DIR}/svg/%.svg: ${ROOT_DIR}/dot/%.dot
	@echo build $@
	@mkdir -p ${ROOT_DIR}/svg
	@dot -Tsvg > $@

${ROOT_DIR}/svg/%.svg: ${ROOT_DIR}/%.dot
	@echo build $@
	@mkdir -p ${ROOT_DIR}/svg
	@sed -e 's/&/&amp;/g' $< | dot -Tsvg > $@

${ROOT_DIR}/svg/%.svg: ${ROOT_DIR}/%.mmd
	@echo build $@
	@mkdir -p ${ROOT_DIR}/svg
	docker run -it --rm -v ${MNT_DIR}:/data minlag/mermaid-cli -i /data/$(shell basename $<) -o /data/svg/$(shell basename $@)

${ROOT_DIR}/svg/%.svg: ${ROOT_DIR}/%.puml
	docker run --rm -v ${MNT_DIR}:/work miy4/plantuml -tsvg -theme plain /work/$(shell basename $<) -o /work/svg 
