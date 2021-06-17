# frozen_string_literal: true

require 'bodacc/notice'

class Bodacc
  class BilanC < Notice
    def notice
      id = @dom_notice.xpath('numeroAnnonce').text
      registry_region = @dom_notice.xpath('numeroDepartement').text

      data = {}
      data[:url] = "https://www.bodacc.fr/annonce/detail-annonce/C/#{@published_at}/#{id}"
      data[:type] = @dom_notice.xpath('typeAnnonce/*').first.name
      data[:entity] = process_entity(@dom_notice, registry_region: registry_region)
      data[:document] = nil

      if @dom_notice.at('depot')
        data[:document] = {}
        data[:document][:name] = @dom_notice.xpath('depot/typeDepot').text
        data[:document][:descriptive] = @dom_notice.xpath('depot/descriptif').text
        data[:document][:closed_at] = (if @dom_notice.at('depot/dateCloture')
                                        Date.parse(@dom_notice.xpath('depot/dateCloture').text)
                                      end)
      end

      data
    end
  end
end
