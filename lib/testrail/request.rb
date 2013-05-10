require 'httparty'
require 'testrail/command_helper'

module Testrail
  class Request
    extend Testrail::CommandHelper
    include HTTParty

    base_uri Testrail.config.server
    format :json

    def self.get(*args)
      request(:get, *args)
    end

    def self.post(*args)
      request(:post, *args)
    end

    private

    def self.request(method, *args)
      command, ids, opts = parse_args(*args)
      url = build_url(command, ids)
      attempts = 0
      begin
        attempts += 1
        response = Testrail::Response.new(HTTParty.send(method, url, opts))
      rescue TimeoutError => error
        retry if attempts < 3
        unless Testrail.logger.nil?
          Testrail.logger.error "Timeout connecting to #{method.to_s.upcase} #{url}"
          Testrail.logger.error error
        end
        raise error
      rescue Exception => error
        unless Testrail.logger.nil?
          Testrail.logger.error "Unexpected exception intercepted calling TestRail"
          Testrail.logger.error error
        end
        raise error
      end
      response
    end

    def self.parse_args(*args)
      opts = args.last.instance_of?(Hash) ? args.pop : {}
      opts[:headers] = opts[:headers] ? Testrail.config.headers.merge(opts[:headers]) : Testrail.config.headers
      command = args.shift
      ids = args.empty? ? nil : args
      [command, ids, opts]
    end
  end
end
