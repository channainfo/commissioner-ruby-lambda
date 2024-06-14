$APP_ENV = :development if $APP_ENV.nil? || ENV['APP_ENV'].nil?

require 'bundler/setup'
Bundler.require(:default, $APP_ENV)

require 'dotenv/load' if [:development, :test].include?($APP_ENV)
require 'logger'
require 'json'