require 'json'

module ActiveMerchant
  module Billing
    class AdaptivePaymentResponse < Response
      def status
        params[:payment_exec_status]
      end
    end
  end
end
