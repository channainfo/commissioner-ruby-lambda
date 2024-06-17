require 'app_spec_helper'
require 'handler/create_job'

describe 'handler' do
  describe 'create_job' do
    let(:event) do
      dir_name = File.dirname(__dir__)
      file_path = File.join(dir_name, 'fixtures', 'media_convert', 'create_job_event.json')
      JSON.parse(File.read(file_path))
    end

    it 'handles create job correctly' do
      allow(Service::JobCreator).to receive(:from_event).with(event)
      handler(event: event, context: 'create_job')
    end
  end
end
