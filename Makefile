MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
AWS_PROFILE := retail-admin
AWS_COMMAND := aws-vault exec $(AWS_PROFILE) --region us-west-2 --
AWS_DOCKER_RUN := $(AWS_COMMAND) docker run \
	-e LOCK_TABLE_NAME \
	-e AWS_REGION \
	-e AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY \
	-e AWS_SESSION_TOKEN

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

watch-diagrams:
	$(MAKEFILE_DIR)watch-diagrams

hugo-draft:
	 docker run \
	 	--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		-p 127.0.0.1:5000:5000/tcp \
		-it asim_ihsan_io \
		bash -i -c '/workspace/src/hugo-draft'

hugo-staging: init-aws-s3-sync
	 $(AWS_DOCKER_RUN) \
	 	--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		-it asim_ihsan_io \
		bash -i -c '/workspace/src/hugo-staging'

hugo-staging-local: init-aws-s3-sync
	$(AWS_COMMAND) $(MAKEFILE_DIR)src/hugo-staging

s3-cf-upload-invalidate-staging:
	 $(AWS_DOCKER_RUN) \
	 	--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		-it asim_ihsan_io \
		bash -i -c '/workspace/src/s3-cf-upload-invalidate-staging'

hugo-production: init-aws-s3-sync
	 $(AWS_DOCKER_RUN) \
	 	--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		-it asim_ihsan_io \
		bash -i -c '/workspace/src/hugo-production'

hugo-production-local: init-aws-s3-sync
	$(AWS_COMMAND) $(MAKEFILE_DIR)src/hugo-production

hugo-production-build-only:
	./src/hugo-production-build-only

generate-critical:
	./src/generate-critical.sh

generate-critical-production:
	./src/generate-critical.sh --production

s3-cf-upload-invalidate-production:
	 $(AWS_DOCKER_RUN) \
	 	--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		-it asim_ihsan_io \
		bash -i -c '/workspace/src/s3-cf-upload-invalidate-production'

cdk-bootstrap:
	cd cdk && $(AWS_COMMAND) cdk bootstrap

# TODO FIXME temporary until I publish this
init-aws-s3-sync:
	cd $(HOME)/workplace/aws-s3-sync && go install
