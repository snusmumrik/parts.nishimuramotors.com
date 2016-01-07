# -*- coding: utf-8 -*-
require "csv"
require "net/http"
require "base64"
require "open-uri"
require "mechanize"

class Product < ActiveRecord::Base
  def self.import_from_csv
    path = "public/products.csv"
    CSV.foreach(path, 'r') do |row|
      # p row

      name = row[2].gsub("'", "’")
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
          if available_on.nil?
            ActiveRecord::Base.connection.update("update spree_products set name = '#{name}' where id = #{spree_product.id}")
          else
            ActiveRecord::Base.connection.update("update spree_products set name = '#{name}', available_on = '#{available_on}' where id = #{spree_product.id}")
          end
        end
      end

      if spree_product.images.first.nil?
        keyword = name.sub(/(専用|保証付き|１年間保証付き|【液入充電済】|【液付属】|一本|1本)/, "").strip
        puts "KEYWORD: #{keyword}"

        self.item_search(spree_product, keyword)
        if spree_product.images.first.nil?
          self.save_image(spree_product, row[6])
        end
      end
    end
  end

  def self.save_image(spree_product, image_url)
    p image_url

    # url = URI.parse(image_url)
    # req = Net::HTTP::Get.new(url.to_s)
    # res = Net::HTTP.start(url.host, url.port) {|http|
    #   http.request(req)
    # }
    # # p res.body

    # image = StringIO.new(Base64.decode64(res.body))
    # # p image
    # # image.class.class_eval { attr_accessor :original_filename, :content_type }
    # # image.original_filename = params[:pigeon][:images][:filename]

    # image.class.class_eval { attr_accessor :content_type }
    # # /\.[a-z]+$/ =~ image_url
    # # extention = $&
    # extention = "image/jpeg"
    # image.content_type = extention

    begin
      if spree_product.images.first.nil?
        spree_product.images.create(attachment: open(image_url))
      end
    rescue => ex
      p ex.message
    end
  end

  def self.item_search(product, keyword)
    request = Vacuum.new("JP")
    request.configure(
                      aws_access_key_id: AWS_ACCESS_KEY_ID,
                      aws_secret_access_key: AWS_SECRET_ACCESS_KEY,
                      associate_tag: ASSOCIATE_TAG
                      )

    parameters = {
      "SearchIndex" => "Automotive",
      "Keywords" => keyword,
      "ResponseGroup" => "Medium"
    }

    # amazon.com
    begin
      response = request.item_search(query: parameters).to_h
      # puts response
    rescue TimeoutError
      warn "TimeoutError"
    rescue  => ex
      case ex
        # when "404" then
        #   warn "404: #{ex.page.uri} does not exist"
      when "Excon::Errors::ServiceUnavailable: Expected(200) <=> Actual(503 Service Unavailable)" then
        if @retryuri != url && sec = ex.page.header["Retry-After"]
          warn "503: will retry #{ex.page.uri} in #{sec}seconds"
          @retryuri = ex.page.uri
          sleep sec.to_i
          retry
        end
      when /\A5/ then
        warn "#{ex.code}: internal error"
      else
        warn ex.message
      end
    end

    if response && response["ItemSearchResponse"]["Items"]["Item"]
      if response["ItemSearchResponse"]["Items"]["Item"].instance_of?(Array)
        item = response["ItemSearchResponse"]["Items"]["Item"][0]
      else
        item = response["ItemSearchResponse"]["Items"]["Item"]
      end
      if !item.nil? && item.instance_of?(Hash)
        puts item
        self.search_amazon_iamges(product, item)
      end
    end
  end

  def self.search_amazon_iamges(product, item)
    if item["ImageSets"] && item["ImageSets"]["ImageSet"].instance_of?(Array)
      for j in 0..4
        if !item["ImageSets"]["ImageSet"][j].blank?
          image_url = item["ImageSets"]["ImageSet"][j]["LargeImage"]["URL"]
          self.save_image(product, image_url)
        end
      end
    elsif item["ImageSets"] && item["ImageSets"]["ImageSet"]
      image_url = item["ImageSets"]["ImageSet"]["LargeImage"]["URL"]
      self.save_image(product, image_url)
    end
  end

  def self.save_image(product, image_url)
    p image_url
    begin
      product.images.create(attachment: open(image_url))
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
      taxonomy = row[0].gsub("'", "’")
      taxon = row[1].gsub("'", "’").gsub(/　+/, " ") unless row[1].blank?
      name = row[2].gsub("'", "’")
      array = [taxonomy, taxon]

        array.each do |value|
      if product = Spree::Product.where(["name = ?", name]).first
          if taxon_translation = ActiveRecord::Base.connection.select_one("select * from spree_taxon_translations where name = '#{value}'")

            p "TAXON: #{value}, PRODUCT: #{product.name}"

            unless ActiveRecord::Base.connection.select_one("select * from spree_products_taxons where product_id = #{product.id} and taxon_id = #{taxon_translation["spree_taxon_id"]}")
              ActiveRecord::Base.connection.create("insert into spree_products_taxons (product_id, taxon_id, position) values (#{product.id}, #{taxon_translation["spree_taxon_id"]}, '1')")
            end

          end
        end
      end
    end
  end

  def self.get_amazon_images(spree_product)
    if supplier = ActiveRecord::Base.connection.select_one("select * from suppliers where spree_product_id = #{spree_product.id}")

      if url = supplier["amazon"]
        puts url
        agent = Mechanize.new

        begin
          page = agent.get(url)
          # puts page
          title = page.search("#productTitle").text
          p title
          if images = page.search("span[class='a-button-text'] img")
            spree_product.images.first.delete if spree_product.images.first
            images.each_with_index do |image, i|
              image_url = image.attr("src").sub!("._SS40_", "")
              p image_url
              /.+\.([a-z]+)$/ =~ image_url
              extention = $1
              spree_product.images.create(attachment: open(image_url))
            end
          end
        rescue TimeoutError
          warn "TimeoutError"
        rescue Mechanize::ResponseCodeError => ex
          case ex.response_code
          when "404" then
            warn "404: #{ex.page.uri} does not exist"
          when "503" then
            # follows RFC2616
            if @retryuri != url && sec = ex.page.header["Retry-After"]
              warn "503: will retry #{ex.page.uri} in #{sec}seconds"
              @retryuri = ex.page.uri
              sleep sec.to_i
              retry
            end
          when /\A5/ then
            warn "#{ex.response_code}: internal error"
          else
            warn ex.message
          end
        end
      end
    end
  end
end
