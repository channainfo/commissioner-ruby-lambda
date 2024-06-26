# to run this file directly from aws lambda ruby lib/handler/create_job.handler
require_relative '../boot'
require_relative '../service/job_creator'

$logger = Logger.new($stdout)
$logger.info { "#{__FILE__} is loading" }

def create_job_handler(event:, context:)
  # Initialize logger
  $logger = Logger.new($stdout)
  $logger.info { "\n Create job with event: #{event}, context: #{context}" }

  service_context = Service::JobCreator.from_event(event)

  if service_context.success?
    { status_code: 200, body: service_context.result }
  else
    { status_code: 400, body: { error_message: service_context.message } }
  end
end
