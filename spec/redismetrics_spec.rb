require 'spec_helper'

describe Redismetrics do
  let :mixin do
    Object.new.extend(described_class)
  end

  describe '.configure' do
    it 'foos'
  end

  describe '.meter' do
    it 'yields to client object if configured'

    it 'yields to NULL object if not configured' do
      expect { |b| described_class.meter(&b) }.to yield_with_args(NULL)
    end
  end


  describe '#meter' do
    it 'yields to client object if configured'

    it 'yields to NULL object if not configured' do
      expect { |b| mixin.meter(&b) }.to yield_with_args(NULL)
    end
  end

  describe '.duration' do
    it 'foos'
  end


  describe '#duration' do
    it 'foos'
  end
end
