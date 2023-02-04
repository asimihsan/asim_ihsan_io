MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

docker-build:
	docker buildx build -t asim_ihsan_io .

docker-build-clean:
	docker buildx build --no-cache -t asim_ihsan_io .

docker-shell:
	docker run \
		--privileged \
		--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		-it asim_ihsan_io \
		/bin/bash -i

generate-critical:
	rm -f $(MAKEFILE_DIR)hugo/layouts/partials/critical-css.html
	echo "<style>" >> $(MAKEFILE_DIR)hugo/layouts/partials/critical-css.html
	cat $(MAKEFILE_DIR)hugo/build/index.html | critical --base $(MAKEFILE_DIR)hugo/build >> $(MAKEFILE_DIR)hugo/layouts/partials/critical-css.html
	echo "</style>" >> $(MAKEFILE_DIR)hugo/layouts/partials/critical-css.html

watch-diagrams:
	$(MAKEFILE_DIR)watch-diagrams

hugo-draft:
	 docker run \
	 	--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		-p 127.0.0.1:5000:5000/tcp \
		-it asim_ihsan_io \
		bash -i -c '/workspace/src/hugo-draft'

hugo-staging: generate-critical
	 docker run \
	 	--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		--env-file $(HOME)/.aws_retail_docker \
		-it asim_ihsan_io \
		bash -i -c '/workspace/src/hugo-staging'

s3-cf-upload-invalidate-staging:
	 docker run \
	 	--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		--env-file $(HOME)/.aws_retail_docker \
		-it asim_ihsan_io \
		bash -i -c '/workspace/src/s3-cf-upload-invalidate-staging'

hugo-production: generate-critical
	 docker run \
	 	--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		--env-file $(HOME)/.aws_retail_docker \
		-it asim_ihsan_io \
		bash -i -c '/workspace/src/hugo-production'

s3-cf-upload-invalidate-production:
	 docker run \
	 	--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		--env-file $(HOME)/.aws_retail_docker \
		-it asim_ihsan_io \
		bash -i -c '/workspace/src/s3-cf-upload-invalidate-production'
