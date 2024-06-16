require 'app_spec_helper'
require 'service/base'

describe Service::Base do
  describe '.call' do
    subject { Service::Base.new(name: 'base') }
    it 'contains the call method' do
      expect { subject.call }.to_not raise_error
    end

    it 'contains the call method' do
      context = subject.context
      expect(context.name).to eq 'base'
    end
  end
end
