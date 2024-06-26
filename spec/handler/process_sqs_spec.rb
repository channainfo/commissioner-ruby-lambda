require 'app_spec_helper'
require 'handler/process_sqs'

describe 'file: process_sqs' do
  describe 'function: process_sqs' do
    let(:event) do
      dir_name = File.dirname(__dir__)
      file_path = File.join(dir_name, 'fixtures', 'sqs', 'create_job_event.json')
      JSON.parse(File.read(file_path))
    end

    it 'renders status code 200 if it has no error' do
      service_context = double(:service_context, success?: true)
      allow(Service::SqsProcessor).to receive(:process_from_event).with(event).and_return(service_context)
      response_body = process_sqs_handler(event: event, context: nil)

      expected_result = { status_code: 200, body: {} }
      expect(response_body).to match(expected_result)
    end

    it 'raise error if it fails' do
      error_message = 'error message'

      service_context = double(:service_context, success?: false, message: error_message)
      allow(Service::SqsProcessor).to receive(:process_from_event).with(event).and_return(service_context)

      expect { process_sqs_handler(event: event, context: nil) }.to raise_error
    end
  end
end
