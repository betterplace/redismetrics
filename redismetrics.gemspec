# -*- encoding: utf-8 -*-
# stub: redismetrics 0.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "redismetrics".freeze
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Developers, developers, developers,\u2026".freeze]
  s.date = "2021-05-27"
  s.description = "This library allows you to store application metrics on a redistimeseries server".freeze
  s.email = "developers@betterplace.org".freeze
  s.extra_rdoc_files = ["README.md".freeze, "lib/redismetrics.rb".freeze, "lib/redismetrics/client.rb".freeze, "lib/redismetrics/local_redis_refinement.rb".freeze, "lib/redismetrics/version.rb".freeze]
  s.files = [".envrc".freeze, ".gitignore".freeze, ".semaphore/semaphore.yml".freeze, ".utilsrc".freeze, "Gemfile".freeze, "README.md".freeze, "Rakefile".freeze, "VERSION".freeze, "docker-compose.yml".freeze, "lib/redismetrics.rb".freeze, "lib/redismetrics/client.rb".freeze, "lib/redismetrics/local_redis_refinement.rb".freeze, "lib/redismetrics/version.rb".freeze, "redismetrics.gemspec".freeze, "spec/client_spec.rb".freeze, "spec/redismetrics_spec.rb".freeze, "spec/spec_helper.rb".freeze]
  s.homepage = "https://github.com/betterplace/redismetrics".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rdoc_options = ["--title".freeze, "Redismetrics -- metrics library".freeze, "--main".freeze, "README.md".freeze]
  s.rubygems_version = "3.2.15".freeze
  s.summary = "metrics library".freeze
  s.test_files = ["spec/client_spec.rb".freeze, "spec/redismetrics_spec.rb".freeze, "spec/spec_helper.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<gem_hadar>.freeze, ["~> 1.11.0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec-collection_matchers>.freeze, [">= 0"])
    s.add_development_dependency(%q<utils>.freeze, [">= 0"])
    s.add_development_dependency(%q<byebug>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<redistimeseries>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<tins>.freeze, [">= 0"])
  else
    s.add_dependency(%q<gem_hadar>.freeze, ["~> 1.11.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-collection_matchers>.freeze, [">= 0"])
    s.add_dependency(%q<utils>.freeze, [">= 0"])
    s.add_dependency(%q<byebug>.freeze, [">= 0"])
    s.add_dependency(%q<redistimeseries>.freeze, [">= 0"])
    s.add_dependency(%q<tins>.freeze, [">= 0"])
  end
end
