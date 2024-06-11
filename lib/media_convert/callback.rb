require 'bundler/setup'

require 'json'
require 'logger'

# Initialize logger
$logger = Logger.new($stdout)

def handler(event:, context:)
  p "Received event: #{event}"
  $logger.info("Lambda function media_convert_callback called with event: #{event}")

  # Process the event data here
  # event_detail = event['detail']
  # status = event_detail['status']
  # job_id = event_detail['jobId']

  # Log the status and job ID
  # puts "MediaConvert job #{job_id} has status: #{status}"

  { statusCode: 200, body: JSON.generate('Event processed successfully') }
end