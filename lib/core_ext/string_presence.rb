# frozen_string_literal: true

module CoreExtensions
  module ObjectExt
    def self.prepended(base)
      base.prepend Presence
    end

    module Presence
      def blank?
        respond_to?(:empty?) ? !!empty? : !self # rubocop: disable Style/DoubleNegation
      end

      def present?
        !blank?
      end

      def presence
        self if present?
      end
    end
  end
end

Object.prepend CoreExtensions::ObjectExt
