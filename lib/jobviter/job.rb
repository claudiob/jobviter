require 'typhoeus'
require 'nokogiri'

module Jobviter
  class Job

    attr_accessor :attributes

    def initialize(attrs)
      attrs.each {|k,v| attrs[k] = v.strip}
      self.attributes = attrs
    end

    def date
      return @date if defined?(@date)

      match = attributes[:date].match /(\d{1,2})\/(\d{1,2})\/(\d{4})/
      month, day, year = match[1], match[2], match[3]

      @date = Date.civil year.to_i, month.to_i, day.to_i
    end

    def [](attr)
      attributes[attr.to_sym]
    end

    def []=(attr, value)
      attributes[attr.to_sym] = value
    end

    def self.all
      fetch_and_parse.map do |job_node|
        job_attrs = node_to_attrs(job_node)
        self.new job_attrs
      end
    end

    def self.first(limit = nil)
      limit ? all.first(limit) : all.first
    end

    def self.find(id)
      all.detect {|job| job.id == id}
    end

    def method_missing(method, *args, &block)
      if attributes.has_key?(method) && args.empty?
        return self[method]
      end
    end

    private

    def self.fetch_and_parse
      return unless raw_result = fetch

      parsed_document = Nokogiri::XML(raw_result)
      parsed_document.css 'job'
    end

    def self.fetch
      response = Typhoeus::Request.get Jobviter.config.jobs_url

      return response.body if response.success?
    end

    def self.node_to_attrs(node)
      {
        :id                 => node.at_css('id').content,
        :requisition_id     => node.at_css('requisitionid').content,
        :title              => node.at_css('title').content,
        :category           => node.at_css('category').content,
        :type               => node.at_css('jobtype').content,
        :location           => node.at_css('location').content,
        :date               => node.at_css('date').content,
        :detail_url         => node.at_css('detail-url').content,
        :apply_url          => node.at_css('apply-url').content,
        :description        => node.at_css('description').content,
        :brief_description  => node.at_css('briefdescription').content
      }
    end

  end
end
