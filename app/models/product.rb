# -*- coding: utf-8 -*-
require "csv"
require "net/http"

class Product < ActiveRecord::Base
  def self.import_from_csv
    path = "public/products.csv"
    CSV.foreach(path, 'r') do |row|
      p row

      name = row[0]
      model_number = row[1]
      description = row[2]
      sold_out = row[5]

      price = row[3] || 0

      if sold_out == "false"
        available_on = Date.today
      else
        available_on = nil
      end

      unless Spree::Product.where(["name = ? AND description = ?", name, description]).first
        # if last = Spree::Product.last
        #   last_id = last.id + 1
        # else
        #   last_id = 1
        # end
        # sku = last_id.to_s.rjust(10, '0')
        # sku = nil

        spree_product = Spree::Product.create("name" => "#{name}",
                                              "description" =>  description,
                                              "meta_keywords" => model_number,
                                              # "sku" => sku,
                                              "prototype_id" => "",
                                              "price" => price,
                                              "available_on" => available_on,
                                              "shipping_category_id" => "1")

        unless spree_product.id.blank?
          replaced_name = name.gsub("'", "’")
          if available_on.nil?
            ActiveRecord::Base.connection.update("update spree_products set name = '#{replaced_name}' where id = #{spree_product.id}")
          else
            ActiveRecord::Base.connection.update("update spree_products set name = '#{replaced_name}', available_on = '#{available_on}' where id = #{spree_product.id}")
          end
        end
      end

      # Product.save_image(spree_product, row[4])
    end
  end

  def self.save_image(spree_product, image_url)
    url = URI.parse(image_url)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    # puts res.body

    image = StringIO.new(Base64.decode64(res.body))
    # image.class.class_eval { attr_accessor :original_filename, :content_type }
    # image.original_filename = params[:pigeon][:images][:filename]    
    
    image.class.class_eval { attr_accessor :content_type }
    # /\.[a-z]+$/ =~ image_url
    # extention = $&
    extention = "image/jpeg"
    image.content_type = extention
    spree_product.images.create(viewable_id: spree_product.id, viewable: image)
  end

  def self.update_price
    Spree::Product.all.each do |product|
      price = Price.where(["spree_product_id = ?", product.id]).first
      array = Array.new
      array << price.ngsj unless price.ngsj.nil?
      array << price.iiparts unless price.iiparts.nil?
      array << price.amazon unless price.amazon.nil?
      array << price.rakuten unless price.rakuten.nil?
      array << price.yahoo unless price.yahoo.nil?
      array.sort

      low = array.first
      high = array.last
      percentage = Profit.last.try(:percentage) || 0.5

      if !low.nil? && !high.nil?
        product.price = low + (high - low) * percentage
      elsif !low.nil?
        product.price = low * 1.3
      end

      if array.size == 0
        product.avilable_on = nil
      end

      p product.price.to_i
      product.save
    end
  end
end
