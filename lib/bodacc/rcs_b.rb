# frozen_string_literal: true

require 'bodacc/notice'

class Bodacc
  class RcsB < Notice
    def notice
      id = @dom_notice.xpath('numeroAnnonce').text
      registry_region = @dom_notice.xpath('numeroDepartement').text
      registry_name = @dom_notice.xpath('tribunal').text.presence

      data = {}
      data[:url] = "https://www.bodacc.fr/annonce/detail-annonce/B/#{@published_at}/#{id}"
      data[:entities] = @dom_notice.xpath('personnes/personne').map do |dom_person|
        process_entity(dom_person, registry_region: registry_region, registry_name: registry_name)
      end

      if @dom_notice.at('modificationsGenerales')
        data[:type] = 'update'
        data[:descriptive] = @dom_notice.xpath('modificationsGenerales/descriptif').text

        if @dom_notice.at('modificationsGenerales/dateCommencementActivite')
          data[:started_at] = Date.parse(@dom_notice.xpath('modificationsGenerales/dateCommencementActivite').text)
        end

        if @dom_notice.at('modificationsGenerales/dateEffet')
          data[:effective_at] = Date.parse(@dom_notice.xpath('modificationsGenerales/dateEffet').text)
        end
      elsif @dom_notice.at('radiationAuRCS/radiationPP')
        data[:type] = 'delete'
        data[:ended_at] = Date.parse(@dom_notice.xpath('radiationAuRCS/radiationPP/dateCessationActivitePP').text)
      elsif @dom_notice.at('radiationAuRCS/radiationPM') || @dom_notice.at('radiationAuRCS')
        data[:type] = 'delete'
      end

      if @dom_notice.at('radiationAuRCS')
        data[:comment] = dom_judgment.xpath('radiationAuRCS/commentaire').text.presence
      end

      data
    end
  end
end
