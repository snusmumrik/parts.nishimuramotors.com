# -*- coding: utf-8 -*-
require "csv"
require "net/http"
require "base64"
require "open-uri"

class Product < ActiveRecord::Base
  def self.import_from_csv
    path = "public/products.csv"
    CSV.foreach(path, 'r') do |row|
      # p row

      name = row[2]
      model_number = row[3]
      description = row[4]
      sold_out = row[7]

      price = row[5] || 0

      if sold_out == "false"
        available_on = Date.today
      else
        available_on = nil
      end

      # if last = Spree::Product.last
      #   last_id = last.id + 1
      # else
      #   last_id = 1
      # end
      # sku = last_id.to_s.rjust(10, '0')
      # sku = nil

      if spree_product = Spree::Product.where(["name = ?", name]).first
        spree_product.update_attributes("description" =>  description,
                                        "meta_keywords" => model_number,
                                        # "sku" => sku,
                                        "prototype_id" => "",
                                        "price" => price,
                                        "available_on" => available_on,
                                        "shipping_category_id" => "1")
      else
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

      self.save_image(spree_product, row[6])
    end
  end

  def self.save_image(spree_product, image_url)
    p image_url
    url = URI.parse(image_url)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    # p res.body

    image = StringIO.new(Base64.decode64(res.body))
    # p image
    # image.class.class_eval { attr_accessor :original_filename, :content_type }
    # image.original_filename = params[:pigeon][:images][:filename]    
    
    image.class.class_eval { attr_accessor :content_type }
    # /\.[a-z]+$/ =~ image_url
    # extention = $&
    extention = "image/jpeg"
    image.content_type = extention

    begin
      if spree_product.images.first.nil?
        spree_product.images.create(attachment: open(image_url))
      end
    rescue => ex
      p ex.message
    end
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

  def self.delete_duplicated_product
    Spree::Product.all.each do |p|
      array = Spree::Product.where(["name = ?", p.name]).all
      if array.size > 1
        p array
        duplicated = array.last
        duplicated.deleted_at = DateTime.now
        duplicated.save
      end
    end
  end

  def self.update_taxons
    path = "public/products.csv"
    CSV.foreach(path, 'r') do |row|
      # p row
      parentcategory = row[0].gsub("'", "’")
      subcategories = row[1].gsub("'", "’")
      categories = [parentcategory, subcategories]
      categories.each do |category|
        name = row[2].gsub("'", "’")
        if product = Spree::Product.where(["name = ?", name]).first
          if taxon_translation = ActiveRecord::Base.connection.select_one("select * from spree_taxon_translations where name = '#{category}'")

            p "CATEGORY: #{category}, PRODUCT: #{product.name}, TAXON: #{taxon_translation["name"]}"

            unless products_taxons = ActiveRecord::Base.connection.select_one("select * from spree_products_taxons where product_id = #{product.id} and taxon_id = #{taxon_translation["spree_taxon_id"]}")
              ActiveRecord::Base.connection.create("insert into spree_products_taxons (product_id, taxon_id, position) values (#{product.id}, #{taxon_translation["spree_taxon_id"]}, '1')")
            end
          end
        end
      end
    end
  end
end
