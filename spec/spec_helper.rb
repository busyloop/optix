require 'simplecov'
SimpleCov.start

RSpec::Matchers.define :have_stdout do |regex|
  define_method :has_stdout? do |actual|
    regex = /^#{Regexp.escape(regex)}$/ if regex.is_a?(String)

    $stdout = StringIO.new
    actual.call
    $stdout.rewind
    captured = $stdout.read

    $stdout = STDOUT
    captured =~ regex
  end
  match { |actual| has_stdout?(actual) }
end


def capture_streams(stdin_str = '')
  begin
    require 'stringio'
    $o_stdin, $o_stdout, $o_stderr = $stdin, $stdout, $stderr
    $stdin, $stdout, $stderr = StringIO.new(stdin_str), StringIO.new, StringIO.new
    yield
    {:stdout => $stdout.string, :stderr => $stderr.string}
  ensure
    $stdin, $stdout, $stderr = $o_stdin, $o_stdout, $o_stderr
  end
end
