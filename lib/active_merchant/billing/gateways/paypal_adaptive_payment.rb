require 'active_merchant/billing/gateways/paypal/paypal_common_api'
require 'active_merchant/billing/gateways/paypal_adaptive_payments/adaptive_payment_response'

module ActiveMerchant
  module Billing

    class PaypalAdaptivePayment < Gateway
      include PaypalCommonAPI

      class_attribute :test_redirect_url
      class_attribute :live_redirect_url
      class_attribute :test_redirect_pre_approval_url
      class_attribute :live_redirect_pre_approval_url

      TEST_URL = 'https://svcs.sandbox.paypal.com/AdaptivePayments/'
      LIVE_URL = 'https://svcs.paypal.com/AdaptivePayments/'

      EMBEDDED_FLOW_TEST_URL = 'https://www.sandbox.paypal.com/webapps/adaptivepayment/flow/pay'
      EMBEDDED_FLOW_LIVE_URL = 'https://www.paypal.com/webapps/adaptivepayment/flow/pay'

      self.test_redirect_url= "https://www.sandbox.paypal.com/webscr?cmd=_ap-payment&paykey="
      self.test_redirect_pre_approval_url= "https://www.sandbox.paypal.com/webscr?cmd=_ap-preapproval&preapprovalkey="
      self.live_redirect_url = 'https://www.paypal.com/webscr?cmd=_ap-payment&paykey='
      self.live_redirect_pre_approval_url = 'https://www.paypal.com/webscr?cmd=_ap-preapproval&preapprovalkey='
      self.supported_countries = ['US']
      self.homepage_url = 'http://x.com/'
      self.display_name = 'Paypal Adaptive Payments'

      def initialize(options = {})
        requires!(options, :appid, :login, :password, :signature)

        @app_id = options[:appid]
        @login = options[:login]
        @password = options[:password]
        @signature = options[:signature]

        super
      end

      # @param [Hash] options
      # @option options [String] :action_type
      # @option options [String] :cancel_url
      # @option options [String] :currency_code
      # @option options [String] :custom
      # @option options [String] :error_language
      # @option options [String] :fees_payer
      # @option options [String] :ipn_notification_url
      # @option options [String] :memo
      # @option options [String] :pin
      # @option options [String] :preapproval_key
      # @option options [Enumerable] :receiver_list
      # @option options [String] :return_url
      # @option options [String] :reverse_all_parallel_payments_on_error
      # @option options [String] :sender_email
      # @option options [String] :tracking_id
      #
      # @option receiver_list [String, Integer] :amount
      # @option receiver_list [String] :email
      # @option receiver_list [String] :invoice_id
      # @option receiver_list [String] :payment_type
      # @option receiver_list [String] :primary
      def setup_purchase(options)
        requires!(options, :cancel_url, :receiver_list, :return_url)

        commit('Pay', build_adaptive_payment_pay_request(options))
      end

      # @param [Hash] options
      # @option options [String] :error_language
      # @option options [String] :pay_key
      # @option options [String] :transaction_id
      def details_for_payment(options)
        commit('PaymentDetails', build_adaptive_payment_details_request(options))
      end

      # @param [Hash] options
      # @option options [String] :error_language
      # @option options [String] :pay_key
      def get_shipping_addresses(options)
        requires!(options, :pay_key)

        commit('GetShippingAddresses', build_adaptive_get_shipping_addresses_request(options))
      end

      # @param [Hash] options
      # @option options [String] :error_language
      # @option options [String] :pay_key
      def get_payment_options(options)
        requires!(options, :pay_key)

        commit('GetPaymentOptions', build_adaptive_get_payment_options_request(options))
      end

      # @param [Hash] options
      # @option options [Hash] :display_options
      # @option options [String] :error_language
      # @option options [Enumerable] :receiver_options
      # @option options [Hash] :sender
      #
      # @option display_options [String] :business_name
      # @option display_options [String] :email_header_image_url
      # @option display_options [String] :email_marketing_image_url
      # @option display_options [String] :header_image_url
      #
      # @option receiver_options [String] :description
      # @option receiver_options [String] :custom_id
      # @option receiver_options [Hash] :invoice_data
      # @option receiver_options [Hash] :receiver
      # @option receiver_options [String] :referrer_code
      #
      # @option sender [String] :referrerCode
      # @option sender [String] :require_shipping_address_selection
      # @option sender [String] :share_address
      # @option sender [String] :share_phone_number
      #
      # @option invoice_data [Enumerable] :item
      # @option invoice_data [Integer, String] :total_tax
      # @option invoice_data [Integer, String] :total_shipping
      #
      # @option item [String] :identifier
      # @option item [String] :item_price
      # @option item [String] :item_count
      # @option item [String] :name
      # @option item [String] :price
      #
      # @option receiver [String] :email
      # @option receiver [Hash] :phone
      #
      # @option phone [Integer, String] :country_code
      # @option phone [Integer, String] :phone_number
      # @option phone [Integer, String] :extension
      def set_payment_options(options)
        requires!(options, :pay_key)

        commit('SetPaymentOptions', build_adaptive_set_payment_options_request(options))
      end

      # @param [Hash] options
      # @option options [String] :currency_code
      # @option options [String] :error_language
      # @option options [String] :fees_payer
      # @option options [String] :pay_key
      # @option options [Enumerable] :receiver_list
      # @option options [String] :transaction_id
      #
      # @option receiver_list [String, Integer] :amount
      # @option receiver_list [String] :email
      # @option receiver_list [String] :primary
      def refund(options)
        requires!(options, :receiver_list)
        options[:receiver_list].each do |receiver|
          requires!(receiver, :amount, :email)
        end

        commit('Refund', build_adaptive_refund_details(options))
      end

      # @param [Hash] options
      # @option options [String] :error_language
      # @option options [String] :funding_plan_id
      # @option options [String] :pay_key
      def execute_payment(options)
        commit('ExecutePayment', build_adaptive_execute_payment_request(options))
      end

      # @param [Hash] options
      # @option options [String] :cancel_url
      # @option options [String] :currency_code
      # @option options [String] :displayMaxTotalAmount
      # @option options [DateTime] :end_date
      # @option options [String] :error_language
      # @option options [String] :max_amount
      # @option options [String] :maxAmountPerPayment
      # @option options [String] :maxNumberOfPayments
      # @option options [String] :memo
      # @option options [String] :notify_url
      # @option options [String] :return_url
      # @option options [String] :senderEmail
      # @option options [DateTime] :start_date
      def preapprove_payment(options)
        requires!(options, :cancel_url, :end_date, :max_amount, :return_url)

        commit('Preapproval', build_preapproval_payment(options))
      end

      # @param [Hash] options
      # @option options [String] :error_language
      # @option options [String] :preapproval_key
      def cancel_preapproval(options)
        requires!(options, :preapproval_key)

        commit('CancelPreapproval', build_cancel_preapproval(options))
      end

      # @param [Hash] options
      # @option options [String] :error_language
      # @option options [String] :get_billing_address
      # @option options [String] :preapproval_key
      def preapproval_details_for(options)
        requires!(options, :preapproval_key)

        commit('PreapprovalDetails', build_preapproval_details(options))
      end

      # TODO: to_currencies should be an array instead of a hash.
      #
      # @param [Hash] options
      # @option options [String] :error_language
      # @option options [Hash] :currency_list
      # @option options [Hash] :to_currencies
      #
      # @option currency_list [Integer] :amount
      # @option currency_list [String] :code
      def convert_currency(options)
        requires!(options, :currency_list, :to_currencies)
        options[:currency_list].each do |currency|
          requires!(currency, :amount, :code)
        end

        commit('ConvertCurrency', build_currency_conversion(options))
      end

      def embedded_flow_url
        test? ? EMBEDDED_FLOW_TEST_URL : EMBEDDED_FLOW_LIVE_URL
      end

      def embedded_flow_url_for(token)
        "#{embedded_flow_url}?paykey=#{token}"
      end

      def redirect_url
        test? ? test_redirect_url : live_redirect_url
      end

      # TODO: validate the token presence
      def redirect_url_for(token)
        "#{redirect_url}#{token}"
      end

      def redirect_pre_approval_url
        test? ? test_redirect_pre_approval_url : live_redirect_pre_approval_url
      end

      def redirect_pre_approval_url_for(token)
        "#{redirect_pre_approval_url}#{token}"
      end

      private

      def build_adaptive_payment_pay_request(opts)
        @xml = ''
        xml = Builder::XmlMarkup.new :target => @xml, :indent => 2
        xml.instruct!
        xml.PayRequest do |x|
          x.requestEnvelope do |x|
            x.detailLevel 'ReturnAll'
            x.errorLanguage opts[:error_language] ||= 'en_US'
          end
          x.actionType opts[:action_type] ||= 'PAY'
          x.preapprovalKey opts[:preapproval_key] if opts.key?(:preapproval_key)
          x.senderEmail opts[:sender_email] if opts.key?(:sender_email)
          x.cancelUrl opts[:cancel_url]
          x.returnUrl opts[:return_url]
          x.ipnNotificationUrl opts[:ipn_notification_url] if opts[:ipn_notification_url]
          x.memo opts[:memo] if opts.key?(:memo)
          x.custom opts[:custom] if opts.key?(:custom)
          x.feesPayer opts[:fees_payer] if opts[:fees_payer]
          x.pin opts[:pin] if opts[:pin]
          x.currencyCode opts[:currency_code] ||= 'USD'
          x.receiverList do |x|
            opts[:receiver_list].each do |receiver|
              x.receiver do |x|
                x.email receiver[:email]
                x.amount receiver[:amount].to_s
                x.primary receiver[:primary] if receiver.key?(:primary)
                x.paymentType receiver[:payment_type] if receiver.key?(:payment_type)
                x.invoiceId receiver[:invoice_id] if receiver.key?(:invoice_id)
              end
            end
          end
          x.reverseAllParallelPaymentsOnError(
            opts[:reverse_all_parallel_payments_on_error] || 'false'
          )
          x.trackingId opts[:tracking_id] if opts[:tracking_id]
        end
      end

      def build_adaptive_execute_payment_request(opts)
        @xml = ''
        xml = Builder::XmlMarkup.new :target => @xml, :indent => 2
        xml.instruct!
        xml.ExecutePaymentRequest do |x|
          x.requestEnvelope do |x|
            x.detailLevel 'ReturnAll'
            x.errorLanguage opts[:error_language] ||= 'en_US'
          end
          x.payKey opts[:pay_key] if opts.key?(:pay_key)
          x.fundingPlanId opts[:funding_plan_id] if opts[:funding_plan_id]
        end
      end

      def build_adaptive_payment_details_request(opts)
        @xml = ''
        xml = Builder::XmlMarkup.new :target => @xml, :indent => 2
        xml.instruct!
        xml.PayRequest do |x|
          x.requestEnvelope do |x|
            x.detailLevel 'ReturnAll'
            x.errorLanguage opts[:error_language] ||= 'en_US'
          end
          if opts[:pay_key].present?
            x.payKey opts[:pay_key]
          elsif opts[:transaction_id].present?
            x.payKey opts[:transaction_id]
          end
        end
      end

      def build_adaptive_get_shipping_addresses_request(opts)
        @xml = ''
        xml = Builder::XmlMarkup.new :target => @xml, :indent => 2
        xml.instruct!
        xml.GetShippingAddressesRequest do |x|
          x.requestEnvelope do |x|
            x.detailLevel 'ReturnAll'
            x.errorLanguage opts[:error_language] ||= 'en_US'
          end
          x.key opts[:pay_key]
        end
      end

      def build_adaptive_get_payment_options_request(opts)
        @xml = ''
        xml = Builder::XmlMarkup.new :target => @xml, :indent => 2
        xml.instruct!
        xml.GetPaymentOptionsRequest do |x|
          x.requestEnvelope do |x|
            x.detailLevel 'ReturnAll'
            x.errorLanguage opts[:error_language] ||= 'en_US'
          end
          x.payKey opts[:pay_key]
        end
      end

      def build_adaptive_set_payment_options_request(opts)
        opts[:sender] ||= {}

        @xml = ''
        xml = Builder::XmlMarkup.new :target => @xml, :indent => 2
        xml.instruct!
        xml.SetPaymentOptionsRequest do |x|
          x.requestEnvelope do |x|
            x.detailLevel 'ReturnAll'
            x.errorLanguage opts[:error_language] ||= 'en_US'
          end
          x.senderOptions do |x|
            x.shareAddress opts[:sender][:share_address] if opts[:sender][:share_address]
            x.sharePhoneNumber opts[:sender][:share_phone_number] if opts[:sender][:share_phone_number]
            x.requireShippingAddressSelection opts[:sender][:require_shipping_address_selection] if opts[:sender][:require_shipping_address_selection]
            x.referrerCode opts[:sender][:referrerCode] if opts[:sender][:referrerCode]
          end
          unless opts[:display_options].blank?
            x.displayOptions do |x|
              x.emailHeaderImageUrl opts[:display_options][:email_header_image_url] if opts[:display_options][:email_header_image_url]
              x.emailMarketingImageUrl opts[:display_options][:email_marketing_image_url] if opts[:display_options][:email_marketing_image_url]
              x.headerImageUrl opts[:display_options][:header_image_url] if opts[:display_options][:header_image_url]
              x.businessName opts[:display_options][:business_name] if opts[:display_options][:business_name]
            end
          end
          opts[:receiver_options].try(:each) do |receiver_options|
            x.receiverOptions do |x|
              x.description receiver_options[:description] if receiver_options[:description]
              x.customId receiver_options[:custom_id] if receiver_options[:custom_id]
              unless receiver_options[:invoice_data].blank?
                x.invoiceData do |x|
                  receiver_options[:invoice_data][:item].try(:each) do |item|
                    x.item do |x|
                      x.name item[:name] if item[:name]
                      x.identifier item[:identifier] if item[:identifier]
                      x.price item[:price] if item[:price]
                      x.itemPrice item[:item_price] if item[:item_price]
                      x.itemCount item[:item_count] if item[:item_count]
                    end
                  end
                  x.totalTax receiver_options[:invoice_data][:total_tax] if receiver_options[:invoice_data][:total_tax]
                  x.totalShipping receiver_options[:invoice_data][:total_shipping] if receiver_options[:invoice_data][:total_shipping]
                end
              end
              x.receiver do |x|
                x.email receiver_options[:receiver][:email] if receiver_options[:receiver][:email]
                unless receiver_options[:receiver][:phone].blank?
                  x.phone do |x|
                    x.countryCode receiver_options[:receiver][:phone][:country_code]
                    x.phoneNumber receiver_options[:receiver][:phone][:phone_number]
                    x.extension receiver_options[:receiver][:phone][:extension] if receiver_options[:receiver][:phone][:extension]
                  end
                end
              end
              x.referrerCode receiver_options[:referrer_code] if receiver_options[:referrer_code]
            end
          end
          x.payKey opts[:pay_key]
        end
      end

      def build_adaptive_refund_details(options)
        @xml = ''
        xml = Builder::XmlMarkup.new :target => @xml, :indent => 2
        xml.instruct!
        xml.RefundRequest do |x|
          x.requestEnvelope do |x|
            x.detailLevel 'ReturnAll'
            x.errorLanguage options[:error_language] ||= 'en_US'
          end
          x.actionType 'REFUND'
          x.payKey options[:pay_key] if options[:pay_key]
          x.payKey options[:transaction_id] if options[:transaction_id]
          x.trackingId options[:tracking_id] if options[:tracking_id]
          x.currencyCode options[:currency_code] ||= 'USD'
          x.receiverList do |x|
            options[:receiver_list].each do |receiver|
              x.receiver do |x|
                x.amount receiver[:amount]
                # x.paymentType receiver[:payment_type] ||= 'GOODS' # API specifies "not used"
                # x.invoiceId receiver[:invoice_id] if receiver[:invoice_id] # API specifies "not used"
                x.email receiver[:email]
                x.primary receiver[:primary] if receiver.key?(:primary)
              end
            end
          end if options[:receiver_list]
          x.feesPayer options[:fees_payer] ||= 'EACHRECEIVER'
        end
      end

      def build_preapproval_payment(options)
        opts = {
          :currency_code => "USD",
          :start_date => DateTime.current
        }.update(options)

        @xml = ''
        xml = Builder::XmlMarkup.new :target => @xml, :indent => 2
        xml.instruct!
        xml.PreapprovalRequest do |x|
          # request envelope
          x.requestEnvelope do |x|
            x.detailLevel 'ReturnAll'
            x.errorLanguage opts[:error_language] ||= 'en_US'
            x.senderEmail opts[:senderEmail] if opts.has_key?(:senderEmail)
          end

          # required preapproval fields
          x.endingDate opts[:end_date].strftime("%Y-%m-%dT%H:%M:%S")
          x.startingDate opts[:start_date].strftime("%Y-%m-%dT%H:%M:%S")
          x.maxTotalAmountOfAllPayments opts[:max_amount]
          x.maxAmountPerPayment opts[:maxAmountPerPayment] if opts.has_key?(:maxAmountPerPayment)
          x.memo opts[:memo] if opts.has_key?(:memo)
          x.maxNumberOfPayments opts[:maxNumberOfPayments] if opts.has_key?(:maxNumberOfPayments)
          x.currencyCode options[:currency_code]
          x.cancelUrl opts[:cancel_url]
          x.returnUrl opts[:return_url]
          x.displayMaxTotalAmount opts[:displayMaxTotalAmount] if opts.has_key?(:displayMaxTotalAmount)

          # notify url
          x.ipnNotificationUrl opts[:notify_url] if opts.has_key?(:notify_url)
        end
      end

      def build_preapproval_details(options)
        @xml = ''
        xml = Builder::XmlMarkup.new :target => @xml, :indent => 2
        xml.instruct!
        xml.PreapprovalDetailsRequest do |x|
          x.requestEnvelope do |x|
            x.detailLevel 'ReturnAll'
            x.errorLanguage options[:error_language] ||= 'en_US'
          end
          x.preapprovalKey options[:preapproval_key]
          x.getBillingAddress options[:get_billing_address] if options[:get_billing_address]
        end
      end

      def build_cancel_preapproval(options)
        @xml = ''
        xml = Builder::XmlMarkup.new :target => @xml, :indent => 2
        xml.instruct!
        xml.PreapprovalDetailsRequest do |x|
          x.requestEnvelope do |x|
            x.detailLevel 'ReturnAll'
            x.errorLanguage options[:error_language] ||= 'en_US'
          end
          x.preapprovalKey options[:preapproval_key]
        end
      end

      def build_currency_conversion(options)
        @xml = ''
        xml = Builder::XmlMarkup.new :target => @xml, :indent => 2
        xml.instruct!
        xml.ConvertCurrencyRequest do |x|
          x.requestEnvelope do |x|
            x.detailLevel 'ReturnAll'
            x.errorLanguage options[:error_language] ||= 'en_US'
          end
          x.baseAmountList do |x|
            options[:currency_list].each do |currency|
              x.currency do |x|
                x.amount currency[:amount]
                x.code currency[:code]
              end
            end
          end
          x.convertToCurrencyList do |x|
            options[:to_currencies].each do |k,v|
              x.currencyCode "#{v}"
            end
          end
        end
      end

      def action_url(action)
        URI.parse(endpoint_url + action)
      end

      def api_request(action, params = nil, options = {})
        raw_response = response = nil
        begin
          raw_response = ssl_post(action_url(action), params, headers(options))
          response = parse(raw_response)
        rescue ResponseError => error
          raw_response = error.response.body
          response = parse(raw_response)
        rescue JSON::ParserError
          response = raw_response
        end

        response
      end

      def authorization_from(response)
        response[:pay_key] || super
      end

      def build_response(success, message, response, options = {})
        AdaptivePaymentResponse.new(success, message, response, options)
      end

      def commit(action, data, options = {})
        response = api_request(action, data, headers(options))

        build_response(
          successful?(response),
          message_from(response),
          response,
          test: test?,
          authorization: authorization_from(response)
        )
      end

      def endpoint_url
        test? ? TEST_URL : LIVE_URL
      end

      def headers(options = {})
        headers = {
          'Content-Type'                  => 'text/xml',
          'X-PAYPAL-APPLICATION-ID'       => @app_id,
          'X-PAYPAL-REQUEST-DATA-FORMAT'  => 'XML',
          'X-PAYPAL-RESPONSE-DATA-FORMAT' => 'JSON',
          'X-PAYPAL-SECURITY-USERID'      => @login,
          'X-PAYPAL-SECURITY-PASSWORD'    => @password,
          'X-PAYPAL-SECURITY-SIGNATURE'   => @signature
        }
        headers.merge(options.slice(:appid, :login, :password, :signature))
      end

      def message_from(response)
        return response[:response_envelope][:ack] unless response.key?(:error)

        response[:error].first[:message]
      end

      def parse(response)
        response = JSON.parse(response)
        response = Hash[response.map { |k, v| [k.underscore, v] }]
        response = response.with_indifferent_access
      end

      def successful?(response)
        SUCCESS_CODES.include?(response[:response_envelope][:ack])
      end

      def test?
        @options[:test] || Base.gateway_mode == :test
      end
    end
  end
end
