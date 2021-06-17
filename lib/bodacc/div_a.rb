# frozen_string_literal: true

require 'bodacc/notice'

class Bodacc
  class DivA < Notice
    def notice
      id = @dom_notice.xpath('numeroAnnonce').text

      data = {}
      data[:url] = "https://www.bodacc.fr/annonce/detail-annonce/A/#{@published_at}/#{id}"
      data[:title] = @dom_notice.xpath('titreAnnonce').text
      data[:content] = @dom_notice.xpath('contenuAnnonce').text

      data
    end
  end
end
