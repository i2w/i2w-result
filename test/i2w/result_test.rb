require "test_helper"

module I2w
  class ResultTest < ActiveSupport::TestCase
    test 'success result' do
      result = Result.success(:val)

      assert result.success?
      refute result.failure?
      assert result.errors.empty?
      assert result.failure.nil?
      assert_equal :val, result.value
      assert_equal :val, result.value_or(:fallback)
      assert :val, result.then { |s| s }.success?
      assert_equal "got: val", result.and_then { |s| "got: #{s}" }.value
    end

    test 'failure result' do
      result = Result.failure(:err)

      refute result.success?
      assert result.failure?
      assert result.errors.empty?
      assert_equal result.failure, :err
      assert_equal result.value_or(:fallback), :fallback
      assert_raises(Result::FailureTreatedAsSuccessError) { result.value }
      assert result.and_then { |s| "got: #{s}" }.failure?
    end

    test 'failure result with errors' do
      result = Result.failure(:input_invalid, { attribute: ['is required'] })

      assert_equal result.errors, { attribute: ['is required'] }
    end

    def pattern_match(result)
      case result
      in :success, success
        "Success: #{success}"
      in :failure, :input_invalid, { attribute: message }
        "Failure on attr #{message}"
      in :failure, :input_invalid, _
        'Failure: Input Invalid'
      in :failure, error, _
        "Failure: #{error}"
      else
        'WAT?'
      end
    end

    test 'pattern matching' do
      assert_equal pattern_match(Result.success(:val)), 'Success: val'
      assert_equal pattern_match(Result.failure(:input_invalid)), 'Failure: Input Invalid'
      assert_equal pattern_match(Result.failure(:input_invalid, { attribute: ['foo'] })), 'Failure on attr ["foo"]'
      assert_equal pattern_match(Result.failure(:db_constraint)), 'Failure: db_constraint'
      assert_equal pattern_match(Object.new), 'WAT?'
    end

    def result_match(result)
      Result.match(result) do |on|
        on.success           { |success| "Success: #{success}" }
        on.failure(:invalid) { |_failure, errors| "Input Invalid: #{errors}" }
        on.failure(:db)      { |failure, _errors| "Failure: #{failure}" }
      end
    end

    test 'result callback' do
      assert_equal result_match(Result.success(:val)), 'Success: val'
      assert_equal result_match(Result.failure(:invalid, { foo: ['bar'] })), 'Input Invalid: {:foo=>["bar"]}'
      assert_equal result_match(Result.failure(:db)), 'Failure: db'
      assert_raises(Result::NoMatchError) { result_match(Result.failure(:foo)) }
    end
  end
end
