# to run this file directly from aws lambda ruby lib/handler/create_job.handler
require_relative '../boot'
require_relative '../service/job_creator'
require_relative '../service/s3_event_parser'

$logger = Logger.new($stdout)
$logger.info { "#{__FILE__} is loading" }

def handler(event:, context:)
  # Initialize logger
  $logger = Logger.new($stdout)
  $logger.info { "\n Create job with event: #{event}, context: #{context}" }

  job_settings = {
    input_s3_uri_file: 's3://production-cm/input/cohesion.mp4',
    output_s3_uri_path: 's3://production-cm/media-convert-output',
    allow_hd: false,
    framerate: 24
  }
  # job_settings = extract_job_settings(event)

  $logger.info { "\n job_settings: #{job_settings}" }

  # Service::JobCreator.call(**job_settings)

  { statusCode: 200, body: JSON.generate('Event processed successfully') }
end

def extract_job_settings(event)
  event_parser = Service::S3EventParser.call(event: event)
  s3_uri = event_parser.result[:s3_uri]
  bucket_name = event_parser.result[:bucket_name]

  $logger.info { "\n event: #{event_parser.result}" }
  $logger.info { "\n s3_input: #{s3_uri}" }

  {
    input_s3_uri_file: s3_uri,
    output_s3_uri_path: "s3://#{bucket_name}/media-convert-output",
    allow_hd: false,
    framerate: Service::JobCreator::FR_CINEMATIC
  }
end

# Enable this to test if it can be invoked correctly
handler(event: { job: 'tyui6789' }, context: 'create_job')
