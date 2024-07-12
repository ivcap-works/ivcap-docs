# CIP Documentation

This directory holds various documentation related artifacts. Currently those are primarily `code-first` diagrams visualising various aspects of the service.

A `make update` will create or update SVG files in the `svg` directory from the various visualisation related files. Currently supported formats are:

* [C4](https://www.c4model.org/): `*.c4.dsl`
  * Restricted to a single file `C4_MODEL_FILE=cip.c4.dsl` as define in [Makefile](./Makefile)
* [PlantUML](https://plantuml.com/): `*.puml`
* [Graphviz](https://graphviz.org/): `*.dot`
* [Mermaid](https://mermaid-js.github.io/mermaid/#/): `*.mmd`

Note, some of the conversation steps are performed via a docker container which may lead to a long run time, the first time `make update` is performed if the relevant docker images need to be downloaded first.
