require_relative 'base'
require_relative 'helper/job_creator'
require_relative 'helper/aws_client'
require_relative 'parser/s3_event'

require 'aws-sdk-mediaconvert'

module Service
  class JobCreator < Base
    include Helper::JobCreator
    include Helper::AwsClient

    delegate :input_s3_uri_file, :output_s3_uri_path, :allow_hd, :framerate, to: :context

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
        output_s3_uri_path: "s3://#{destination_bucket}/medias",
        allow_hd: false,
        framerate: Service::JobCreator::FR_CINEMATIC
      }
    end

    # result.job(id, arn, status, created_at) ( https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/MediaConvert/Types/Job.html )
    def call
      create_job
      send_sqs_message
    rescue Aws::MediaConvert::Errors::ServiceError, Aws::SQS::Errors::ServiceError => e
      context.fail!(message: e.message)
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
        output_groups: [
          output_group_dash,
          output_group_hls
        ]
      }

      @settings
    end

    def output_group_hls
      # hls config
      {
        name: 'HLSGroup',
        output_group_settings: {
          type: 'HLS_GROUP_SETTINGS',
          hls_group_settings: {
            destination: "#{output_s3_uri_path}/hls/#{output_sub_dir_name}/",
            segment_length_control: SEGMENT_LENGTH_CONTROL,
            segment_control: 'SEGMENTED_FILES',
            segment_length: SEGMENT_LENGTH,
            # in HLS, the buffering behavior is managed by the player
            # min_buffer_time: SEGMENT_LENGTH * SEGMENT_BUFFER_COUNT
            min_segment_length: MIN_SEGMENT_LENGTH
          }
        },
        outputs: config_output_hlses
      }
    end

    # protocol either: 'HLS' or DASH
    def config_outputs(protocol)
      result = []
      result << create_output(protocol, :high) if allow_hd

      result.push(
        create_output(protocol, :medium),
        create_output(protocol, :standard),
        create_output(protocol, :low)
      )
    end

    def config_output_dashs
      config_outputs('DASH')
    end

    def config_output_hlses
      config_outputs('HLS')
    end

    def output_group_dash
      # dash config
      min_buffer_time = SEGMENT_LENGTH * SEGMENT_BUFFER_COUNT * 1000
      {
        name: 'DASHGroup',
        output_group_settings: {
          type: 'DASH_ISO_GROUP_SETTINGS',
          dash_iso_group_settings: {
            destination: "#{output_s3_uri_path}/dash/#{output_sub_dir_name}/",
            segment_length_control: SEGMENT_LENGTH_CONTROL,
            segment_length: SEGMENT_LENGTH,
            segment_control: 'SEGMENTED_FILES',
            min_buffer_time: min_buffer_time,
            fragment_length: FRAGMENT_LENGTH
          }
        },
        outputs: config_output_dashs
      }
    end

    def video_qualities
      @video_qualities ||= {
        high: { resolution: '1920x1080', bitrate: 4500..6000, framerate: [24, 30, 60], audio_rate: 128 },
        medium: { resolution: '1280x720', bitrate: 2500..3500, framerate: [24, 30, 60], audio_rate: 128 },
        standard: { resolution: '854x480', bitrate: 1000..1500, framerate: [24, 30], audio_rate: 128 },
        low: { resolution: '640x360', bitrate: 500..1000, framerate: [24, 30], audio_rate: 96 },
        bottom: { resolution: '426x240', bitrate: 300..700, framerate: [24, 30], audio_rate: 64 }
      }
    end
  end
end
