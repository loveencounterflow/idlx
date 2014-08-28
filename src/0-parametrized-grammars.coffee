

# ###

# # Demo: Parametrized Grammars

# ## Rationale

# In this module, we want to explore how to parametrize grammars.

# Let's say you've found a grammar `G` that parses nested lists, as in `[ 1, [ 2, 3, [ 4 ], 5 ]]`. Obviously,
# if the grammar works for square brackets, it should not only work for pointy brackets, too, and for any pair
# of distinct characters `( o, c )`. Likewise, the mark that separates elements could conceivably any old
# character, as long as it fits into the general setup of the rest of the language. Finally, what is allowed
# to appear as e single element in such a construct is a 'little language' (a grammar, a rule) in its own
# right—it's easy to see that if this version works for list literals à la what's sketched aboved, it can,
# mutatis mutandis, also serve to parse set literals like `{ 1, { 2, 3, { 4 }, 5 }}` and POD literals like
# `{ a: 1, { b: 2, c: 3, { d: 4 }, e: 5 }}`.

# ## Naming Conventions

# In non-parametrized ('direct', or 'constant') grammars, you bind all your rules to `@` (`this`) on the
# module level. You should start all rules that are part of the grammar proper (i.e. those that produce
# use the Arabika `new` module to produce AST nodes that are in line with the
# [SpiderMonkey Parser API](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/SpiderMonkey/Parser_API))
# with a lower case Latin letter (although nothing keeps you from using other scripts if you feel like it).

# Grammar rules should generally be kept as short as possible—typically, they're one-liners (plus an
# `.onMatch()` handler, also often on a single line). This is mainly because the `packrattle` parser is wont
# to throw hard-to-interpret error messages that do not include references to the source code line that caused
# the trouble; it is therefore of paramount importance to break down the parsing process into many small
# pieces with focussed concerns, each of which should be individually tested in the `$TESTS` section (see
# below); that way, it's easier to narrow down faulty grammar rules.

# As a side effect of working with *lots* of very simple rules, it's not always convenient to have all rules
# produce full-blown SM Parser API nodes; often, a simple list or a string is all the result you need. Also,
# helper functions, options objects and data collections are sometimes needed to sort things out in an
# organized fashion. To help consumers identify exactly which rules produce Parser API nodes, the convention
# is to give all such methods names that start with a lower case Latin letter; all methods and other objects
# that serve other purposes should start with a `$` (dollar sign).

# In addition, you can `require` additional module or define helper functions on the module level (as shown
# below with the `translate()` method).

# ###



# ############################################################################################################
# TRM                       = require 'coffeenode-trm'
# rpr                       = TRM.rpr.bind TRM
# badge                     = '﴾0-parametrized-grammars﴿'
# log                       = TRM.get_logger 'plain',     badge
# info                      = TRM.get_logger 'info',      badge
# whisper                   = TRM.get_logger 'whisper',   badge
# alert                     = TRM.get_logger 'alert',     badge
# debug                     = TRM.get_logger 'debug',     badge
# warn                      = TRM.get_logger 'warn',      badge
# help                      = TRM.get_logger 'help',      badge
# echo                      = TRM.echo.bind TRM
# rainbow                   = TRM.rainbow.bind TRM
# #...........................................................................................................
# π                         = require 'coffeenode-packrattle'
# # BNP                       = require 'coffeenode-bitsnpieces'
# FLOWMATIC                 = require 'flowmatic'
# $new                      = FLOWMATIC.new
# XRE                       = require './XRE'


# #-----------------------------------------------------------------------------------------------------------
# @$ =
#   ### a RegEx that matches one digit: ###
#   'digit':              /[0123456789]/
#   ### a RegEx that matches one sign (to act as plus and minus): ###
#   'sign':               /[-+]/
#   ### an optional POD that maps from custom digits to ASCII digits: ###
#   'digits':             null
#   ### an optional POD that maps from custom signs to ASCII signs: ###
#   'signs':              null

# #-----------------------------------------------------------------------------------------------------------
# @$new = $new.new @

# #-----------------------------------------------------------------------------------------------------------
# @$new.$digits = ( G, $ ) ->
#   R = π.alt -> π.repeat $[ 'digit' ], 1
#   R = R.onMatch ( match ) ->
#     # whisper match
#     ( submatch[ 0 ] for submatch in match ).join ''
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @$new.$sign = ( G, $ ) ->
#   R = π.optional $[ 'sign' ]
#   R = R.onMatch ( match ) -> if match.length is 0 then '' else match[ 0 ]
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @$new.$literal = ( G, $ ) ->
#   R = π.alt -> π.seq G.$sign, G.$digits
#   # R = R.onMatch ( match ) -> match.join ''
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @$new.expression = ( G, $ ) ->
#   R = π.alt -> G.$literal
#   R = R.onMatch ( match ) ->
#     [ sign, digits, ] = match
#     sign    = translate   sign,  sign_mapping if   sign.length > 0 and (  sign_mapping = $[  'signs' ] )?
#     digits  = translate digits, digit_mapping if digits.length > 0 and ( digit_mapping = $[ 'digits' ] )?
#     raw     = sign + digits
#     value   = parseInt raw, 10
#     return $new.literal 'number', raw, value
#   return R


# #===========================================================================================================
# # HELPERS
# #-----------------------------------------------------------------------------------------------------------
# translate = ( text, mapping ) ->
#   ### TAINT does not honour codepoints beyond 0xffff ###
#   R = []
#   for original_chr in text
#     new_chr = mapping[ original_chr ]
#     throw new Error "unable to translate #{rpr original_chr}" unless new_chr?
#     R.push new_chr
#   return R.join ''


# #===========================================================================================================
# # APPLY NEW TO MODULE
# #-----------------------------------------------------------------------------------------------------------
# ### Run `@$new` to make `@` (`this`) an instance of this grammar with default options: ###
# @$new @, null



# #===========================================================================================================
# @$TESTS =

#   #---------------------------------------------------------------------------------------------------------
#   '$digits (default G): parses a sequence of ASCII digits': ( test ) ->
#     G = @
#     probes_and_results = [
#       [ '1234',         '1234',       ]
#       [ '0',            '0',          ]
#       ]
#     for [ probe, result, ] in probes_and_results
#       test.eq ( G.$digits.run probe ), result

#   #---------------------------------------------------------------------------------------------------------
#   '$digits (default G): rejects anything but ASCII digits': ( test ) ->
#     G = @
#     probes = [ '', 'x0', ]
#     for probe in probes
#       test.throws ( -> G.$digits.run probe ), /Expected/

#   #---------------------------------------------------------------------------------------------------------
#   '$new: returns grammar with custom options': ( test ) ->
#     G = @$new digit: /[〇一二三四五六七八九]/
#     test.eq G[ '$' ], { digit: /[〇一二三四五六七八九]/, sign: /[-+]/, digits: null, signs: null }
#     for name in [ '$digits', '$literal', 'expression', ]
#       ### TAINT this is a very shallow test: ###
#       test.ok G[ name ]?

#   #---------------------------------------------------------------------------------------------------------
#   '$digits (custom G): parses a sequence of Chinese digits': ( test ) ->
#     options =
#       digit:      /[〇一二三四五六七八九]/
#       digits:
#         '〇':        '0'
#         '一':        '1'
#         '二':        '2'
#         '三':        '3'
#         '四':        '4'
#         '五':        '5'
#         '六':        '6'
#         '七':        '7'
#         '八':        '8'
#         '九':        '9'
#     G = @$new options
#     probes_and_results = [
#       [ '一二三四',         '一二三四',         ]
#       [ '〇六三',           '〇六三',               ]
#       ]
#     for [ probe, result, ] in probes_and_results
#       test.eq ( G.$digits.run probe ), result

#   #---------------------------------------------------------------------------------------------------------
#   '$digits (default G): rejects anything but ASCII digits': ( test ) ->
#     G = @
#     probes = [
#       ''
#       'x0'
#       ]
#     for probe in probes
#       test.throws ( -> G.$digits.run probe ), /Expected/

#   #---------------------------------------------------------------------------------------------------------
#   '$literal (default G): parses a sequence of optional sign, ASCII digits': ( test ) ->
#     G = @
#     probes_and_results = [
#       [ '1234',         [ '',   '1234',   ],    ]
#       [ '0',            [ '',   '0',      ],    ]
#       [ '+1234',        [ '+',  '1234',   ],    ]
#       [ '+0',           [ '+',  '0',      ],    ]
#       [ '-1234',        [ '-',  '1234',   ],    ]
#       [ '-0',           [ '-',  '0',      ],    ]
#       ]
#     for [ probe, result, ] in probes_and_results
#       test.eq ( G.$literal.run probe ), result

#   #---------------------------------------------------------------------------------------------------------
#   'expression (default G): parses an integer, returns node with value': ( test ) ->
#     G = @
#     probes_and_results = [
#       [ '1234',           $new.literal 'number', '1234',   1234    ]
#       [ '0',              $new.literal 'number', '0',      0       ]
#       [ '+1234',          $new.literal 'number', '+1234',  +1234   ]
#       [ '+0',             $new.literal 'number', '+0',     +0      ]
#       [ '-1234',          $new.literal 'number', '-1234',  -1234   ]
#       [ '-0',             $new.literal 'number', '-0',     -0      ]
#       ]
#     for [ probe, result, ] in probes_and_results
#       test.eq ( G.expression.run probe ), result

#   #---------------------------------------------------------------------------------------------------------
#   'expression (custom G): parses an integer written with CJK digits, returns node with value': ( test ) ->
#     options =
#       digit:      /[〇一二三四五六七八九]/
#       sign:       /[PM]/
#       digits:     { '〇':'0','一':'1','二':'2','三':'3','四':'4','五':'5','六':'6','七':'7','八':'8','九':'9',}
#       signs:      { 'M': '-', 'P': '+', }
#     G = @$new options
#     probes_and_results = [
#       [ '一二三四',    $new.literal 'number', '1234',   1234    ]
#       [ '〇',         $new.literal 'number', '0',      0       ]
#       [ 'P一二三四',   $new.literal 'number', '+1234',  +1234   ]
#       [ 'P〇',        $new.literal 'number', '+0',     +0      ]
#       [ 'M一二三四',   $new.literal 'number', '-1234',  -1234   ]
#       [ 'M〇',        $new.literal 'number', '-0',     -0      ]
#       ]
#     for [ probe, result, ] in probes_and_results
#       test.eq ( G.expression.run probe ), result


