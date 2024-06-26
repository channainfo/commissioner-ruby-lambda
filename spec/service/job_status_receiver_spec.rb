require 'app_spec_helper'
require 'service/job_status_receiver'

describe Service::JobStatusReceiver do
  let(:event) do
    file_path = File.join($SPEC_ROOT, 'fixtures', 'media_convert', 'cloudwatch_complete_event.json')
    JSON.parse(File.read(file_path))
  end

  let(:output_groups) { event['detail']['outputGroupDetails'] }

  let(:options) do
    {
      arn: 'arn:aws:mediaconvert:ap-southeast-1:636758493619:jobs/1718809546016-qkgk9n',
      job_id: '1718809546016-qkgk9n',
      status: 'COMPLETE',
      output_groups: output_groups
    }
  end

  subject do
    described_class.new(options: options)
  end

  describe 'delegate' do
    it 'delegate to context' do
      expect(subject.options).to eq options
    end
  end

  describe '.from_event' do
    it 'return options' do
      allow(described_class).to receive(:extract_cloud_watch_options_from_event).and_return(options)

      expect(described_class).to receive(:call).with(options: options)
      described_class.from_event(event)
    end
  end

  describe '.extract_cloud_watch_options_from_event' do
    it 'return options' do
      expected_result = {
        arn: 'arn:aws:mediaconvert:ap-southeast-1:636758493619:jobs/1718809546016-qkgk9n',
        job_id: '1718809546016-qkgk9n',
        status: 'COMPLETE',
        output_groups: output_groups
      }

      result = described_class.extract_cloud_watch_options_from_event(event)
      expect(result).to match(expected_result)
    end
  end

  describe '#sqs_message_body' do
    it 'return sqs message body' do
      expected_result = {
        message_type: :media_convert_job_status,
        arn: 'arn:aws:mediaconvert:ap-southeast-1:636758493619:jobs/1718809546016-qkgk9n',
        job_id: '1718809546016-qkgk9n',
        status: 'COMPLETE',
        output_groups: output_groups
      }

      result = subject.send(:sqs_message_body)
      expect(result).to match(expected_result)
    end
  end

  describe '#send_sqs_message' do
    it 'send sqs message' do
      message_body = {}
      options = { queue_url: subject.sqs_url, message_body: message_body.to_json }
      allow(subject).to receive(:sqs_message_body).and_return(message_body)
      expect(subject.sqs_client).to receive(:send_message).with(options)
      subject.send(:send_sqs_message)
    end
  end

  describe '#call' do
    it 'create job and send sqs message' do
      expect(subject).to receive(:send_sqs_message)

      subject.send(:call)
    end
  end

  describe '#media_convert_client' do
    it 'return media_convert_client' do
      expect(subject.media_convert_client).to be_kind_of(Aws::MediaConvert::Client)
    end
  end

  describe '#sqs_client' do
    it 'return sqs_client' do
      expect(subject.sqs_client).to be_kind_of(Aws::SQS::Client)
    end
  end

  describe '#client_options' do
    it 'return the client_options' do
      ENV['AWS_CONF_ACCESS_KEY_ID'] = 'mykey'
      ENV['AWS_CONF_SECRET_ACCESS_KEY'] = 'my_secret'
      ENV['AWS_CONF_REGION'] = 'ap-southeast-1'

      expected_options = { access_key_id: 'mykey', secret_access_key: 'my_secret', region: 'ap-southeast-1' }
      expect(subject.client_options).to match(expected_options)
    end
  end
end
