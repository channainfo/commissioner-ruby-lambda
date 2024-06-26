require 'app_spec_helper'
require 'handler/create_job'

describe 'file: create_job.rb' do
  describe 'function: create_job_handler' do
    let(:event) do
      file_path = File.join($SPEC_ROOT, 'fixtures', 'media_convert', 'create_job_event.json')
      JSON.parse(File.read(file_path))
    end

    it 'renders status code 200 if it has no error' do
      service_context = double(:service_context, success?: true, result: {})
      allow(Service::JobCreator).to receive(:from_event).with(event).and_return(service_context)
      response_body = create_job_handler(event: event, context: nil)

      expected_result = { status_code: 200, body: {} }
      expect(response_body).to match(expected_result)
    end

    it 'renders status code 400 if it has error' do
      error_message = 'error message'
      service_context = double(:service_context, success?: false, message: error_message)
      allow(Service::JobCreator).to receive(:from_event).with(event).and_return(service_context)
      response_body = create_job_handler(event: event, context: nil)

      expected_result = { status_code: 400, body: { error_message: error_message } }
      expect(response_body).to match(expected_result)
    end
  end
end
