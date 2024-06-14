FROM ruby:3.2.0

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

# config necessary env ( docker-compose or aws ecs environment variables)
ENV AWS_ACCESS_KEY_ID ""
ENV AWS_SECRET_ACCESS_KEY ""
ENV AWS_REGION "ap-southeast-1"
ENV AWS_BUCKET_NAME ""
ENV AWS_MEDIA_CONVERT_ROLE ""
ENV AWS_MEDIA_CONVERT_TOPIC ""

WORKDIR $HOME/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["ruby", "./lib/handler/create_job.rb"]