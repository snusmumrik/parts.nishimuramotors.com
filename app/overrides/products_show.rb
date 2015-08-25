# -*- coding: utf-8 -*-
Deface::Override.new(:virtual_path => "spree/products/show",
                     :name => "translate_recently_viewed_products",
                     :replace => "#recently_viewed h3.product-section-title",
                     :text => '<h3 class="product-section-title">最近見た商品</h3>'
                     )

Deface::Override.new(:virtual_path => "spree/products/show",
                     :name => "translate_review",
                     :replace => "#reviews h3.product-section-title",
                     :text => '<h3 class="product-section-title">レビュー</h3>'
                     )

# Deface::Override.new(:virtual_path => "spree/products/show",
#                      :name => "translate_write_your_own_review",
#                      :replace => "#reviews",
#                      :text => '<erb loud>link_to "レビューを書きませんか？", new_product_review_path(@product), class: "btn btn-default"</erb>'
#                      )

Deface::Override.new(:virtual_path => "spree/products/show",
                     :name => "translate_write_your_own_review",
                     :replace => "#reviews",
                     :text => ''
                     )

Deface::Override.new(:virtual_path => "spree/products/show",
                     :name => "translate_bookmark",
                     :replace => "#social_nav h6",
                     :text => '<h6>この商品を共有しませんか？</h6>'
                     )
