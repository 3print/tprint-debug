module TPrint
  DEBUG=2
  WARN=1
  LOG=0

  def self.kill_line text
    "\r\e[2K#{text}"
  end

  def self.colorize(text, color_code)
    "\033[#{color_code}m#{text}\033[0m"
  end

  def self.red(text)
      self.colorize(text, "31")
  end

  def self.green(text)
      self.colorize(text, "32")
  end

  def self.options_keys
    %w(verbose kill_line).map &:intern
  end

  def self.is_options? h
    h.is_a?(Hash) && h.keys.all?{|k| options_keys.include?(k)}
  end

  def self.prepare_input inputs, opts={}
    depth = opts[:depth] || 0
    options = Hash[*options_keys.map{|k| [k, opts[k]]}.flatten]
    out = []
    padding = "  "*depth
    padding_plus = "  "*(depth+1)
    inputs = [inputs] unless inputs.is_a?(Array)
    _inputs = []
    inputs.each do |input|
      if is_options? input
        options.update input
      else
        _inputs << input
      end
    end
    _inputs.each do |input|
      if String === input
        out << padding + "\"#{input}\""
      elsif Array === input
        if options[:verbose]
          if input.size > 0
            out << padding + "[ "
            input.each do |o|
              _out, null = prepare_input([o], options)
              out << padding_plus + "- " + _out.first
              out += _out[1..-1].map{|oo| padding_plus + "  " + oo}
            end
            out << padding + "]"
          else
            out << padding + "[]"
          end
        else
          out << padding + "[ " + input.map{|o| prepare_input([o], options).first}.join(", ") + " ]"
        end
      elsif Hash === input
        out << padding + "{"
        input.each do |k, v|
          tmp, null = prepare_input([v], {depth: depth}.update(options))
          out << padding_plus + "- #{k}: " + tmp.first
          tmp[1..-1].each do |vv|
             out << " " * (depth + 1 + "- #{k}: ".size) + vv
          end
        end
        out << padding + "}"
      else
        input = input.inspect if input.respond_to? :inspect
        input = input.to_s if input.respond_to? :to_s
        out << padding + input
      end
    end
    [out, options]
  end

  def self.log_level= level
    @log_level = level
  end

  def self.log_level
    lvl   = @log_level
    lvl ||= ENV['LOG_LEVEL'].to_i
    lvl ||= LOG if rails? && (Rails.env.production? || Rails.env.store?)
    lvl ||= DEBUG
    lvl
  end

  def self.for_log_level level
    yield if block_given? && log_level >= level
  end

  def self.being_verbose
    @verbose = true
    yield if block_given?
    @verbose = false
  end

  def self.rails?
    Object.const_defined?('Rails')
  end

  @get_caller_infos = Proc.new {
    idx = 0
    idx += 1 while caller[idx] =~ /tprint-debug.rb/
    infos = caller[idx].split(":")
    first = infos[0]
    first = first.gsub(Rails.root.to_s, '') if rails?
    [first, infos[1]]
  }

  def self.output color, inputs, caller_infos, options={}
    inputs.each do |l|
      out = send(color, "#{caller_infos[0]}:#{caller_infos[1]} >>>\t" + l.gsub("\n", ''))
      if options[:kill_line]
        @killed_previous = true
        STDOUT.print kill_line out
      else
        puts "\n" if @killed_previous
        puts out
        @killed_previous = false
      end
    end
  end

  def self.debug *inputs
    for_log_level DEBUG do
      _inputs, options = prepare_input inputs, verbose: @verbose
      caller_infos = @get_caller_infos.call()
      output 'red', _inputs, caller_infos, options
    end
    inputs
  end

  def self.debug_verbose *inputs
    debug *inputs, verbose: true
  end

  def self.log *inputs
    for_log_level LOG do
      _inputs, options = prepare_input inputs
      caller_infos = @get_caller_infos.call()
      output 'green', _inputs, caller_infos, options
    end
    inputs
  end

  def self.log_verbose *inputs
    log *inputs, verbose: true
  end

  def self.start_timer id=:default, verbose=true
    @@timers ||= {}
    @@timers[id] = Time.now
    debug("start timer #{id}") if verbose
  end

  def self.checkpoint msg, opts={}
    timer = opts[:timer] || :default
    relative = opts[:relative]
    time = Time.now - @@timers[timer]
    unit = "s"
    if time < 1000
      time *= 1000
      unit = "ms"
    end
    debug "#{msg} (#{time}#{unit})"
    start_timer timer, false if relative
  end
end
