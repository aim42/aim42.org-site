FROM jekyll/jekyll:3.6

COPY Gemfile .

RUN bundle install

WORKDIR /srv/jekyll
EXPOSE 4000
