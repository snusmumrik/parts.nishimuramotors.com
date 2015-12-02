# -*- coding: utf-8 -*-
Deface::Override.new(:virtual_path => "spree/order_mailer/confirm_email",
                     :name => "replace_dear_customer",
                     :replace => "code[erb-loud]:contains('order_mailer.confirm_email.dear_customer')",
                     :text => "<%= @order.bill_address.lastname %> <%= @order.bill_address.firstname %> 様"
                     )

Deface::Override.new(:virtual_path => "spree/order_mailer/confirm_email",
                     :name => "replace_subtotal",
                     :replace => "code[erb-loud]:contains('order_mailer.confirm_email.subtotal')",
                     :text => "<%= t('order_mailer.confirm_email.subtotal') %> <%= @order.display_item_total %>"
                     )

Deface::Override.new(:virtual_path => "spree/order_mailer/confirm_email",
                     :name => "replace_total",
                     :replace => "code[erb-loud]:contains('order_mailer.confirm_email.total')",
                     :text => "<%= t('order_mailer.confirm_email.total') %> <%= @order.display_total %>"
                     )

Deface::Override.new(:virtual_path => "spree/order_mailer/confirm_email",
                     :name => "replace_thanks",
                     :replace => "code[erb-loud]:contains('order_mailer.confirm_email.thanks')",
                     :text => "
<%= t('order_mailer.confirm_email.thanks') %>

ニシムラモータース
900-0005
沖縄県那覇市天久794-6 1F
http://nishimuramotors.com"
                     )
