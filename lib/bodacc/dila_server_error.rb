# frozen_string_literal: true

class Bodacc
  class DilaServerError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
      super
    end
  end
end
