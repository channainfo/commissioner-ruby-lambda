require_relative '../base'

module Service
  module Parser
    class CloudWatchEvent < Base
      delegate :event, to: :context

      def call
        media_convert_info
      end

      # rubocop:disable Metrics/AbcSize
      def media_convert_info
        detail = event['detail']

        context.result = {
          arn: event['resources'][0],
          job_id: detail['jobId'],
          status: detail['status'],
          output_groups: detail['outputGroupDetails'] || []
        }

        if detail['status'] == 'ERROR'
          context.result.merge!(
            error_code: detail['errorCode'],
            error_message: detail['errorMessage']
          )
        end

        context.result
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
