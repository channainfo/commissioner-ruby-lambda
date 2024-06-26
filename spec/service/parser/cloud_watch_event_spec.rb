require 'app_spec_helper'
require 'service/parser/cloud_watch_event'

describe Service::Parser::CloudWatchEvent do
  let(:complete_event) do
    file_path = File.join($SPEC_ROOT, 'fixtures', 'media_convert', 'cloudwatch_complete_event.json')
    JSON.parse(File.read(file_path))
  end

  let(:processing_event) do
    file_path = File.join($SPEC_ROOT, 'fixtures', 'media_convert', 'cloudwatch_processing_event.json')
    JSON.parse(File.read(file_path))
  end

  let(:error_event) do
    file_path = File.join($SPEC_ROOT, 'fixtures', 'media_convert', 'cloudwatch_error_event.json')
    JSON.parse(File.read(file_path))
  end

  describe '.call' do
    context 'with a processing event' do
      subject { described_class.new(event: processing_event) }
      it 'contains the call method ' do
        expected_result = {
          arn: 'arn:aws:mediaconvert:ap-southeast-1:636758493619:jobs/1718809546016-qkgk9n',
          job_id: '1718809546016-qkgk9n',
          status: 'PROGRESSING',
          output_groups: []
        }
        subject.call

        expect(subject.context.result).to match(expected_result)
      end
    end

    context 'with a complete event' do
      subject { described_class.new(event: complete_event) }
      it 'contains the call method ' do
        expected_result = {
          arn: 'arn:aws:mediaconvert:ap-southeast-1:636758493619:jobs/1718809546016-qkgk9n',
          job_id: '1718809546016-qkgk9n',
          status: 'COMPLETE',
          output_groups: complete_event['detail']['outputGroupDetails']
        }

        subject.call

        expect(subject.context.result[:output_groups]).to_not be_empty
        expect(subject.context.result).to match(expected_result)
      end
    end

    # rubocop:disable Layout/LineLength
    context 'with an error event' do
      subject { described_class.new(event: error_event) }
      it 'contains the call method ' do
        expected_result = {
          arn: 'arn:aws:mediaconvert:ap-southeast-1:636758493619:jobs/1718867702267-tfl96w',
          job_id: '1718867702267-tfl96w',
          status: 'ERROR',
          error_code: 1404,
          error_message: "Unable to open input file [s3://input-production-cm/medias/%E1%9E%8F%E1%9E%97%E1%9E%96%E1%9E%A2%E1%9E%99%E1%9E%80.mp4]: [Failed probe/open: [Can't read input stream: [Failed to read data: HeadObject failed]]]",
          output_groups: []
        }

        subject.call

        expect(subject.context.result).to match(expected_result)
      end
    end
    # rubocop:enable Layout/LineLength
  end
end
