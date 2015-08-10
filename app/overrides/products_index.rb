# -*- coding: utf-8 -*-
Deface::Override.new(:virtual_path => "spree/shared/_products",
                     :name => "translate_recently_viewed_products",
                     :replace => "#recently_viewed h3.product-section-title",
                     :text => '<h3 class="product-section-title">最近見た商品</h3>'
                     )
