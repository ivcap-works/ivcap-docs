
API_URL=https://develop.ivcap.net
DOMAIN=docs.develop.ivcap.net

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

BUILD_TZ=Australia/Sydney

build:
	mkdocs build

deploy: ${ROOT_DIR}/${DOMAIN}.tgz
	$(eval BUILD_ART=$(shell ivcap --silent artifact create --force -n ${DOMAIN} -f ${ROOT_DIR}/${DOMAIN}.tgz))
	@echo "ArtifactID: $(BUILD_ART)"
	echo "{\
		\"\$$${}schema\": \"urn:ivcap:schema:app-server.1\",\
		\"host\": \"${DOMAIN}\",\
		\"artifact\": \"${BUILD_ART}\",\
		\"404\": \"404.html\"\
	}" | ivcap --timeout 600 aspect update urn:ivcap:app-server:${DOMAIN} -f -

serve:
	mkdocs serve

${ROOT_DIR}/${DOMAIN}.tgz: build
	cd ${ROOT_DIR}/site && tar zcf ${ROOT_DIR}/${DOMAIN}.tgz *
