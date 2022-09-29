MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

docker-build:
	docker build -t asim_ihsan_io .

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
