# -*- coding: utf-8 -*-
require "csv"
require "net/http"

class Product < ActiveRecord::Base
  def self.import_from_csv
    path = "public/products.csv"
    CSV.foreach(path, 'r') do |row|
      p row

      price = row[3] || 0
      if row[5] == true
        available = "2015/09/01"
      else
        available = ""
      end
      # spree_product = Spree::Product.create("name"=>"#{row[0]}", "sku"=>"", "prototype_id"=>"", "price"=>"#{price}", "available_on"=>"#{available}", "shipping_category_id"=>"1")
      spree_product = Spree::Product.find($.)
      spree_product.description = row[2]
      spree_product.save

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
