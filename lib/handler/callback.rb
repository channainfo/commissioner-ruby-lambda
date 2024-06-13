require 'boot'
require 'service/job_creator'

def handler(event:, context:)
  logger = Logger.new($stdout)
  logger.info { "Callback with event: #{event}" }


  # Process the event data here
  # event_detail = event['detail']
  # status = event_detail['status']
  # job_id = event_detail['jobId']

  # Log the status and job ID
  # puts "MediaConvert job #{job_id} has status: #{status}"



  body = JSON.generate(event)
  response = { statusCode: 200, body: body}
  response
end