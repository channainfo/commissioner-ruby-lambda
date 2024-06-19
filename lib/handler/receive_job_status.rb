# to run this file directly from aws lambda ruby lib/handler/callback.handler
require_relative '../boot'
require_relative '../service/job_status_receiver'

$logger = Logger.new($stdout)
$logger.info { "#{__FILE__} is loading" }

def receive_job_status_handler(event:, context:)
  $logger.info { "Receive job status with event: #{event}, context: #{context}" }

  service_context = Service::JobStatusReceiver.from_event(event)

  if service_context.success?
    { status_code: 200, body: {} }
  else
    { status_code: 400, body: { error_message: service_context.message } }
  end
end
