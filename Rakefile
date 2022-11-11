# vim: set filetype=ruby et sw=2 ts=2:

require 'gem_hadar'

GemHadar do
  name        'redismetrics'
  author      'Developers, developers, developers,…'
  email       'developers@betterplace.org'
  homepage    "https://github.com/betterplace/#{name}"
  summary     'metrics library'
  description 'This library allows you to store application metrics on a redistimeseries server'
  test_dir    'spec'
  ignore      '.*.sw[pon]', 'pkg', 'Gemfile.lock', 'coverage', '.rvmrc',
    '.AppleDouble', '.DS_Store', 'errors.lst', 'tags'

  readme      'README.md'
  title       "#{name.camelize} -- metrics library"
  licenses    << 'Apache-2.0'

  dependency             'redistimeseries'
  dependency             'tins'
  development_dependency 'rake'
  development_dependency 'simplecov'
  development_dependency 'rspec'
  development_dependency 'rspec-collection_matchers'
  development_dependency 'utils'
  development_dependency 'debug'
end

task :default => :spec
