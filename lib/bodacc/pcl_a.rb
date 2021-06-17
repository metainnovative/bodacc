# frozen_string_literal: true

require 'bodacc/notice'

class Bodacc
  class PclA < Notice
    def notice
      id = @dom_notice.xpath('numeroAnnonce').text
      registry_region = @dom_notice.xpath('numeroDepartement').text

      data = {}
      data[:url] = "https://www.bodacc.fr/annonce/detail-annonce/A/#{@published_at}/#{id}"
      data[:type] = @dom_notice.xpath('typeAnnonce/*').first.name
      data[:entity] = process_entity(@dom_notice, registry_region: registry_region)
      data[:judgment] = nil

      judgment_tag_name = if @dom_notice.at('jugementAnnule')
                            'jugementAnnule'
                          elsif @dom_notice.at('jugement')
                            'jugement'
                          end
      dom_judgment = @dom_notice.xpath(judgment_tag_name)

      if dom_judgment
        data[:judgment] = {}
        data[:judgment][:type] = judgment_tag_name
        data[:judgment][:name] = dom_judgment.xpath('famille').text
        data[:judgment][:descriptive] = dom_judgment.xpath('nature').text
        data[:judgment][:established_at] = (Date.parse(dom_judgment.xpath('date').text) if dom_judgment.at('date'))
        data[:judgment][:comment] = dom_judgment.xpath('complementJugement').text
      end

      data
    end

    private

    def process_entity(dom_person, registry_region: nil)
      data = super
      data[:registration_number] ||= dom_person.xpath('identifiantClient').text
      data
    end
  end
end
