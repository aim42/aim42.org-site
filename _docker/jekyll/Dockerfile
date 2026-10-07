FROM ruby:3.3

RUN gem install bundler:2.5.23

WORKDIR /site
COPY Gemfile Gemfile.lock ./
RUN bundle _2.5.23_ config set path /usr/local/bundle \
    && bundle _2.5.23_ install --jobs 4 --retry 3

# The repo is bind-mounted over /site at runtime; the gems live outside it.
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4242", "--force_polling"]
