require 'spec_helper'

describe Redismetrics do
  let :redis do
    double
  end

  let :mixin do
    Object.new.extend(described_class)
  end

  after do
    Redismetrics.instance_variable_set :@client, nil
  end

  describe '.configure' do
    it 'can be configured globally' do
      expect(redis).to receive(:ts_info)
      described_class.configure { redis }
      described_class.meter { }
    end
  end

  describe '.meter' do
    it 'yields to client object if configured' do
      described_class.configure { Redis.new }
      expect { |b| described_class.meter(&b) }.to yield_with_args(kind_of(Redismetrics::Client))
    end

    it 'yields to NULL object if not configured' do
      expect { |b| described_class.meter(&b) }.to yield_with_args(NULL)
    end
  end


  describe '#meter' do
    it 'yields to client object if configured' do
      described_class.configure { Redis.new }
      expect { |b| mixin.meter(&b) }.to yield_with_args(kind_of(Redismetrics::Client))
    end

    it 'yields to NULL object if not configured' do
      expect { |b| mixin.meter(&b) }.to yield_with_args(NULL)
    end
  end

  context 'duration' do
    before do
      described_class.configure { Redis.new }
      Redismetrics.meter do |c|
        c.destroy key: 'foo'
      end
    end

    describe '.duration' do

      it 'can measure the duration of a block' do
        described_class.duration(key: 'foo') { sleep 0.1 }
        Redismetrics.meter do |c|
          expect(c.read(key: 'foo', convert: :to_f).to_a.last.last).to be >= 0.1
        end
      end
    end

    describe '#duration' do
      it 'can measure the duration of a block' do
        mixin.duration(key: 'foo') { sleep 0.1 }
        Redismetrics.meter do |c|
          expect(c.read(key: 'foo', convert: :to_f).to_a.last.last).to be >= 0.1
        end
      end
    end
  end
end
