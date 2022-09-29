MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

docker-build:
	docker build -t asim_ihsan_io .

hugo-draft:
	 docker run \
	 	--volume "$(MAKEFILE_DIR):/workspace" \
		--workdir /workspace \
		-p 127.0.0.1:5000:5000/tcp \
		-it asim_ihsan_io \
		bash -c '(cd /workspace/hugo && \
			hugo --buildDrafts \
			--destination build \
			--watch server \
			--disableFastRender \
			--bind 0.0.0.0 \
			--baseURL "http://127.0.0.1" \
			--enableGitInfo \
			--port 5000)'
