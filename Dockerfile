FROM jekyll/builder

LABEL version="0.5.0"
LABEL description="develop and generate aim42.org site"
LABEL vendor="aim42 (Gernot Starke)"

COPY Gemfile .

RUN apk update && \
    bundle install

WORKDIR /srv/jekyll
EXPOSE 4000
