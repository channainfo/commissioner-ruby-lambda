# to run this file directly from aws lambda ruby lib/handler/callback.handler
require_relative '../boot'
require_relative '../service/job_creator'

$logger = Logger.new($stdout)
$logger.info { "#{__FILE__} is loading" }

def handler(event:, context:)
  $logger.info { "Callback with event: #{event}, context: #{context}" }

  body = JSON.generate(event)
  { statusCode: 200, body: body }
end

# Enable this to test if it can be invoked correctly
# handler(event: {status: 'COMPLETE', media: 'xyz' }, context: 'Hello')
