require 'byebug'                # optional, may be helpful
require 'open-uri'              # allows open('http://...') to return body
require 'cgi'                   # for escaping URIs
require 'nokogiri'              # XML parser
require 'active_model'          # for validations

class OracleOfBacon

  class InvalidError < RuntimeError ; end
  class NetworkError < RuntimeError ; end
  class InvalidKeyError < RuntimeError ; end

  attr_accessor :from, :to
  attr_reader :api_key, :response, :uri
  
  include ActiveModel::Validations
  validates_presence_of :from
  validates_presence_of :to
  validates_presence_of :api_key
  validate :from_does_not_equal_to

  def from_does_not_equal_to
    # YOUR CODE HERE
    if @from == @to
      self.errors.add(:from, 'cannot be the same as To')
    end
  end

  def initialize(api_key='')
    @api_key = api_key
    @from = 'Kevin Bacon'
    @to = 'Kevin Bacon'
    @uri = nil
    @response = nil
    # your code here
  end

  def find_connections
byebug    
    raise InvalidError unless self.valid?
    make_uri_from_arguments
    begin
      xml = URI.parse(@uri).read
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError => e
      # convert all of these into a generic OracleOfBacon::NetworkError,
      #  but keep the original error message
      # your code here
      raise OracleOfBacon::NetworkError, e.message
    end
    # your code here: create the OracleOfBacon::Response object
    @response = Response.new(xml)
  end

  def make_uri_from_arguments
   @uri =
      'http://oracleofbacon.org/cgi-bin/xml?p=' +
      CGI.escape(api_key) +
      '&a=' + CGI.escape(from) +
      '&b=' + CGI.escape(to)
  end
      
    private

  class Response
    attr_reader :type, :data
    def initialize(xml)
      @doc = Nokogiri::XML(xml)
      parse_response
    end
    private
    def parse_response
      if @doc.xpath('/error').any?
        parse_error_response
      elsif @doc.xpath('/link').any?
        parse_graph_response
      elsif @doc.xpath('/spellcheck').any?
        parse_spellcheck_response
      else
        parse_unknown_response
      end
    end
    def parse_error_response
      @type = :error
      @data = 'Unauthorized access'
    end
    def parse_unknown_response
      @type = :unknown
      @data = 'Unknown response type'
    end
    
    def parse_graph_response
      @type = :graph
      actors = @doc.xpath('//actor').map(&:content)
      movies = @doc.xpath('//movie').map(&:content)
      @data = actors.zip(movies).flatten.compact
    end
    def parse_spellcheck_response
      @type = :spellcheck
      @data = @doc.xpath('//match').map(&:content)
    end
    
    def actors
      @doc.xpath('//actor')
    end
    def movies
      @doc.xpath('//movie')
    end
  end
end

