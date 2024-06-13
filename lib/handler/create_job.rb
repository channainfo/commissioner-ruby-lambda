require 'boot'
require 'service/job_creator'

def handler(event:, context:)

  options = {
    input_s3_uri_file: 's3://production-cm/media-convert/startwar.mp4',
    output_s3_uri_path: 's3://production-cm/media-convert-output',
    allow_hd: false,
    framerate: Service::JobCreator::FR_CINEMATIC
  }

  Service::JobCreator.call(options)


  # Initialize logger
  logger = Logger.new($stdout)

  logger.info { "Create job with event: #{event}" }

  # Process the event data here
  # event_detail = event['detail']
  # status = event_detail['status']
  # job_id = event_detail['jobId']

  # Log the status and job ID
  # puts "MediaConvert job #{job_id} has status: #{status}"

  { statusCode: 200, body: JSON.generate('Event processed successfully') }
end
