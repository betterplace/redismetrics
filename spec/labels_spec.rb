require 'spec_helper'

describe Redismetrics::Labels do
  let :label1a do
    described_class.new(foo: 'bar', 'bar' => 'baz')
  end

  let :label1b do
    described_class.new(bar: 'baz', 'foo' => 'bar')
  end

  let :label2 do
    described_class.new(bar: 'baz', 'foo' => 'ba2')
  end

  it 'can be empty' do
    expect(described_class.new).to be_empty
  end

  it 'can be created from spec' do
    expect(label1a).to be_a described_class
  end

  it 'can be modified later on' do
    expect { label1a[:quux] = 'blub' }.to change { label1a.to_a }.
      from( [[:bar, "baz"], [:foo, "bar"]] ).
      to(   [[:bar, "baz"], [:foo, "bar"], [:quux, "blub"]] )
  end

  it 'can be equal' do
    expect(label1a).to eq label1a
  end

  it 'is equal independent of ordering' do
    expect(label1a).to eq label1b
  end

  it 'can be different' do
    expect(label1a).not_to eq label2
  end

  it 'is hash like' do
    expect(label1a.to_hash).to be_a Hash
  end

  it 'is displayed like a hash' do
    expect(label1a.to_s).to eq '{:foo=>"bar", :bar=>"baz"}'
  end
end
