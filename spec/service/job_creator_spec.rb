require 'app_spec_helper'
require 'service/job_creator'

describe Service::JobCreator do
  let(:event) do
    dir_name = File.dirname(__dir__)
    file_path = File.join(dir_name, 'fixtures', 'media_convert', 'create_job_event.json')
    JSON.parse(File.read(file_path))
  end

  let(:bucket_output) { 'ouput-production-cm' }

  subject do
    described_class.new(
      input_s3_uri_file: 's3://production-cm/media-convert/startwar-f30-p7-q7.mp4',
      output_s3_uri_path: 's3://production-cm/media-convert-output'
    )
  end

  describe 'delegate' do
    it 'delegate to context' do
      expect(subject.input_s3_uri_file).to eq 's3://production-cm/media-convert/startwar-f30-p7-q7.mp4'
      expect(subject.output_s3_uri_path).to eq 's3://production-cm/media-convert-output'
    end
  end

  describe '.from_event' do
    it 'return options' do
      options = {
        input_s3_uri_file: 's3://production-cm/input/cohesion.mp4',
        output_s3_uri_path: "s3://#{bucket_output}/medias"
      }
      allow(ENV).to receive(:fetch).with('AWS_CONF_BUCKET_OUTPUT').and_return(bucket_output)
      allow(described_class).to receive(:extract_s3_options_from_event).and_return(options)

      expect(described_class).to receive(:call).with(**options)
      described_class.from_event(event)
    end
  end

  describe '.extract_s3_options_from_event' do
    it 'return options' do
      allow(ENV).to receive(:fetch).with('AWS_CONF_BUCKET_OUTPUT').and_return(bucket_output)
      result = described_class.extract_s3_options_from_event(event)

      expected_result = {
        input_s3_uri_file: 's3://production-cm/input/cohesion.mp4',
        output_s3_uri_path: "s3://#{bucket_output}/medias"
      }

      expect(result).to match(expected_result)
    end
  end

  describe '#selected_qualities' do
    it 'return low and medium qualities' do
      # low standard medium high
      low_and_medium = 1 + 0 + 4

      result = subject.send(:selected_qualities, low_and_medium)

      expect(result).to eq %i[low medium]
    end

    it 'return low, standard, medium and high qualities' do
      # low standard medium high
      quality = 1 + 2 + 4 + 8
      result = subject.send(:selected_qualities, quality)

      expect(result).to eq %i[low standard medium high]
    end
  end

  describe '#settings' do
    it 'return settings with inputs and output_groups' do
      subject.send(:extract_transcode_options)
      result = subject.send(:settings)

      expect(result[:inputs]).to be_a_kind_of(Array)
      expect(result[:output_groups]).to be_a_kind_of(Array)
      expect(result[:output_groups]).to have_attributes(size: 3)
    end
  end

  describe '#output_groups' do
    output_group_file = ['FileGroup']

    it 'return output_group_file if protocol is a file' do
      allow(subject).to receive(:selected_protocols).and_return(['FILE'])
      allow(subject).to receive(:output_group_file).and_return(output_group_file)

      result = subject.send(:output_groups)
      expect(result).to match([output_group_file])
    end

    it 'return output_group_file if protocol is a file, hls' do
      output_group_file = ['FileGroup']
      output_group_dash = ['DASHGroup']
      output_group_hls = ['HLSGroup']

      allow(subject).to receive(:selected_protocols).and_return(%w[FILE DASH HLS])
      allow(subject).to receive(:output_group_file).and_return(output_group_file)
      allow(subject).to receive(:output_group_dash).and_return(output_group_dash)
      allow(subject).to receive(:output_group_hls).and_return(output_group_hls)

      result = subject.send(:output_groups)
      expect(result).to match([output_group_file, output_group_dash, output_group_hls])
    end
  end

  describe '#selected_protocols' do
    it 'return low and medium qualities' do
      # file hls dash
      hls_dash = 0 + 2 + 4

      result = subject.send(:selected_protocols, hls_dash)

      expect(result).to eq %w[HLS DASH]
    end

    it 'return low, standard, medium and high qualities' do
      # file hls dash
      file_dash = 1 + 0 + 4

      result = subject.send(:selected_protocols, file_dash)

      expect(result).to eq %w[FILE DASH]
    end
  end

  describe '#extract_transcode_options' do
    subject do
      described_class.new(
        input_s3_uri_file: 's3://production-cm/media-convert/2024-08-01/startwar.-uuid-f24-p1-q3.mp4'
      )
    end

    context 'with valid input file' do
      it 'return extract transcode options correctly' do
        subject.send(:extract_transcode_options)

        segment_data = '2024-08-01'
        calculated_segment = Digest::MD5.hexdigest(segment_data)
        expected_segment = 'c09fda3b7c33e798acd103b71a6fc404'

        expect(subject.context.success?).to eq true
        expect(calculated_segment).to eq expected_segment
        expect(subject.context.segment).to eq expected_segment
        expect(subject.context.framerate).to eq 24
        expect(subject.context.protocol).to eq 1
        expect(subject.context.quality).to eq 3
      end
    end

    context 'with invalid extension' do
      subject { described_class.new(input_s3_uri_file: 's3://production-cm/media-convert/startwar.-uuid-p1-q3.avi') }

      it 'return raise error with invalid extension' do
        expect { subject.send(:extract_transcode_options) }.to raise_error Interactor::Failure
        expect(subject.context.message).to eq('invalid extension: avi, expected format mp4')
      end
    end

    context 'with invalid framerate' do
      subject { described_class.new(input_s3_uri_file: 's3://production-cm/media-convert/startwarddq3.mp4') }

      it 'return raise error with invalid framerate' do
        expect { subject.send(:extract_transcode_options) }.to raise_error Interactor::Failure
        expect(subject.context.message).to eq('invalid framerate: startwarddq3, expected format /f(24|30|60)/')
      end
    end

    context 'with invalid protocol' do
      subject { described_class.new(input_s3_uri_file: 's3://production-cm/media-convert/startwar-f30-p-q3.mp4') }

      it 'return raise error with invalid protocol' do
        expect { subject.send(:extract_transcode_options) }.to raise_error Interactor::Failure
        expect(subject.context.message).to eq('invalid protocol: p, expected format /p[1-9]/')
      end
    end

    context 'with invalid quality' do
      subject { described_class.new(input_s3_uri_file: 's3://production-cm/media-convert/startwar-f60-p1-p3a.mp4') }

      it 'return raise error with invalid quality' do
        expect { subject.send(:extract_transcode_options) }.to raise_error Interactor::Failure
        expect(subject.context.message).to eq('invalid quality: p3a for format /q[1-9]/')
      end
    end
  end

  describe '#create_job' do
    it 'return call' do
      media_convert_client = double(:media_convert_client)
      job_options = {}
      job_response = double(:job_response, job: :anything)

      result = {
        id: '5678920-02-2222',
        arn: 'arn:5678920-02-2222',
        status: 'PROCESSING',
        created_at: '2024-06-18 04:30:47 +0000'
      }

      allow(subject).to receive(:media_convert_client).and_return(media_convert_client)
      allow(subject).to receive(:job_options).and_return(job_options)
      allow(media_convert_client).to receive(:create_job).with(job_options).and_return(job_response)
      allow(subject).to receive(:job_result).with(job_response.job).and_return(result)

      subject.send(:create_job)
      expect(subject.context.result).to match(result)
    end
  end

  describe '#sqs_message_body' do
    it 'return sqs message body' do
      s3_input_file = 's3://anything'
      result = {
        id: '5678920-02-2222',
        arn: 'arn:5678920-02-2222',
        status: 'PROCESSING',
        created_at: '2024-06-18 04:30:47 +0000'
      }

      subject.context.result = result
      allow(subject).to receive(:input_s3_uri_file).and_return(s3_input_file)

      expected_result = {
        id: '5678920-02-2222',
        arn: 'arn:5678920-02-2222',
        status: 'PROCESSING',
        created_at: '2024-06-18 04:30:47 +0000',
        message_type: :media_convert_create_job,
        input_file: s3_input_file
      }

      result = subject.send(:sqs_message_body)
      expect(result).to match(expected_result)
    end
  end

  describe '#send_sqs_message' do
    context 'with manual segment' do
      it 'does not send sql message' do
        subject.context.manual_segment = true
        expect(subject.sqs_client).to_not receive(:send_message)

        subject.send(:send_sqs_message)
      end
    end

    context 'with non manual segment' do
      it 'send sqs message' do
        message_body = {}
        options = { queue_url: subject.sqs_url, message_body: message_body.to_json }
        allow(subject).to receive(:sqs_message_body).and_return(message_body)
        expect(subject.sqs_client).to receive(:send_message).with(options)

        subject.send(:send_sqs_message)
      end
    end
  end

  describe '#call' do
    it 'create job and send sqs message' do
      expect(subject).to receive(:create_job)
      expect(subject).to receive(:send_sqs_message)

      subject.send(:call)
    end
  end

  describe '#job_result' do
    it 'return job_result' do
      options = {
        id: '5678920-02-2222',
        arn: 'arn:5678920-02-2222',
        status: 'PROCESSING',
        created_at: '2024-06-18 04:30:47 +0000'
      }

      job_type = double(:job_type, **options)

      subject = described_class.new
      result = subject.send(:job_result, job_type)

      expect(result).to match(options)
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

  describe '#job_options' do
    it 'return job_options' do
      settings = {}
      arn_role = 'arn:'

      allow(subject).to receive(:arn_role).and_return(arn_role)
      allow(subject).to receive(:settings).and_return(settings)
      result = subject.send(:job_options)

      expect(result).to be_kind_of(Hash)
      expect(result).to match(role: arn_role, settings: settings)
    end
  end

  describe '#output_group_hls' do
    it 'return output_group_hls settings' do
      allow(subject).to receive(:config_output_hlses).and_return([])
      result = subject.send(:output_group_hls)
      expect(result).to be_kind_of(Hash)
      expect(result).to include(:name, :output_group_settings, :outputs)
    end
  end

  describe '#output_group_dash' do
    it 'return output_group_dash settings' do
      allow(subject).to receive(:config_output_dashs).and_return([])
      result = subject.send(:output_group_dash)

      expect(result).to be_kind_of(Hash)
      expect(result[:name]).to eq 'DASHGroup'
      expect(result).to include(:name, :output_group_settings, :outputs)
    end
  end

  describe '#video_quality_configs' do
    it 'return video_quality_configs settings' do
      result = subject.send(:video_quality_configs)

      expect(result).to be_kind_of(Hash)
      expect(result).to include(:high, :medium, :standard, :low)
    end
  end

  describe '#config_outputs' do
    it 'return config_outputs settings' do
      qualities = %i[low standard medium]
      protocol = 'HLS'
      allow(subject).to receive(:selected_qualities).and_return(qualities)

      expect(subject).to receive(:create_output).with(protocol, :low)
      expect(subject).to receive(:create_output).with(protocol, :standard)
      expect(subject).to receive(:create_output).with(protocol, :medium)

      result = subject.send(:config_outputs, protocol)

      expect(result).to be_kind_of(Array)
      expect(result.count).to eq(3)
    end
  end

  describe '#config_output_dashs' do
    it 'return config_output_dashs settings' do
      expect(subject).to receive(:config_outputs).with('DASH')
      subject.send(:config_output_dashs)
    end
  end

  describe '#config_output_hlses' do
    it 'return config_output_hlses settings' do
      expect(subject).to receive(:config_outputs).with('HLS')
      subject.send(:config_output_hlses)
    end
  end

  describe '#create_output' do
    it 'return create_output settings' do
      result = subject.send(:create_output, 'HLS', :high)
      expect(result).to include(:name_modifier, :container_settings, :video_description, :audio_descriptions)
    end
  end
end
