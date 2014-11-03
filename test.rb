require './lib/tprint-debug.rb'

TPrint.log 'foo'
TPrint.debug 'foo'
TPrint.debug [:a, "b", "1"], {c: {foo: 'bar'}, miaou: 'cuicui'}, "baz"
TPrint.debug_verbose [:a, "b", "1"], {c: {foo: 'bar'}, miaou: 'cuicui'}, "baz"
