require 'test_helper'

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
      assert_equal 'got: val', result.and_then { |s| "got: #{s}" }.value

      side_effects = []
      assert_equal :val, result.and_tap { |s| side_effects << "got: #{s}" }.value
      assert_equal ['got: val'], side_effects
    end

    test 'failure result' do
      result = Result.failure(:err)

      refute result.success?
      assert result.failure?
      assert result.errors.empty?
      assert_equal :err, result.failure
      assert_equal :fallback, result.value_or(:fallback)
      assert_raises(Result::FailureTreatedAsSuccessError) { result.value }
      assert result.and_then { |s| "got: #{s}" }.failure?

      side_effects = []
      assert result.and_tap { |s| side_effects << "got: #{s}" }.failure?
      assert_equal [], side_effects
    end

    test 'failure result with errors' do
      result = Result.failure(:input_invalid, { attribute: ['is required'] })

      assert_equal({ attribute: ['is required'] }, result.errors)
    end

    test 'failure object with errors' do
      input = Object.new
      input.singleton_class.define_method(:errors) { { attribute: ['is required'] } }

      result = Result.failure(input)
      assert_equal input, result.failure
      assert_equal({ attribute: ['is required'] }, result.errors)
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

    test 'chaining syntax success' do
      side_effects = []

      actual = Result['80'].and_tap { side_effects << _1 }
                           .and_then(&:to_i)
                           .and_tap { side_effects << _1 }
                           .and_then { Result[1 + _1] }
                           .and_tap { side_effects << (_1 + 100) } # has no effect on the value
                           .and_then { _1 / 9 }

      assert actual.success?
      assert_equal 9, actual.value
      assert_equal ['80', 80, 181], side_effects
    end

    test 'chaining syntax failure' do
      side_effects = []

      actual = Result['80'].and_tap { side_effects << _1 }
                           .and_then(&:to_i)
                           .and_tap { side_effects << _1 }
                           .and_then { Result.failure(:problem) }
                           .and_tap { side_effects << (_1 + 100) }
                           .and_then { _1 / 9 }

      refute actual.success?
      assert_equal :problem, actual.failure
      assert_equal ['80', 80], side_effects
    end

    test 'Result do syntax' do
      side_effects = []

      num = '80'
      actual = Result.do do |r|
        side_effects << num
        num = r.value! Result[num.to_i]
        side_effects << num
        num = r.value! Result[1 + num]
        side_effects << (num + 100)
        num / 9
      end

      assert actual.success?
      assert_equal 9, actual.value
      assert_equal ['80', 80, 181], side_effects
    end

    test 'Result do syntax with failure' do
      side_effects = []

      num = '80'
      actual = Result.do do |r|
        side_effects << num
        num = r.value! Result[num.to_i]
        side_effects << num
        num = r.value! Result.failure(:problem)
        side_effects << (num + 100)
        num / 9
      end

      refute actual.success?
      assert_equal :problem, actual.failure
      assert_equal ['80', 80], side_effects
    end

    class Foo
      prepend Result::Do

      def self.inherited(subclass)
        super
        subclass.prepend(Result::Do)
      end

      def call(arg)
        bar = value! process_arg(arg)
        "success: #{bar}"
      end

      def process_arg(arg)
        return Result.success(arg) if arg == :bar

        Result.failure(:must_be_bar)
      end
    end

    class DowncaseFoo < Foo
      def call(arg)
        arg = value! downcase(arg)
        super(arg)
      end

      def downcase(arg)
        return Result.failure(:must_not_be_baz) if arg == :baz

        Result[arg.to_s.downcase.to_sym]
      end
    end

    test 'embedded do syntax' do
      assert Foo.new.call(:bar).success?
      assert_equal 'success: bar', Foo.new.call(:bar).value

      refute Foo.new.call(:baz).success?
      assert_equal :must_be_bar, Foo.new.call(:baz).failure
    end

    test 'embedded do syntax and inheritance' do
      assert DowncaseFoo.new.call(:BAR).success?
      assert_equal 'success: bar', DowncaseFoo.new.call(:bar).value

      refute DowncaseFoo.new.call(:baz).success?
      assert_equal :must_not_be_baz, DowncaseFoo.new.call(:baz).failure
    end
  end
end
