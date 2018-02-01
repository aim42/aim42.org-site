ROM jekyll/jekyll:3.6

COPY Gemfile .
COPY Gemfile.lock .

RUN bundle install
WORKDIR /srv/jekyll
EXPOSE 4000
