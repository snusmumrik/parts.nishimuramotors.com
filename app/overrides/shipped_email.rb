# -*- coding: utf-8 -*-
Deface::Override.new(:virtual_path => "spree/shipment_mailer/shipped_email",
                     :name => "replace_dear_customer",
                     :replace => "code[erb-loud]:contains('shipment_mailer.shipped_email.dear_customer')",
                     :text => "<%= @shipment.order.bill_address.lastname %> <%= @shipment.order.bill_address.firstname %> 様"
                     )


Deface::Override.new(:virtual_path => "spree/shipment_mailer/shipped_email",
                     :name => "replace_thanks",
                     :replace => "code[erb-loud]:contains('shipment_mailer.shipped_email.thanks')",
                     :text => "
<%= t('shipment_mailer.shipped_email.thanks') %>

ニシムラモータース
900-0005
沖縄県那覇市天久794-6 1F
http://nishimuramotors.com"
                     )
