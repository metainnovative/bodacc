# frozen_string_literal: true

require 'bodacc/notice'

class Bodacc
  class RcsA < Notice
    def notice
      id = @dom_notice.xpath('numeroAnnonce').text
      registry_region = @dom_notice.xpath('numeroDepartement').text
      registry_name = @dom_notice.xpath('tribunal').text.presence

      data = {}
      data[:url] = "https://www.bodacc.fr/annonce/detail-annonce/A/#{@published_at}/#{id}"
      data[:entities] = @dom_notice.xpath('personnes/personne').map do |dom_person|
        process_entity(dom_person, registry_region: registry_region, registry_name: registry_name)
      end

      if @dom_notice.at('etablissement')
        data[:establishment] = {}
        data[:establishment][:fund_origin] = @dom_notice.xpath('etablissement/origineFonds').text.presence
        data[:establishment][:type] = @dom_notice.xpath('etablissement/qualiteEtablissement').text.presence
        data[:establishment][:activity] = @dom_notice.xpath('etablissement/activite').text.presence
        data[:establishment][:address] = (process_address(@dom_notice.xpath('etablissement/adresse')) if @dom_notice.at('etablissement/adresse'))
      end

      data[:act] = nil

      if @dom_notice.at('acte')
        act_tag_name = @dom_notice.xpath('acte/*').first.name
        dom_act = @dom_notice.at("acte/#{act_tag_name}")

        data[:act] = {}
        data[:act][:type] = act_tag_name

        case act_tag_name
        when 'creation'
          data[:act][:category] = dom_act.xpath('categorieCreation').text
        when 'immatriculation'
          data[:act][:category] = dom_act.xpath('categorieImmatriculation').text
          data[:act][:descriptive] = dom_act.xpath('descriptif').text

          if dom_act.at('dateEffet')
            data[:act][:effective_at] = Date.parse(dom_act.xpath('dateEffet').text)
          end
        when 'vente'
          data[:act][:issue] = (if dom_act.at('journal')
                                  {
                                    title: dom_act.xpath('journal/titre').text,
                                    published_at: Date.parse(dom_act.xpath('journal/date').text)
                                  }
                                end)
          data[:act][:category] = dom_act.xpath('categorieVente').text

          if dom_act.at('opposition')
            data[:act][:opposition] = dom_act.xpath('opposition').text
          elsif dom_act.at('declarationCreance')
            data[:act][:declaration] = dom_act.xpath('declarationCreance').text
          end

          data[:act][:descriptive] = dom_act.xpath('descriptif').text.presence

          if dom_act.at('dateEffet')
            data[:act][:effective_at] = Date.parse(dom_act.xpath('dateEffet').text)
          end
        end

        if dom_act.at('dateImmatriculation')
          data[:act][:requested_at] = Date.parse(dom_act.xpath('dateImmatriculation').text)
        end

        if dom_act.at('dateCommencementActivite')
          data[:act][:started_at] = Date.parse(dom_act.xpath('dateCommencementActivite').text)
        end
      end

      data
    end
  end
end
