module Spree
  class HomeController < Spree::StoreController
    helper 'spree/products'
    respond_to :html

    def index
      # @searcher = build_searcher(params.merge(include_images: true))
      # @products = @searcher.retrieve_products
      # @products = Spree::Product.join(:)
      @products = Spree::Product.find_by_sql("select * from spree_products a left join spree_variants b on a.id = b.product_id left join spree_line_items c on b.id = c.variant_id left join spree_orders d on c.order_id = d.id where d.number is not null order by d.created_at desc limit 4")
      @new_items = Spree::Product.order("available_on DESC").limit(4)
      @ranking = Spree::Product.find_by_sql("select * from spree_products where id in (select c.product_id from spree_orders a left join spree_line_items b on a.id = b.order_id left join spree_variants c on b.variant_id = c.id group by c.product_id order by sum(b.quantity) desc) limit 3")
      @taxonomies = Spree::Taxonomy.includes(root: :children)
    end
  end
end
