# frozen_string_literal: true

require 'core_ext/string_presence'

class Bodacc
  class Notice
    def initialize(dom_notice, published_at)
      @dom_notice = dom_notice
      @published_at = published_at
    end

    def self.parse(dom_notice, published_at)
      new(dom_notice, published_at).notice
    end

    def notice
      raise NotImplementedError
    end

    private

    def process_entity(dom_person, registry_region: nil, registry_name: nil)
      dom_registration = if dom_person.at('numeroImmatriculation')
                           dom_person.xpath('numeroImmatriculation')
                         elsif dom_person.at('personnePhysique/numeroImmatriculation')
                           dom_person.xpath('personnePhysique/numeroImmatriculation')
                         elsif dom_person.at('personneMorale/numeroImmatriculation')
                           dom_person.xpath('personneMorale/numeroImmatriculation')
                         end
      registry_name ||= dom_registration&.xpath('tribunal')&.text.presence

      data = process_registration(dom_registration, registry_region: registry_region, registry_name: registry_name)

      if dom_person.at('personnePhysique')
        data[:type] = 'person'
        data[:firstname] = dom_person.xpath('personnePhysique/prenom').text
        data[:lastname] = dom_person.xpath('personnePhysique/nom').text
        data[:address] = (process_address(dom_person.xpath('adresse')) if dom_person.at('adresse'))
      elsif dom_person.at('personneMorale')
        data[:type] = 'enterprise'
        data[:name] = dom_person.xpath('personneMorale/denomination').text
        data[:administration] = dom_person.xpath('personneMorale/administration').text
        data[:address] = if dom_person.at('siegeSocial')
                           process_address(dom_person.xpath('siegeSocial'))
                         elsif dom_person.at('adresse')
                           process_address(dom_person.xpath('adresse'))
                         end

        dom_share_capital = if dom_person.at('capital')
                              dom_person
                            elsif dom_person.at('capitalVariable')
                              dom_person
                            elsif dom_person.at('personneMorale/capitalVariable')
                              dom_person.xpath('personneMorale')
                            elsif dom_person.at('personneMorale/capitalVariable')
                              dom_person.xpath('personneMorale')
                            end

        data.merge!(process_share_capital(dom_share_capital))
      end

      data
    end

    def process_share_capital(dom_share_capital)
      data = {}

      if dom_share_capital&.at('capital')
        data[:share_capital] = {
          amount: dom_share_capital.xpath('capital/montantCapital').text.to_f,
          currency: dom_share_capital.xpath('capital/devise').text.downcase
        }
      elsif dom_share_capital&.at('capitalVariable')
        variable_share_capital = dom_share_capital.xpath('capitalVariable').text.split(' ')

        data[:share_capital] = {
          amount: variable_share_capital.first.to_f,
          currency: variable_share_capital.last.downcase
        }
      end

      data
    end

    def process_registration(dom_registration, registry_region: nil, registry_name: nil)
      data = {}

      if dom_registration&.at('numeroIdentificationRCS')
        data[:registration_number] = dom_registration.xpath('numeroIdentificationRCS').text.tr(' ', '')
        data[:registration_type] = dom_registration.xpath('codeRCS').text.downcase.presence || 'rcs'
      elsif dom_registration&.at('numeroIdentification')
        data[:registration_number] = dom_registration.xpath('numeroIdentification').text.tr(' ', '')
        data[:registration_type] = dom_registration.xpath('codeRCS').text.downcase.presence || 'unknown'
      end

      data[:registry_region] = registry_region
      data[:registry_name] = if dom_registration&.at('nomGreffeImmat')
                               dom_registration.xpath('nomGreffeImmat').text
                             else
                               registry_name
                             end

      data
    end

    def process_address(dom_address)
      data = {}
      country_tag_name = dom_address.xpath('*').first.name

      case country_tag_name
      when 'france'
        city_tag_name = %w[localite ville].find { |tag_name| dom_address.at("france/#{tag_name}") }

        data[:street] = [
          dom_address.xpath('france/numeroVoie').text.presence,
          dom_address.xpath('france/typeVoie').text.presence,
          dom_address.xpath('france/nomVoie').text.presence,
          dom_address.xpath('france/complGeographique').text.presence
        ].compact.join(' ')
        data[:zipcode] = dom_address.xpath('france/codePostal').text
        data[:city] = dom_address.xpath("france/#{city_tag_name}").text
        data[:country] = 'fr'
        data
      when 'etranger'
        data[:street] = dom_address.xpath('etranger/adresse').text.presence
        data[:zipcode] = nil
        data[:city] = nil
        data[:country] = dom_address.xpath('etranger/pays').text.downcase
        data
      end
    end
  end
end
