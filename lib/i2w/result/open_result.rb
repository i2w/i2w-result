# frozen_string_literal: true

require_relative 'hash_result'
require 'ostruct'

module I2w
  module Result
    # Just like a HashResult, except you can set arbitrary vaules via = methods, eg.
    #
    #   Result.open_result do |r|
    #     r.user              = repo(User).find(id: user_id)
    #     r[:comment, :input] = repo(Comment).create(user_id: r.user.id, input: input)
    #   end
    #
    # #value and #failure both return OpenStructs
    class OpenResult < HashResult
      def method_missing(method, *args)
        last = method.to_s[-1]
        if last == '=' && args.length == 1
          self[method.to_s[0..-2].to_sym] = args.first
        elsif !%[! ?].include?(last) && @hash.key?(method)
          self[method]
        else
          super
        end
      end

      def value = OpenStruct.new(super)

      def failure = OpenStruct.new(super)
    end
  end
end