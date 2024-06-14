
$APP_ENV ||= ENV['APP_ENV'].to_sym unless ENV['APP_ENV'].nil?

group = :development if $APP_ENV.nil?
group = $APP_ENV if $APP_ENV == :test || $APP_ENV == :development

require 'bundler/setup'

if group.nil?
  Bundler.require(:default)
else
  Bundler.require(:default, group)
end

require 'dotenv/load' if [:development, :test].include?($APP_ENV)
require 'logger'
require 'json'