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
      input_s3_uri_file: 's3://production-cm/media-convert/startwar.mp4',
      output_s3_uri_path: 's3://production-cm/media-convert-output',
      allow_hd: false,
      framerate: described_class::FR_CINEMATIC
    )
  end

  describe 'delegate' do
    it 'delegate to context' do
      expect(subject.input_s3_uri_file).to eq 's3://production-cm/media-convert/startwar.mp4'
      expect(subject.output_s3_uri_path).to eq 's3://production-cm/media-convert-output'
      expect(subject.allow_hd).to eq false
      expect(subject.framerate).to eq described_class::FR_CINEMATIC
    end
  end

  describe '.from_event' do
    it 'return options' do
      options = {
        allow_hd: false,
        framerate: 24,
        input_s3_uri_file: 's3://production-cm/input/cohesion.mp4',
        output_s3_uri_path: "s3://#{bucket_output}/medias"
      }
      allow(ENV).to receive(:fetch).with('AWS_CONF_BUCKET_OUTPUT').and_return(bucket_output)
      allow(described_class).to receive(:extract_job_settings).and_return(options)

      expect(described_class).to receive(:call).with(**options)
      described_class.from_event(event)
    end
  end

  describe '.extract_job_settings' do
    it 'return options' do
      allow(ENV).to receive(:fetch).with('AWS_CONF_BUCKET_OUTPUT').and_return(bucket_output)
      result = described_class.extract_job_settings(event)

      expected_result = {
        allow_hd: false,
        framerate: 24,
        input_s3_uri_file: 's3://production-cm/input/cohesion.mp4',
        output_s3_uri_path: "s3://#{bucket_output}/medias"
      }

      expect(result).to match(expected_result)
    end
  end

  describe '#call' do
    it 'return call' do
      client = double(:media_convert_client)
      job_options = { some_settings: {} }

      allow(subject).to receive(:client).and_return(client)
      allow(subject).to receive(:job_options).and_return(job_options)

      expect(client).to receive(:create_job).with(job_options)

      subject.call
    end
  end

  describe '#client' do
    it 'return client' do
      expect(subject.client).to be_kind_of(Aws::MediaConvert::Client)
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
      result = subject.send(:job_options)
      expect(result).to be_kind_of(Hash)
      expect(result).to include(:role, :settings)
    end
  end

  describe '#settings' do
    it 'return settins' do
      result = subject.send(:settings)
      expect(result).to be_kind_of(Hash)
      expect(result).to include(:inputs, :output_groups)
    end
  end

  describe '#output_group_hls' do
    it 'return output_group_hls settings' do
      result = subject.send(:output_group_hls)
      expect(result).to be_kind_of(Hash)
      expect(result).to include(:name, :output_group_settings, :outputs)
    end
  end

  describe '#output_group_dash' do
    it 'return output_group_dash settings' do
      result = subject.send(:output_group_dash)

      expect(result).to be_kind_of(Hash)
      expect(result[:name]).to eq 'DASHGroup'
      expect(result).to include(:name, :output_group_settings, :outputs)
    end
  end

  describe '#video_qualities' do
    it 'return video_qualities settings' do
      result = subject.send(:video_qualities)

      expect(result).to be_kind_of(Hash)
      expect(result).to include(:high, :medium, :standard, :low)
    end
  end

  describe '#config_outputs' do
    it 'return config_outputs settings with high quality included if allow_hd is true' do
      allow(subject).to receive(:allow_hd).and_return(true)

      result = subject.send(:config_outputs, 'HLS')

      expect(result).to be_kind_of(Array)
      expect(result.count).to eq(4)
    end

    it 'return config_outputs settings without high quality included if allow_hd is false' do
      allow(subject).to receive(:allow_hd).and_return(false)

      result = subject.send(:config_outputs, 'HLS')

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
