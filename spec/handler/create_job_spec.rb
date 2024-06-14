require 'app_spec_helper'
require 'handler/create_job'

describe 'handler' do
  describe 'create_job' do
    handler(event: {job: 'tyui6789'}, context: 'create_job')
  end
end