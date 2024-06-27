require_relative 'base'
require_relative 'helper/media_convert/config'
require_relative 'helper/media_convert/output'
require_relative 'helper/aws_client'
require_relative 'parser/s3_event'

require 'aws-sdk-mediaconvert'

module Service
  class JobCreator < Base
    include Helper::MediaConvert::Output

    include Helper::AwsClient

    delegate :input_s3_uri_file, :output_s3_uri_path, to: :context

    def self.from_event(event)
      options = extract_s3_options_from_event(event)
      call(**options)
    end

    def self.extract_s3_options_from_event(event)
      event_parser = Service::Parser::S3Event.call(event: event)
      s3_uri = event_parser.result[:s3_uri]

      # ouput-production-cm
      destination_bucket = ENV.fetch('AWS_CONF_BUCKET_OUTPUT')

      {
        input_s3_uri_file: s3_uri,
        output_s3_uri_path: "s3://#{destination_bucket}/medias"
      }
    end

    # result.job(id, arn, status, created_at) ( https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/MediaConvert/Types/Job.html )
    # input_s3_uri_file: s3://production-cm/media-convert/startwar.mp4
    # output_s3_uri_path: s3://production-cm/media-convert-output
    def call
      extract_transcode_options
      create_job
      send_sqs_message
    rescue Aws::MediaConvert::Errors::ServiceError, Aws::SQS::Errors::ServiceError => e
      context.fail!(message: e.message)
    end

    def extract_transcode_options
      result = input_s3_uri_file.split('/').last.split('.')
      file_name = result[0..-2].join('.')
      ext = result[-1].downcase

      context.fail!(message: "invalid extension: #{ext}, expected format mp4") if ext != 'mp4'

      (framerate, protocol, quality) = file_name.split('-').last(3)

      ensure_framerate(framerate)
      ensure_protocol(protocol)
      ensure_quality(quality)
    end

    def ensure_quality(quality)
      if quality.nil? || !quality.match?(/q[1-9]/)
        context.fail!(message: "invalid quality: #{quality} for format /q[1-9]/")
      end

      context.quality = quality[1..].to_i
    end

    def ensure_protocol(protocol)
      if protocol.nil? || !protocol.match?(/p[1-9]/)
        context.fail!(message: "invalid protocol: #{protocol}, expected format /p[1-9]/")
      end

      context.protocol = protocol[1..].to_i
    end

    def ensure_framerate(framerate)
      if framerate.nil? || !framerate.match?(/f(24|30|60)/)
        context.fail!(message: "invalid framerate: #{framerate}, expected format /f(24|30|60)/")
      end

      context.framerate = framerate[1..].to_i # 24/30/60
    end

    def job_result(job_type)
      {
        id: job_type.id,
        arn: job_type.arn,
        status: job_type.status,
        created_at: job_type.created_at
      }
    end

    # id: '5678920-02-2222', arn: 'arn:5678920-02-2222', status: 'PROCESSING', created_at: '2024-06-18 04:30:47 +0000'
    def create_job
      job_response = media_convert_client.create_job(job_options)
      context.result = job_result(job_response.job)
    end

    def sqs_message_body
      context.result.merge(
        message_type: :media_convert_create_job,
        input_file: input_s3_uri_file
      )
    end

    def send_sqs_message
      sqs_client.send_message(
        queue_url: sqs_url,
        message_body: sqs_message_body.to_json
      )
    end

    def output_sub_dir_name
      return @output_sub_dir_name if defined?(@output_sub_dir_name)

      file_name = input_s3_uri_file.split('/').last
      names = file_name.split('.')
      return names.first if names.count == 1

      @output_sub_dir_name = names[0..-2].join('-')
      @output_sub_dir_name
    end

    def job_options
      {
        role: arn_role,
        settings: settings
      }
    end

    def settings
      return @settings if defined?(@settings)

      @settings = {
        inputs: [
          {
            file_input: input_s3_uri_file,
            audio_selectors: {
              'Audio Selector 1' => {
                default_selection: 'DEFAULT'
              }
            },
            video_selector: {},
            timecode_source: 'ZEROBASED'
          }
        ],
        output_groups: output_groups
      }

      @settings
    end

    def selected_qualities(bitwise_protocol)
      result = []

      SUPPORTED_QUALITIES.each_with_index do |quality, index|
        quality_on = (2**index) & bitwise_protocol
        result << quality if quality_on != 0
      end

      result
    end

    def selected_protocols(bitwise_protocol)
      result = []

      SUPPORTED_PROTOCOLS.each_with_index do |protocol, index|
        protocol_on = (2**index) & bitwise_protocol
        result << protocol if protocol_on != 0
      end

      result
    end
  end
end
