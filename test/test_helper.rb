$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
require 'json'
require 'yaml'
require 'mocha'
require 'minitest/autorun'
require 'active_merchant'
require 'active_paypal_adaptive_payment'

ActiveMerchant::Billing::Base.mode = :test

module Minitest
  class Test
    private

    def preapproval_options
      {
        return_url: 'http://example.com/return',
        cancel_url: 'http://example.com/cancel',
        senderEmail: 'sender@example.com',
        start_date: Time.now,
        end_date: 180.days.from_now,
        currency_code: 'USD',
        max_amount: 100_00,
        maxNumberOfPayments: 10
      }
    end

    def all_fixtures
      @fixtures ||= load_fixtures
    end

    def fixtures(key)
      data = all_fixtures[key]
      fail StandardError.new("No fixture data was found for '#{key}'") unless data
      data.dup
    end

    def load_fixtures
      file = File.join(File.dirname(__FILE__), 'fixtures.yml')
      symbolize_keys(YAML.load(File.read(file)))
    end

    def symbolize_keys(hash)
      return hash unless hash.is_a?(Hash)

      hash.symbolize_keys!
      hash.each { |_, v| symbolize_keys(v) }
    end
  end
end
