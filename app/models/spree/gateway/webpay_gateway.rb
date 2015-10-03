class Spree::Gateway::WebpayGateway < Spree::Gateway
  preference :login, :string
 
  def provider_class
    ActiveMerchant::Billing::WebpayGateway
  end
 
  def authorize(money, creditcard, gateway_options)
    provider.authorize(money * 100, creditcard, gateway_options)
  end
end
