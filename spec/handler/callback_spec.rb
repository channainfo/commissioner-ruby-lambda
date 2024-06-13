require 'spec_helper'
require 'handler/callback'

describe 'handler' do
  describe 'callback' do
    handler(event: {status: 'COMPLETE', media: 'xyz' }, context: 'Hello')
  end
end