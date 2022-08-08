require 'spec_helper'

describe Redismetrics::Client do
  let :redis do
    Redis.new(url: ENV.fetch('REDIS_URL')) # avoid flushing any running redis instances
  end

  before do
    redis.flushall
  end

  let :client do
    described_class.new(redis: redis)
  end

  describe '.new' do
    it 'can be instantiated' do
      expect(client).to be_a described_class
    end

    it 'can detect if not a redistimeseries server' do
      allow(redis).to receive(:ts_info).and_raise(
        Redis::CommandError, 'ERR unknown command bla…')
      expect { client }.to raise_error(Redis::CommandError).
        with_message('redis server has to be a redistimeseries server')
    end

    it 'raises connection errors' do
      allow(redis).to receive(:ts_info).and_raise(Redis::CannotConnectError)
      expect { client }.to raise_error(Redis::CannotConnectError)
    end
  end

  describe '#write' do
    it 'can write a metric value after a creating a new metric range' do
      expect {
        client.write(key: 'foo', value: 23)
      }.to change { client.exist?(key: 'foo') }.from(false).to(true)
      sleep 0.1
      last_value = client.read(key: 'foo').to_a.last.last
      expect(last_value).to eq('23')
    end

    it 'can write a metric value into an existing metric range' do
      client.write(key: 'foo', value: 23)
    end

    it 'can create a new metric range with the given retention time' do
      client.write(key: 'foo', value: 23, retention: 666.0)
      expect(client.retention(key: 'foo')).to eq 666.0
    end

    it 'writes new metric ranges with infinite retention time by default' do
      client.write(key: 'foo', value: 23)
      expect(client.retention(key: 'foo')).to be_infinite
    end

    it 'catches and logs command errors during writing metrics' do
      allow(client.instance_eval { @redis }).to receive(:ts_add).
        and_raise Redis::CommandError
      expect(Redismetrics).to receive(:warn).with(/Caught: Redis::CommandError/)
      expect(client.write(key: 'foo', value: 23)).to eq client
    end
  end

  describe '#retention!' do
    it 'change the retention time later' do
      client.write(key: 'foo', value: 23, retention: 666.0)
      expect { client.retention!(key: 'foo', time: 2323.0) }.to change {
        client.retention(key: 'foo')
      }.from(666.0).to(2323.0)
    end
  end

  describe '#labels!' do
    it 'change the labels later' do
      client.write(key: 'foo', value: 23, labels: {foo: 'bar'})
      expect { client.labels!(key: 'foo', labels: {bar: 'baz'}) }.to change {
        client.labels(key: 'foo').to_h
      }.from({foo: 'bar', key: 'foo'}).to({bar: 'baz',key: 'foo'})
    end
  end

  describe '#read' do
    before do
      client.write(key: 'foo', value: 23)
      sleep 0.1
      client.write(key: 'foo', value: 66.6)
      sleep 0.1
      client.write(key: 'foo', value: 42)
      sleep 0.1
    end

    it 'can return values between from and to timestamps in a metric range' do
      now = Time.now
      range = client.read(key: 'foo', from: Time.at(Time.now.to_f - 0.11))
      expect(range).to have(1).entries
      expect(range.first.last).to eq '42'
      range = client.read(
        key: 'foo',
        from: Time.at(now.to_f - 0.21),
        to: Time.at(now.to_f - 0.11),
      )
      expect(range).to have(1).entries
      expect(range.first.last).to eq '66.6'
    end

    it 'can return all entries in a metric range' do
      range = client.read(key: 'foo')
      range.map(&:first).each { |t| expect(t).to be_a Time }
      expect(range.map(&:last)).to contain_exactly('23', '66.6', '42')
    end

    it 'can apply conversion as Symbol' do
      range = client.read(key: 'foo', convert: :to_i)
      range.map(&:first).each { |t| expect(t).to be_a Time }
      expect(range.map(&:last)).to contain_exactly(23, 66, 42)
    end

    it 'can apply conversion as unary Proc' do
      range = client.read(key: 'foo', convert: -> v { Rational(v) })
      range.map(&:first).each { |t| expect(t).to be_a Time }
      expect(range.map(&:last)).to contain_exactly(23r, 666r/10, 42r)
    end

    it 'can apply conversion as binary Proc' do
      range = client.read(key: 'foo', convert: -> t, v { [ t.to_f, Rational(v) ] })
      range.map(&:first).each { |t| expect(t).to be_a Float }
      expect(range.map(&:last)).to contain_exactly(23r, 666r/10, 42r)
    end

    it 'can apply conversion that acts like a Proc' do
      c = Class.new do
        def to_proc
          -> t, v { [ t.to_f, Rational(v) ] }
        end
      end
      range = client.read(key: 'foo', convert: c.new)
      range.map(&:first).each { |t| expect(t).to be_a Float }
      expect(range.map(&:last)).to contain_exactly(23r, 666r/10, 42r)
    end

    it 'cannot apply conversion Proc with wrong arity' do
      expect {
        client.read(key: 'foo', convert: -> { :nix })
      }.to raise_error ArgumentError
    end

    it 'cannot apply unpexcted conversions' do
      expect {
        client.read(key: 'foo', convert: 'nix')
      }.to raise_error ArgumentError
    end
  end

  describe '#exist?' do
    it 'can detect if a metric already was created' do
      expect {
        client.write(key: 'foo', value: 23)
      }.to change { client.exist?(key: 'foo') }.from(false).to(true)
    end
  end

  describe '#destroy' do
    it 'can destroy an existing metric' do
      client.write(key: 'foo', value: 23)
      expect {
        client.destroy(key: 'foo')
      }.to change { client.exist?(key: 'foo') }.from(true).to(false)
    end
  end

  describe '#keys' do
    it 'returns the keys for the existing metrics' do
      expect {
        client.write(key: 'foo', value: 23)
      }.to change { client.keys }.from([]).to(%w[ foo ])
    end
  end
end
