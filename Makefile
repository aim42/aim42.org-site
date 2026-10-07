# Local development and checks run in Docker; no local Ruby needed.
SITE_PORT ?= 4242
RUN = docker compose run --rm --no-deps jekyll

.PHONY: help build lock dev down clean site-test validate unit check

help:
	@printf "make build      build the Jekyll image (rerun after Gemfile.lock changes)\n"
	@printf "make lock       regenerate Gemfile.lock inside Docker (after editing Gemfile)\n"
	@printf "make dev        serve the site on http://localhost:$(SITE_PORT)\n"
	@printf "make down       stop the dev container\n"
	@printf "make clean      remove containers, cache volumes and _site\n"
	@printf "make site-test  build the site and run tests/site_test.rb\n"

build:
	docker compose build jekyll

lock:
	docker run --rm -v "$(CURDIR):/site" -w /site ruby:3.3 sh -c \
	  "gem install bundler:2.5.23 && bundle _2.5.23_ lock --add-platform aarch64-linux x86_64-linux"

dev:
	@printf "==> open http://localhost:$(SITE_PORT)\n"
	docker compose up jekyll

down:
	docker compose down

clean:
	docker compose down --volumes 2>/dev/null || true
	rm -rf _site

site-test:
	$(RUN) sh -c "bundle exec jekyll build --quiet && bundle exec ruby tests/site_test.rb"

validate:
	$(RUN) ruby tools/validate.rb

unit:
	$(RUN) bundle exec ruby tests/validate_test.rb

check: validate unit site-test
