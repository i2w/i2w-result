# frozen_string_literal: true

require "forwardable"

module I2w
  module Result
    # minimal implementation of an errors object, a subset of ActiveModel::Errors functionality
    class Errors
      include Enumerable
      extend Forwardable

      def_delegators :@errors, :keys, :key?, :count, :size, :clear, :blank?, :empty?, :any?

      def initialize(errors = {})
        @errors = Hash.new { |hash, key| hash[key] = [] }
        errors.to_h.each { |key, errs| Array(errs).each { add(key, _1) } }
      end

      def each
        return to_enum(:each) unless block_given?

        to_hash.each { |key, errs| errs.each { yield(key, _1) } }
      end

      def add(key, err) = @errors[key.to_sym].push(err)

      def to_hash = @errors.dup

      alias to_h to_hash

      def messages_for(key) = @errors[key]

      alias [] messages_for

      def full_messages = @errors.flat_map { |key, errs| errs.map { "#{key.to_s.titleize} #{_1}" } }

      alias to_a full_messages

      alias attribute_names keys

      alias include? key?
    end
  end
end
