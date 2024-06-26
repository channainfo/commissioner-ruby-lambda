# to run this file directly from aws lambda ruby lib/handler/callback.handler
require_relative '../boot'
require_relative '../service/sqs_processor'

$logger = Logger.new($stdout)
$logger.info { "#{__FILE__} is loading" }

def process_sqs_handler(event:, context:)
  $logger.info { "ProcessSQS with event: #{event}, context: #{context}" }

  sqs_processor_context = Service::SqsProcessor.process_from_event(event)

  raise sqs_processor_context.message unless sqs_processor_context.success?

  { status_code: 200, body: {} }
end
