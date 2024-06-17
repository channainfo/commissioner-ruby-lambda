# to run this file directly from aws lambda ruby lib/handler/create_job.handler
require_relative '../boot'
require_relative '../service/job_creator'

$logger = Logger.new($stdout)
$logger.info { "#{__FILE__} is loading" }

def handler(event:, context:)
  # Initialize logger
  $logger = Logger.new($stdout)
  $logger.info { "\n Create job with event: #{event}, context: #{context}" }

  Service::JobCreator.from_event(event)

  { statusCode: 200, body: JSON.generate('Event processed successfully') }
end

# Enable this to test if it can be invoked correctly
# handler(event: { job: 'tyui6789' }, context: 'create_job')
