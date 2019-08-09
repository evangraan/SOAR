# Persistent::Cache

[![Gem Version](https://badge.fury.io/rb/persistent-cache-ram.png)](https://badge.fury.io/rb/persistent-cache-ram)
[![Build Status](https://travis-ci.org/evangraan/persistent-cache-ram.svg?branch=master)](https://travis-ci.org/evangraan/persistent-cache-ram)
[![Coverage Status](https://coveralls.io/repos/github/evangraan/persistent-cache-ram/badge.svg?branch=master)](https://coveralls.io/github/evangraan/persistent-cache-ram?branch=master)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/0b8fc9ae1fcb4291999679aa37ee0298)](https://www.codacy.com/app/ernst-van-graan/persistent-cache-ram?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=evangraan/persistent-cache-ram&amp;utm_campaign=Badge_Grade)

Persistent cache behaves like a hash, with a pluggable back-end. This gem only implements STORAGE_RAM, and in doing so has no dependencies such as sqlite, etc. Please see the persistent-cache gem for support for more back-ends and a comprehensive README.

## Installation

Add this line to your application's Gemfile:

    gem 'persistent-cache-ram'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install persistent-cache

## Usage

    require 'persistent-cache'

    Please see the persistent-cache gem for usage instructions. This is a STORAGE_RAM only implementation.

## Contributing

Please send feedback and comments to the authors at:

Ernst van Graan <ernst.van.graan@hetzner.co.za>

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
