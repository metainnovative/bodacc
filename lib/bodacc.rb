# frozen_string_literal: true

require 'date'
require 'net/http'
require 'nokogiri'
require 'rubygems/package'
require 'tempfile'

require 'bodacc/bilan_c'
require 'bodacc/date_parsing_error'
require 'bodacc/dila_server_error'
require 'bodacc/div_a'
require 'bodacc/pcl_a'
require 'bodacc/rcs_a'
require 'bodacc/rcs_b'
require 'bodacc/unrecognized_file_error'
require 'bodacc/version'
require 'core_ext/string_presence'

class Bodacc
  include Singleton

  def self.list(year: nil)
    instance.list(year)
  end

  def list(year)
    response = request(year: year)

    raise DilaServerError, response unless response.is_a?(Net::HTTPSuccess)

    response.body.scan(/<a href="([\w-]+\.taz)">/).map { |match| match.first.sub(/\.taz$/, '') }
  end

  def self.get(filename, &block)
    instance.get(filename, &block)
  end

  def get(filename)
    notices_xpath = '//listeAvis/avis'

    case filename
    when /^BILAN_BXC/
      klass = BilanC
      year = filename.match(/BILAN_BXC(\d{4})\d+/)[1]
    when /^DIVA/
      klass = DivA
      year = filename.match(/DIVA(\d{4})\d+/)[1]
    when /^PCL_BXA/
      klass = PclA
      year = filename.match(/PCL_BXA(\d{4})\d+/)[1]
      notices_xpath = '//annonces/annonce'
    when /^RCS-A_BXA/
      klass = RcsA
      year = filename.match(/RCS-A_BXA(\d{4})\d+/)[1]
    when /^RCS-B_BXB/
      klass = RcsB
      year = filename.match(/RCS-B_BXB(\d{4})\d+/)[1]
    else
      raise UnrecognizedFileError, "filename: #{filename}"
    end

    raise DateParsingError, "filename: #{filename}" unless year

    response = request(filename, year: year)

    raise DilaServerError, response unless response.is_a?(Net::HTTPSuccess)

    string_to_io(response.body) do |taz_file|
      taz_extract(taz_file) do |dom|
        dom_notices = dom.xpath(notices_xpath)
        published_at = dom.xpath('//parution').text

        if block_given?
          dom_notices.each do |dom_notice|
            yield klass.parse(dom_notice, published_at)
          end

          nil
        else
          dom_notices.map do |dom_notice|
            klass.parse(dom_notice, published_at)
          end
        end
      end
    end
  end

  private

  def string_to_io(date)
    taz_file = Tempfile.new(%w[bodacc .taz])
    taz_file.binmode
    taz_file.write(date)
    taz_file.flush
    taz_file.rewind

    yield taz_file
  ensure
    taz_file.close
    taz_file.unlink
  end

  def taz_extract(taz_file)
    Gem::Package::TarReader.new(taz_file) do |taz|
      dom = Nokogiri::XML(taz.first)

      return (yield dom)
    ensure
      taz.close
    end
  end

  def request(filename = nil, year: nil)
    year ||= Date.today.year
    path = ("#{filename}.taz" if filename.present?)
    base_path = if Date.today.year.to_s == year.to_s
                  "/OPENDATA/BODACC/#{year}/"
                else
                  "/OPENDATA/BODACC/FluxHistorique/#{year}/"
                end

    http = Net::HTTP.new('echanges.dila.gouv.fr', 443)
    http.use_ssl = true
    http.get("#{base_path}#{path}")
  end
end
