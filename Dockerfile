FROM ruby:3.3.0

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR $HOME/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["./media_convert_create_job.rb"]