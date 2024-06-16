require_relative 'base'

module Service
  class S3EventParser < Base
    delegate :event, to: :context

    def call
      s3_object_info
    end

    # rubocop:disable Metrics/AbcSize
    def s3_object_info
      record = event['Records'][0]
      {
        s3_uri: "s3://#{record['s3']['bucket']['name']}/#{record['s3']['object']['key']}",
        bucket_name: record['s3']['bucket']['name'],
        size: record['s3']['object']['size'],
        object_key: record['s3']['object']['key'],
        etag: record['s3']['object']['eTag'],
        event_time: record['eventTime']
      }
    end
    # rubocop:enable Metrics/AbcSize
  end
end
