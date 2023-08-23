require 'spec_helper'

describe Redismetrics do
  let :redis do
    double(ping: "PONG")
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

    it 'yields to NULL object if server unavailable' do
      described_class.configure { Redis.new }
      allow_any_instance_of(Redis).to receive(:ping).and_return nil
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

    it 'attempts to reconnect if connection was lost' do
      described_class.configure { Redis.new }
      client = described_class.instance_variable_get(:@client)
      expect(client.instance_variable_get(:@redis)).to receive(:ping).
          and_raise Redis::CannotConnectError
      expect { |b| mixin.meter(&b) }.to yield_with_args(kind_of(Redismetrics::Client))
    end

    it 'attempts to reconnect repeatedly after a while if connection was lost' do
      Time.dummy(Time.parse('2011-11-11 11:11:11')) do
        described_class.configure { Redis.new }
        client = described_class.instance_variable_get(:@client)
        expect(client.instance_variable_get(:@redis)).to receive(:ping).
          and_raise Redis::CannotConnectError
        allow(Redismetrics).to receive(:reconnect).once.and_return nil
        expect { |b| mixin.meter(&b) }.to yield_with_args(NULL)
      end
      Time.dummy(Time.parse('2011-11-11 11:11:42')) do
        allow(Redismetrics).to receive(:reconnect).and_call_original
        expect { |b| mixin.meter(&b) }.to yield_with_args(kind_of(Redismetrics::Client))
      end
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

      it 'stores the maximum duration of multiple conflicting blocks' do
        now = Time.now
        mixin.duration(key: 'foo', timestamp: now) { sleep 0.1 }
        mixin.duration(key: 'foo', timestamp: now) { sleep 0.3 }
        mixin.duration(key: 'foo', timestamp: now) { sleep 0.1 }
        Redismetrics.meter do |c|
          expect(c.read(key: 'foo').count).to eq 1
          value = c.read(key: 'foo', convert: :to_f).to_a.last.last
          expect(value).to be >= 0.3
          expect(value).to be < 3.1
        end
      end
    end
  end

  context 'count' do
    before do
      described_class.configure { Redis.new }
      Redismetrics.meter do |c|
        c.destroy key: 'foo'
      end
    end

    describe '.count' do
      it 'can the count the execution a block' do
        described_class.count(key: 'foo') {}
        Redismetrics.meter do |c|
          expect(c.read(key: 'foo', convert: :to_f).to_a.last.last).to eq 1
        end
      end
    end

    describe '#count' do
      it 'can measure the count of a block' do
        mixin.count(key: 'foo') {}
        Redismetrics.meter do |c|
          expect(c.read(key: 'foo', convert: :to_f).to_a.last.last).to eq 1
        end
      end

      it 'can sum the counts of two conflicting blocks' do
        now = Time.now
        mixin.count(key: 'foo', timestamp: now) {}
        mixin.count(key: 'foo', timestamp: now) {}
        Redismetrics.meter do |c|
          expect(c.read(key: 'foo').count).to eq 1
          expect(c.read(key: 'foo', convert: :to_f).to_a.last.last).to eq 2
        end
      end
    end

  end
end
