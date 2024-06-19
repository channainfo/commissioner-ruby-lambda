require_relative 'base'
require 'httparty'
require 'json'

module Service
  class SqsProcessor < Service::Base
    delegate :payload, to: :context

    # payload: payload
    def call
      api_call
    end

    def self.extract_message_options_from_event(event)
      body_payload = event['Records'].map { |record| JSON.parse(record['body'], symbolize_names: true) }

      { payload: body_payload }
    end

    def self.process_from_event(event)
      options = extract_message_options_from_event(event)
      call(**options)
    end

    def api_call
      response = HTTParty.post(
        job_api_endpoint,
        headers: request_headers,
        body: payload.to_json
      )

      return if response.code == 200

      error_message = "status_code: #{response.code}, body: #{response.body}"
      context.fail!(message: error_message)
    end

    def request_headers
      {
        'Content-Type' => 'application/json',
        'X-Api-Key' => api_key,
        'X-Api-Name' => api_name
      }
    end

    def job_api_endpoint
      "#{host}/api/webhook/media_convert_queues"
    end

    def host
      ENV.fetch('API_CM_HOST')
    end

    def api_key
      ENV.fetch('API_CM_KEY')
    end

    def api_name
      ENV.fetch('API_CM_NAME')
    end
  end
end
