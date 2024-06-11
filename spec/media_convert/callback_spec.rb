require 'spec_helper'
require 'media_convert/callback'

describe 'LambdaFunction: media_convert.callback#handler' do
  describe 'handler' do
    it 'handler' do
      handler(event: {status: 'COMPLETE', media: 'xyz' }, context: 'Hello')
    end
  end
end