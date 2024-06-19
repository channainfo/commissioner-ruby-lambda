require 'app_spec_helper'
require 'service/sqs_processor'

describe Service::SqsProcessor do
  let(:payload) do
    [{
      id: '1234-5678-9012',
      arn: '1234-5678-9012',
      status: 'created',
      input_file: 's3://production-cm/media-convert/startwar.mp4',
      message_type: 'media_convert_create_job'
    }]
  end

  let(:event) do
    dir_name = File.dirname(__dir__)
    file_path = File.join(dir_name, 'fixtures', 'sqs', 'create_job_event.json')
    JSON.parse(File.read(file_path))
  end

  let(:host) { 'https://aws-api.bookme.plus' }

  subject do
    described_class.new(
      payload: payload
    )
  end

  describe 'delegate' do
    it 'delegate to context' do
      expect(subject.payload).to eq payload
    end
  end

  describe '.process_from_event' do
    it 'return options' do
      options = { payload: [] }
      allow(described_class).to receive(:extract_message_options_from_event).and_return(options)
      expect(described_class).to receive(:call).with(**options)

      described_class.process_from_event(event)
    end
  end

  describe '.extract_message_options_from_event' do
    it 'return options' do
      result = described_class.extract_message_options_from_event(event)
      expected_result = { payload: payload }
      expect(result).to eq(expected_result)
    end
  end

  describe '#call' do
    it 'return call' do
      expect(subject).to receive(:api_call)
      subject.call
    end
  end

  # TODO: use vcr to api
  describe '#api_call' do
    context 'request successfully' do
      it 'return success' do
        response = double(:response, code: 200)
        api_endpoint = subject.send(:job_api_endpoint)
        headers = subject.send(:request_headers)
        body = subject.send(:payload).to_json

        allow(HTTParty).to receive(:post).with(api_endpoint, headers: headers, body: body).and_return(response)
        subject.send(:api_call)

        expect(subject.context.success?).to eq true
      end
    end

    context 'request error' do
      it 'return failure with message' do
        body = 'invalid input'
        response = double(:response, code: 400, body: body)
        error_message = "status_code: 400, body: #{body}"

        api_endpoint = subject.send(:job_api_endpoint)
        headers = subject.send(:request_headers)
        body = subject.send(:payload).to_json

        allow(HTTParty).to receive(:post).with(api_endpoint, headers: headers, body: body).and_return(response)
        expect { subject.send(:api_call) }.to raise_error Interactor::Failure

        expect(subject.context.success?).to eq false
        expect(subject.context.message).to eq error_message
      end
    end
  end

  describe '#request_headers' do
    it 'return headers' do
      api_key = 'mykey'
      api_name = 'myname'

      expected_result = {
        'Content-Type' => 'application/json',
        'X-Api-Key' => api_key,
        'X-Api-Name' => api_name
      }
      allow(ENV).to receive(:fetch).with('API_CM_KEY').and_return(api_key)
      allow(ENV).to receive(:fetch).with('API_CM_NAME').and_return(api_name)

      result = subject.send(:request_headers)

      expect(result).to match(expected_result)
    end
  end

  describe '#host' do
    it 'return API_CM_HOST from env' do
      allow(ENV).to receive(:fetch).with('API_CM_HOST').and_return(host)

      result = subject.send(:host)
      expect(result).to eq host
    end
  end

  describe '#job_api_endpoint' do
    it 'return a job endpoint' do
      allow(subject).to receive(:host).and_return(host)

      result = subject.send(:job_api_endpoint)
      expect(result).to eq 'https://aws-api.bookme.plus/api/webhook/media_convert_queues'
    end
  end
end
