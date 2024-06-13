require 'app_spec_helper'
require 'service/s3_event_parser'

describe Service::S3EventParser do
  let(:event) do
    dir_name = File.dirname(__dir__)
    file_path = File.join(dir_name, 'fixtures', 'media_convert', 'create_job_event.json') 
    JSON.parse(File.read(file_path))
  end

  describe '.call' do
    subject { described_class.new(event: event) }

    it 'contains the call method' do

      expected_result = {
        :s3_uri=>"s3://production-cm/input/cohesion.mp4",
        :bucket_name=>"production-cm",
        :size=>9432978,
        :object_key=>"input/cohesion.mp4",
        :etag=>"c1ad3716ee5ed6b639d8218289d11f7e",
        :event_time=>"2024-06-11T02:58:20.153Z"
      }
      expect(subject.call).to match(expected_result)
    end
  end
end