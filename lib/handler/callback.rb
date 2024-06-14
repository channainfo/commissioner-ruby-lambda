# to run this file directly from aws lambda ruby lib/handler/callback.handler
require_relative '../boot'
require_relative '../service/job_creator'

def handler(event:, context:)
  logger = Logger.new($stdout)
  logger.info { "Callback with event: #{event}" }

  body = JSON.generate(event)
  response = { statusCode: 200, body: body}
  response
end

# Enable this to test if it can be invoked correctly
# handler(event: {status: 'COMPLETE', media: 'xyz' }, context: 'Hello')

