require 'httparty'
require 'json'
require 'uri'

require "flapjack-diner/version"

module Flapjack
  module Diner

    include HTTParty
    format :json

    class << self

      # NB: clients will need to handle any exceptions caused by,
      # e.g., network failures or non-parseable JSON data.

      def entities
        jsonify( get("/entities") )
      end

      def checks(entity)
        args = prepare(:entity => {:value => entity, :required => true})

        pr, ho, po = protocol_host_port
        uri = URI::HTTP.build(:protocol => pr, :host => ho, :port => po,
          :path => "/checks/#{args[:entity]}")

        jsonify( get(uri.request_uri) )
      end

      def status(entity, check = nil)
        args = prepare(:entity     => {:value => entity, :required => true},
                       :check      => {:value => check})

        path = "/status/#{args[:entity]}"
        path += "/#{args[:check]}" if args[:check]

        pr, ho, po = protocol_host_port
        uri = URI::HTTP.build(:protocol => pr, :host => ho, :port => po,
          :path => path)

        jsonify( get(uri.request_uri) )
      end

      def acknowledge!(entity, check, options = {})
        args = prepare(:entity   => {:value => entity, :required => true},
                       :check    => {:value => check, :required => true})
        query = prepare(:summary => {:value => options[:summary]})

        path = "/acknowledgments/#{args[:entity]}/#{args[:check]}"
        params = query.collect{|k,v| "#{k.to_s}=#{v}"}.join('&')

        jsonify( post(path, :body => params) )
      end

      def create_scheduled_maintenance!(entity, check, start_time, duration, options = {})
        args = prepare(:entity     => {:value => entity, :required => true},
                       :check      => {:value => check, :required => true})
        query = prepare(:start_time => {:value => start_time, :required => true, :class => Time},
                        :duration   => {:value => duration, :required => true, :class => Integer},
                        :summary    => {:value => options[:summary]})

        path ="/scheduled_maintenances/#{args[:entity]}/#{args[:check]}"
        params = query.collect{|k,v| "#{k.to_s}=#{v}"}.join('&')

        jsonify( post(path, :body => params) )
      end

      def scheduled_maintenances(entity, check = nil, options = {})
        args = prepare(:entity      => {:value => entity, :required => true},
                       :check       => {:value => check})
        query = prepare(:start_time => {:value => options[:start_time], :class => Time},
                        :end_time   => {:value => options[:end_time], :class => Time})

        path = "/scheduled_maintenances/#{args[:entity]}"
        path += "/#{args[:check]}" if args[:check]

        params = query.collect{|k,v| "#{k.to_s}=#{v}"}

        pr, ho, po = protocol_host_port
        uri = URI::HTTP.build(:protocol => pr, :host => ho, :port => po,
          :path => path, :query => params.empty? ? nil : params.join('&'))

        jsonify( get(uri.request_uri) )
      end

      def unscheduled_maintenances(entity, check = nil, options = {})
        args = prepare(:entity      => {:value => entity, :required => true},
                       :check       => {:value => check})
        query = prepare(:start_time => {:value => options[:start_time], :class => Time},
                        :end_time   => {:value => options[:end_time], :class => Time})

        path = "/unscheduled_maintenances/#{args[:entity]}"
        path += "/#{args[:check]}" if args[:check]

        params = query.collect{|k,v| "#{k.to_s}=#{v}"}

        pr, ho, po = protocol_host_port
        uri = URI::HTTP.build(:protocol => pr, :host => ho, :port => po,
          :path => path, :query => params.empty? ? nil : params.join('&'))

        jsonify( get(uri.request_uri) )
      end

      def outages(entity, check = nil, options = {})
        args = prepare(:entity      => {:value => entity, :required => true},
                       :check       => {:value => check})
        query = prepare(:start_time => {:value => options[:start_time], :class => Time},
                        :end_time   => {:value => options[:end_time], :class => Time})

        path = "/outages/#{args[:entity]}"
        path += "/#{args[:check]}" if args[:check]

        params = query.collect{|k,v| "#{k.to_s}=#{v}"}

        pr, ho, po = protocol_host_port
        uri = URI::HTTP.build(:protocol => pr, :host => ho, :port => po, :path => path,
          :query => params.empty? ? nil : params.join('&'))

        jsonify( get(uri.request_uri) )
      end

      def downtime(entity, check = nil, options = {})
        args = prepare(:entity      => {:value => entity, :required => true},
                       :check       => {:value => check})
        query = prepare(:start_time => {:value => options[:start_time], :class => Time},
                        :end_time   => {:value => options[:end_time], :class => Time})

        path = "/downtime/#{args[:entity]}"
        path += "/#{args[:check]}" if args[:check]

        params = query.collect{|k,v| "#{k.to_s}=#{v}"}

        pr, ho, po = protocol_host_port
        uri = URI::HTTP.build(:protocol => pr, :host => ho, :port => po,
          :path => path, :query => params.empty? ? nil : params.join('&'))

        jsonify( get(uri.request_uri) )
      end

    private

      def protocol_host_port
        self.base_uri =~ /$(?:(https?):\/\/)?([a-zA-Z0-9][a-zA-Z0-9\.\-]*[a-zA-Z0-9])(?::\d+)?/i
        protocol = ($1 || 'http').downcase
        host = $2
        port = $3 || ('https'.eql?(protocol) ? 443 : 80)

        [protocol, host, port]
      end

      def prepare(data = {})
        data.merge!(data) {|k,ov,nv|
          if ov[:value].nil?
            raise "'#{k.to_s}' is required" if ov[:required]
            nil
          else
            raise "'#{k.to_s}' must be a #{ov[:class]}" if ov[:class] && !ov[:value].is_a?(ov[:class])
            if ov[:value].is_a?(Time)
              URI.escape(ov[:value].iso8601)
            else
              URI.escape(ov[:value].to_s)
            end
          end
        }.reject {|k,v| v.nil? }
      end

      def jsonify(response)
        return unless response && response.body
        JSON.parse(response.body)
      end

    end

  end
end
