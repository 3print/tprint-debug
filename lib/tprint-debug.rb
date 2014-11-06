module TPrint
  DEBUG=2
  WARN=1
  LOG=0

  def self.colorize(text, color_code)
    "\033[#{color_code}m#{text}\033[0m"
  end

  def self.red(text)
      self.colorize(text, "31")
  end

  def self.green(text)
      self.colorize(text, "32")
  end

  def self.prepare_input inputs, opts={}
    depth = opts[:depth] || 0
    verbose = opts[:verbose]
    out = []
    padding = "  "*depth
    padding_plus = "  "*(depth+1)
    inputs = [inputs] unless inputs.is_a?(Array)
    inputs.each do |input|
      if String === input
        out << padding + "\"#{input}\""
      elsif Array === input
        if verbose
          if input.size > 0
            out << padding + "[ "
            input.each do |o|
              _out = prepare_input([o], verbose: verbose)
              out << padding_plus + "- " + _out.first
              out += _out[1..-1].map{|oo| padding_plus + "  " + oo}
            end
            out << padding + "]"
          else
            out << padding + "[]"
          end
        else
          out << padding + "[ " + input.map{|o| prepare_input([o], verbose: verbose)}.join(", ") + " ]"
        end
      elsif Hash === input
        out << padding + "{"
        input.each do |k, v|
          tmp = prepare_input([v], depth: depth, verbose: verbose)
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
    out
  end

  def self.log_level= level
    @log_level = level
  end

  def self.log_level
    lvl   = @log_level
    lvl ||= ENV['LOG_LEVEL']
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

  def self.output color, inputs, caller_infos
    inputs.each do |l|
      puts send(color, "#{caller_infos[0]}:#{caller_infos[1]} >>>\t" + l.gsub("\n", ''))
    end
  end

  def self.debug *inputs
    for_log_level DEBUG do
      _inputs = prepare_input inputs, verbose: @verbose
      caller_infos = @get_caller_infos.call()
      output 'red', _inputs, caller_infos
    end
    inputs
  end

  def self.debug_verbose *inputs
    being_verbose do
      debug *inputs
    end
    inputs
  end

  def self.log *inputs
    for_log_level LOG do
      _inputs = prepare_input inputs
      caller_infos = @get_caller_infos.call()
      output 'green', _inputs, caller_infos
    end
    inputs
  end

  def self.log_verbose *inputs
    being_verbose do
      log *inputs
    end
    inputs
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
    debug "#{msg} (#{time}s)"
    start_timer timer, false if relative
  end
end
