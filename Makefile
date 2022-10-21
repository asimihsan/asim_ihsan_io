MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

docker-build:
	docker buildx build -t asim_ihsan_io .

docker-shell:
	docker run \
		--privileged \
		--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		-it asim_ihsan_io \
		/bin/bash -i

.PHONY: watch-diagrams
watch-diagrams:
	$(MAKEFILE_DIR)watch-diagrams

hugo-draft:
	 docker run \
	 	--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		-p 127.0.0.1:5000:5000/tcp \
		-it asim_ihsan_io \
		bash -i -c '/workspace/src/hugo-draft'

hugo-staging:
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

hugo-production:
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
