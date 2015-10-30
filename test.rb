require './lib/tprint-debug.rb'

raise unless TPrint.is_options?(:verbose=>nil, :kill_line=>nil)
TPrint.print 'foo'
TPrint.print 'foo', color: "blue"
TPrint.print 'foo', color: "pink"
TPrint.log 'foo'
TPrint.debug 'foo'
TPrint.debug [:a, "b", "1"]
TPrint.debug [:a, "b", "1"], verbose: true
TPrint.debug_verbose [:a, "b", "1"]
TPrint.debug [:a, "b", "1"], {c: {foo: 'bar'}, miaou: 'cuicui'}, "baz"
TPrint.debug_verbose [:a, "b", "1"], {c: {foo: 'bar'}, miaou: 'cuicui'}, "baz"
TPrint.debug [:a, "b", "1"], {c: {foo: 'bar'}, miaou: 'cuicui'}, "baz", verbose: true
TPrint.debug [[1, 2], [3, 4]]
TPrint.debug_verbose [[1, 2], [3, 4]]
TPrint.debug_verbose 1, 2
TPrint.log 'You should not see me', kill_line: true
sleep 0.5
TPrint.log 'You should not see me 2', kill_line: true
sleep 0.5
TPrint.log 'You should see me', kill_line: true

TPrint.debug_verbose 1, 2
