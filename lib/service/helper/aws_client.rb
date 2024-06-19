module Service
  module Helper
    module AwsClient
      def sqs_client
        @sqs_client ||= Aws::SQS::Client.new(client_options)
      end

      def media_convert_client
        @media_convert_client ||= Aws::MediaConvert::Client.new(client_options)
      end

      def client_options
        {
          access_key_id: ENV.fetch('AWS_CONF_ACCESS_KEY_ID'),
          secret_access_key: ENV.fetch('AWS_CONF_SECRET_ACCESS_KEY'),
          region: ENV.fetch('AWS_CONF_REGION')
        }
      end

      def sqs_url
        ENV.fetch('AWS_SQS_QUEUE_URL')
      end

      def arn_role
        # 'arn:aws:iam::123456789012:role/MediaConvert_Default_Role'
        ENV.fetch('AWS_CONF_MEDIA_CONVERT_ROLE')
      end
    end
  end
end
