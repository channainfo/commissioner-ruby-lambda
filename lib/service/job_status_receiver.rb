require_relative 'base'
require_relative 'helper/aws_client'
require_relative 'parser/cloud_watch_event'
require 'aws-sdk-mediaconvert'

module Service
  class JobStatusReceiver < Base
    include Helper::AwsClient

    delegate :options, to: :context

    def self.from_event(event)
      options = extract_cloud_watch_options_from_event(event)
      call(options: options)
    end

    def self.extract_cloud_watch_options_from_event(event)
      Service::Parser::CloudWatchEvent.call(event: event).result
    end

    # arn: 'arn:aws:mediaconvert:ap-southeast-1:636758493619:jobs/1718809546016-qkgk9n',
    # job_id: '1718809546016-qkgk9n',
    # status: 'PROGRESSING',
    # output_groups: [
    def call
      send_sqs_message
    rescue Aws::SQS::Errors::ServiceError => e
      context.fail!(message: e.message)
    end

    def sqs_message_body
      {
        message_type: :media_convert_job_status
      }.merge(options)
    end

    def send_sqs_message
      sqs_client.send_message(
        queue_url: sqs_url,
        message_body: sqs_message_body.to_json
      )
    end
  end
end
