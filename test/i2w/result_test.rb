require 'test_helper'

module I2w
  class ResultTest < ActiveSupport::TestCase
    test 'success result' do
      result = Result.success(:val)

      assert result.success?
      refute result.failure?
      assert_raises(NoMethodError) { result.errors }
      assert_raises(NoMethodError) { result.failure }
      assert_equal :val, result.value
      assert_equal :val, result.value_or(:fallback)
      assert result.and_then { |s| s }.success?
      assert_equal 'got: val', result.and_then { |s| "got: #{s}" }
                                     .or_else { |f| "nope: #{f}" }.value

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
      assert_raises(Result::ValueCalledOnFailureError) { result.value }
      assert result.and_then { |s| "got: #{s}" }.failure?
      assert_equal 'nope: err', result.and_then { "got: #{_1}" }
                                      .or_else { "nope: #{_1}" }.value

      side_effects = []
      assert result.and_tap { |s| side_effects << "got: #{s}" }.failure?
      assert_equal [], side_effects
    end

    test 'ValueCalledOnFailureError wrapping an exception failure' do
      exception = begin
                    Result.to_result { 1 / 0 }.value
                  rescue Result::Error => e
                    e
                  end

      assert_equal Result::ValueCalledOnFailureError, exception.class
      assert exception.cause.is_a?(ZeroDivisionError)
    end

    test 'ValueCalledOnFailureError for a normal failure' do
      exception = begin
                    Result.failure(:boom, foo: 'bar').value
                  rescue Result::Error => e
                    e
                  end

      assert_equal Result::ValueCalledOnFailureError, exception.class
      assert_equal "#value called on #<I2w::Result::Failure:failure boom, {:foo=>[{:error=>\"bar\"}]}>", exception.message
    end

    test '.to_result(&block)' do
      result = Result.to_result { 1 + 3 }

      assert_equal 4, result.value

      result = Result.to_result { Result.success(4) }

      assert_equal 4, result.value

      result = Result.to_result { 1 / 0 }

      assert_instance_of ZeroDivisionError, result.failure
      assert_equal({ base: ["divided by 0"] }, result.errors.to_hash)
    end

    test 'RescueAsFailure' do
      rescue_some = RescueAsFailure.new(ZeroDivisionError => -> { 'you broke it' })
      rescue_some.add('KeyError') { { _1.key => 'was not there'} }

      assert_raises(NameError) { rescue_some.call { foo } }

      result = rescue_some.call { 1 / 0 }
      assert_instance_of ZeroDivisionError, result.failure
      assert_equal({ base: ['you broke it'] }, result.errors.to_hash)

      result = rescue_some.call { {}.fetch(:foo) }
      assert_instance_of KeyError, result.failure
      assert_equal({ foo: ['was not there'] }, result.errors.to_hash)

      result = rescue_some.call { 'foo' }
      assert 'foo', result.value
    end

    test 'failure result with errors' do
      result = Result.failure(:input_invalid, attribute: ['required', 'missing'], foo: 'bar')

      refute result.errors.empty?
      assert result.errors.any?
      assert [:attribute, :foo], result.errors.attribute_names
      assert_equal 3, result.errors.count
      assert_equal ['required', 'missing'], result.errors.messages_for(:attribute)
      assert_equal({ attribute: ['required', 'missing'], foo: ['bar']}, result.errors.to_hash)
    end

    test 'failure#backtrace reports where the failure was called' do
      mod = Module.new do
        def self.a = b
        def self.b = c
        def self.c = Result.failure(:foo)
      end

      actual = mod.a.backtrace
      assert actual[2].include?("in `c'")
      assert actual[3].include?("in `b'")
      assert actual[4].include?("in `a'")
    end

    test 'nested exceptions are reachable via #cause' do
      mod = Module.new do
        def self.a
          Result.open_result do |r|
            r.calculation = b
          end
        end

        def self.b
          Result.to_result { 1 / 0 }
        end
      end

      result = mod.a
      assert result.failure?

      exception = assert_raises(Result::ValueCalledOnFailureError) do
        result.value
      end

      assert result.match_failure?(:calculation)
      assert result.match_failure?(ZeroDivisionError)

      assert_equal result, exception.result
      assert_match(/#value called on/, exception.message)
      assert_match(/:in `block in a'/, exception.backtrace[2])

      exception = exception.cause
      assert_instance_of Result::FailureError, exception
      assert_equal result.first_failure, exception.result
      assert_match(/:in `b'/, exception.backtrace[5])
      assert_match(/:in `block in a'/, exception.backtrace[6])

      exception = exception.cause
      assert_instance_of ZeroDivisionError, exception
      assert_match(/:in `block in b'/, exception.backtrace[1])
      assert_match(/:in `b'/, exception.backtrace[4])
      assert_match(/:in `block in a'/, exception.backtrace[5])

      exception = exception.cause
      assert_nil exception
    end

    class ObjWithErrors
      extend ActiveModel::Translation

      def errors
        ActiveModel::Errors.new(self).tap do |errors|
          errors.add(:attribute, 'is required')
          errors.add(:attribute, 'missing')
          errors.add(:foo, 'bar')
        end
      end
    end

    test 'failure(object with errors) uses that objects errors' do
      input = ObjWithErrors.new
      result = Result.failure(input)
      assert_equal input, result.failure
      assert_equal 3, result.errors.count
      assert_equal 3, result.failure.errors.count
      assert_equal ["Attribute is required", "Attribute missing", "Foo bar"], result.errors.full_messages
      assert_equal ["Attribute is required", "Attribute missing", "Foo bar"], result.failure.errors.full_messages
    end

    def result_match(result)
      Result.match(result) do |on|
        on.success                    { |success| "Success: #{success}" }
        on.failure(:invalid)          { |_failure, errors| "Input Invalid: #{errors.to_a.join(', ')}" }
        on.failure(:db)               { |failure, _errors| "Failure: #{failure}" }
        on.failure(ZeroDivisionError) { "Failure/0" }
        on.failure(:key1, :key2)      { |_failure, _errors, matched| "Failure on #{matched}" }
      end
    end

    test 'Result.match examples' do
      assert_equal result_match(Result.success(:val)), 'Success: val'
      assert_equal result_match(Result.failure(:invalid, { foo: ['bar'] })), 'Input Invalid: Foo bar'
      assert_equal result_match(Result.failure(:db)), 'Failure: db'
      assert_equal result_match(Result.to_result { 1/0 }), 'Failure/0'
      assert_equal result_match(Result.open_result { _1.key1 = Result.failure(:nope) }), 'Failure on key1'
      assert_equal result_match(Result.hash_result(key1: 1, key2: Result.failure(:nope))), 'Failure on key2'
    end

    test 'Result.match catch all failure' do
      actual = Result.match(Result.failure(:foo)) do |on|
                 on.failure { _1 }
               end

      assert_equal :foo, actual
    end

    test 'Result.match no match error' do
      actual = assert_raises(Result::MatchNotFoundError) { result_match(Result.failure(:foo)) }
      assert_equal "match not found for #<I2w::Result::Failure:failure foo, {}>", actual.message
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

    test 'hash_result failure' do
      actual = Result.hash_result do |h|
        h[:foo] = "FOO"
        h[:bar] = Result.success("BAR")
        failure = Result.failure("BAZ", error: "No Baz!")
        h[:baz] = failure
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
      assert_equal "BAZ", actual.first_failure.failure
      assert_equal :baz, actual.first_failure_key

      assert_raise(Result::ValueCalledOnFailureError) { actual.value }
      assert_raise(Result::ValueCalledOnFailureError) { actual.to_h }
      assert_raise(Result::ValueCalledOnFailureError) { actual.to_hash }

      side_effect = nil
      assert actual.and_then { side_effect = :hi }.failure?
      assert_nil side_effect

      side_effect = nil
      refute actual.and_then { side_effect = :hi }.success?
      assert_nil side_effect

      side_effect = nil
      assert actual.and_tap { side_effect = :hi }.failure?
      assert_nil side_effect

      side_effect = nil
      assert actual.or_else { side_effect = :hi }.success?
      assert :hi, side_effect

      assert_equal :fail, actual.value_or { :fail }

      assert_equal(['Error No Baz!'], actual.errors.to_a)
      refute_equal actual.backtrace, actual.first_failure.backtrace
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
      assert_raises(NoMethodError) { actual.failure }
      assert_raises(NoMethodError) { actual.errors }

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
      assert_equal [:f1, :f2], actual.failure_results.keys
      assert_equal [:s3], actual.success_results.keys
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

      assert_raise(Result::ValueCalledOnFailureError) { actual.foo }
    end

    test "open_result left, right syntax" do
      actual = Result.open_result do |r|
        r[:foo, :bar] = Result.failure(:foo)
      end

      assert actual.failure?
      assert_raise(Result::ValueCalledOnFailureError) { actual.bar }
      assert_equal :foo, actual.failures[:bar]
      assert_equal :foo, actual.failures.bar

      assert_equal :foo, actual.failure[:bar]
      assert_equal :foo, actual.failure.bar
    end
  end
end
