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
      assert result.and_then { |s| s }.success?
      assert_equal 'got: val', result.and_then { |s| "got: #{s}" }.value
      assert_equal 'got: val', result.with_success { "got: #{_1.value}" }.with_failure { "nope out: #{_1.failure}" }.value

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
      assert_equal :fallback, result.value_or { :fallback }
      assert_equal [:err, :fallback], result.value_or { [_1.failure, :fallback] }
      assert_raises(Result::FailureTreatedAsSuccessError) { result.value }
      assert result.and_then { |s| "got: #{s}" }.failure?
      assert_equal 'nope out: err', result.with_success { "got: #{_1.value}" }.with_failure { "nope out: #{_1.failure}" }.value

      side_effects = []
      assert result.and_tap { |s| side_effects << "got: #{s}" }.failure?
      assert_equal [], side_effects
    end

    test 'wrap' do
      result = Result.wrap { 1 + 3 }

      assert_equal 4, result.value

      result = Result.wrap { 1 / 0 }

      assert result.failure.is_a?(ZeroDivisionError)
      assert_equal({ :message => "divided by 0" }, result.errors)
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

    test 'hash_result failure' do
      actual = Result.hash_result do |h|
        h[:foo] = "FOO"
        h[:bar] = Result.success("BAR")
        h[:baz] = Result.failure("BAZ", [error: "No Baz!"])
        h[:faz] = "FAZ" # not added
        raise 'this will not be reached'
      end

      refute actual.success?
      assert actual.failure?

      assert actual.success?(:foo)
      refute actual.failure?(:foo)
      assert actual.failure?(:baz)
      refute actual.success?(:baz)

      assert_equal({ foo: "FOO", bar: "BAR" }, actual.successes)
      assert_equal({ baz: "BAZ" }, actual.failures)
      assert_equal({ foo: "FOO", bar: "BAR", baz: "BAZ"}, actual.failure)

      assert_raise(Result::FailureTreatedAsSuccessError) { actual.value }
      assert_raise(Result::FailureTreatedAsSuccessError) { actual.to_h }
      assert_raise(Result::FailureTreatedAsSuccessError) { actual.to_hash }

      side_effect = nil
      assert actual.and_then { side_effect = :hi }.failure?
      assert_nil side_effect

      side_effect = nil
      refute actual.and_then { side_effect = :hi }.success?
      assert_nil side_effect

      side_effect = nil
      assert actual.and_tap { side_effect = :hi }.failure?
      assert_nil side_effect

      assert_equal :fail, actual.value_or { :fail }

      assert_equal([error: 'No Baz!'], actual.errors)
    end

    test 'hash_result success' do
      actual = Result.hash_result do |h|
        h[:foo] = "FOO"
        h[:bar] = Result.success("BAR")
      end

      assert actual.success?
      refute actual.failure?

      assert actual.success?(:foo)
      refute actual.failure?(:foo)
      assert actual.success?(:bar)
      refute actual.failure?(:bar)

      assert_equal({ foo: "FOO", bar: "BAR" }, actual.successes)
      assert_equal({}, actual.failures)
      assert_nil actual.failure

      assert_equal({ foo: "FOO", bar: "BAR" }, actual.value)
      assert_equal({ foo: "FOO", bar: "BAR" }, actual.to_h)
      assert_equal({ foo: "FOO", bar: "BAR" }, actual.to_hash)

      side_effect = nil
      refute actual.and_then { side_effect = :hi }.failure?
      assert_equal :hi, side_effect

      actual = actual.and_tap { side_effect = :hi }
      assert_equal({ foo: "FOO", bar: "BAR" }, actual.value)
      assert_equal :hi, side_effect

      actual = actual.and_then { :hi }
      assert :hi, actual.value

      assert actual.errors.empty?
    end

    test "hash_result[left, right]= stores success on left, failure on right" do
      actual = Result.hash_result do |h|
        h[:success, :failure] = 'Success!'
        h[:success, :failure] = Result.failure('Failure!')
        raise 'this will not be reached'
      end

      assert_equal({ success: 'Success!', failure: 'Failure!'}, actual.failure)
    end

    test "hash_result with no args returns HashResult with no early return on failure (because no block)" do
      actual = Result.hash_result

      actual[:f1] = Result.failure(1)
      actual[:f2] = Result.failure(2)
      actual[:s3] = Result.success(3)

      assert_equal({ f1: 1, f2: 2, s3: 3}, actual.failure)
      assert_equal({ f1: 1, f2: 2 }, actual.failures)
    end

    test "hash_result with hash arg returns HashResult for arg" do
      actual = Result.hash_result(f1: Result.failure(1), f2: Result.failure(2), s3: Result.success(3))

      assert_equal({ f1: 1, f2: 2, s3: 3}, actual.failure)
      assert_equal({ f1: 1, f2: 2 }, actual.failures)
    end

    test "open_result success" do
      actual = Result.open_result do |r|
        r.foo = Result.success(:foo)
      end
      assert actual.success?
      assert_equal :foo, actual[:foo]
      assert_equal :foo, actual.value[:foo]
      assert_equal :foo, actual.value.foo
      assert_equal({ foo: :foo }, actual.to_h)
      assert_equal :foo, actual.foo
    end

    test "open_result failure" do
      actual = Result.open_result do |r|
        r.bar = :bar
        r.foo = Result.failure(:foo)
      end
      assert actual.failure?

      assert_equal :foo, actual.failures[:foo]
      assert_equal :foo, actual.failures.foo
      refute actual.failures.key?(:bar)

      assert_equal :foo, actual.failure[:foo]
      assert_equal :foo, actual.failure.foo
      assert_equal :bar, actual.failure[:bar]
      assert_equal :bar, actual.failure.bar

      assert_raise(Result::FailureTreatedAsSuccessError) { actual.foo }
    end

    test "open_result left, right syntax" do
      actual = Result.open_result do |r|
        r[:foo, :bar] = Result.failure(:foo)
      end

      assert actual.failure?
      assert_raise(Result::FailureTreatedAsSuccessError) { actual.bar }
      assert_equal :foo, actual.failures[:bar]
      assert_equal :foo, actual.failures.bar

      assert_equal :foo, actual.failure[:bar]
      assert_equal :foo, actual.failure.bar
    end
  end
end
