
############################################################################################################
# njs_util                  = require 'util'
# njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'IDLX/XXXXXXXX'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
echo                      = TRM.echo.bind TRM
rainbow                   = TRM.rainbow.bind TRM
#...........................................................................................................
BNP                       = require 'coffeenode-bitsnpieces'
ƒ                         = require 'flowmatic'
$new                      = ƒ.new
# CHR                       = require './3-chr'
# XRE                       = require './XRE'
BASE                      = require './1-BASE'


#===========================================================================================================
# OPTIONS
#-----------------------------------------------------------------------------------------------------------
@options =
  # 'assignment-mark':      ':'
  # 'comment-mark':         '#'
  # 'comment-text':         /// ^ [^ \n ]* ///
  # 'finish-formula':       '●'
  # 'operator-2':           /// (?: [⿰⿱⿴⿵⿶⿷⿸⿹⿺⿻] | \ue01f | &jzr\#xe01f; ) ///
  # 'operator-1':           /// (?: [\ue018-\ue01c] | &jzr\#xe01[89abc] ) ; ///
  'operator-2':           /// [ ⿰ ⿱ ⿴ ⿵ ⿶ ⿷ ⿸ ⿹ ⿺ ⿻ ◰ ] ///
  'operator-1':           /// [ ↻ ↔ ↕ ] ///



  # # #-----------------------------------------------------------------------------------------------------------
  # # @cjkg_chr_kernel_matcher = ///
  # #   #{@missing_formula_matcher}
  # #   | #{@curvy_line_matcher}
  # #   | #{@ncr_kernel_matcher.source}
  # #   | #{@cjk_chr_kernel_matcher.source} ///g

  # # #-----------------------------------------------------------------------------------------------------------
  # # @cjk_chr_matcher         = /// ^ (?:  #{@cjk_chr_kernel_matcher.source} ) ///
  # # @cjkg_chr_matcher        = /// ^ (?: #{@cjkg_chr_kernel_matcher.source} ) ///

# #===========================================================================================================
# # GRAMMAR
# #-----------------------------------------------------------------------------------------------------------
# @formula         = ( π ) -> return Π.choice      π, @formula_bracketed, @formula_plain, @missing
# @formula_plain   = ( π ) -> return Π.choice      π, @formula_binary, @formula_unary
# @operator_1      = ( π ) -> return Π.match       π, @operator_1_matcher
# @terms           = ( π ) -> return Π.one_or_more π, @term
# #...........................................................................................................
# @formula_unary   = ( π ) -> return stash 'formula/plain', Π.sequence π, @operator_1, @term
# @formula_binary  = ( π ) -> return stash 'formula/plain', Π.sequence π, @operator_2, @term, @term

# #-----------------------------------------------------------------------------------------------------------
# @formula_bracketed = ( π ) ->
#   [ left_bracket
#     operator
#     terms
#     right_bracket ] = Π.sequence π, '(', @operator_2, @terms, ')'
#   #.........................................................................................................
#   if ( length_of terms ) < 2
#     bye "operator needs at least two arguments; unable to parse #{rpr π[ 'source' ]}"
#   #.........................................................................................................
#   return [ 'formula/bracketed'
#     left_bracket
#     operator
#     terms...
#     right_bracket ]


#===========================================================================================================
# CONSTRUCTOR
#-----------------------------------------------------------------------------------------------------------
@constructor = ( G, $ ) ->

  #=========================================================================================================
  # RULES
  #---------------------------------------------------------------------------------------------------------
  G.expression      = -> ƒ.or     ( -> BASE.$finish ), ( -> G.formula )
  G.formula         = -> ƒ.or     ( -> G.formula_bracketed ), ( -> G.formula_plain ), ( -> BASE.missing )
  G.formula_plain   = -> ƒ.or     ( -> G.formula_binary ), ( -> G.formula_unary )
  G.formula_unary   = -> ƒ.seq    ( -> G.operator_1 ), ( -> G.term )
  G.formula_binary  = -> ƒ.seq    ( -> G.operator_2 ), ( -> G.term ), ( -> G.term )
  G.term            = -> ƒ.or     ( -> G.term_precise ), ( -> G.term_similar )
  G.terms           = -> ƒ.repeat ( -> G.term ), 1
  G.term_precise    = -> ƒ.or     ( -> G.formula ), ( -> G.component )
  G.term_similar    = -> ƒ.seq    ( -> ƒ.string BASE.$[ 'similarity-mark' ] ), ( -> G.term_precise )
  G.component       = -> ƒ.or     ( -> BASE.$cjk_chr ), ( -> BASE.$ncr ), ( -> BASE.$curvy_line )

  # #---------------------------------------------------------------------------------------------------------
  # G.term = ƒ.or -> ( ƒ.regex $[ 'operator-1' ] )
  #   .onMatch ( match, state ) -> return match[ 0 ]
  #   .describe 'EXTENSION/term'

  #---------------------------------------------------------------------------------------------------------
  G.operator_1 = ƒ.or -> ( ƒ.regex $[ 'operator-1' ] )
    .onMatch ( match, state ) -> return match[ 0 ]
    # .describe 'EXTENSION/operator-1'

  #---------------------------------------------------------------------------------------------------------
  G.operator_2 = ƒ.or -> ( ƒ.regex $[ 'operator-2' ] )
    .onMatch ( match, state ) -> return match[ 0 ]
    .describe 'EXTENSION/operator-2'

  #---------------------------------------------------------------------------------------------------------
  G.formula_bracketed = ƒ.seq ( ƒ.string '(' ), ( -> G.operator_2 ), ( -> G.terms ), ( ƒ.string ')' )
    .onMatch ( match, state ) -> return match[ 1 ... match.length - 1 ]


  #=========================================================================================================
  # TESTS
  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'unary formula' ] = ( test ) ->
    # debug $[ 'operator-1' ]
    # debug $[ 'operator-2' ]
    # debug ( name for name of G ).sort()
    probes_and_matchers = [
      [ '↔正', [ '↔', '正', ], ]
      [ '↻正', [ '↻', '正', ], ]
      [ '↔≈匕', [ '↔', [ '≈', '匕' ] ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.formula_unary.run probe
      debug result
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'binary formula' ] = ( test ) ->
    probes_and_matchers = [
      [ '⿱丶乂', [ '⿱', '丶', '乂', ], ]
      [ '⿺走⿹◰口戈日', [ '⿺', '走', [ '⿹', [ '◰', '口', '戈' ], '日' ] ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.formula_binary.run probe
      debug result
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'plain formula' ] = ( test ) ->
    probes_and_matchers = [
      [ '↻正', [ '↻', '正', ], ]
      [ '↔≈匕', [ '↔', [ '≈', '匕' ] ], ]
      [ '↔正', [ '↔', '正', ], ]
      [ '⿱丶乂', [ '⿱', '丶', '乂', ], ]
      [ '⿺走⿹◰口戈日', [ '⿺', '走', [ '⿹', [ '◰', '口', '戈' ], '日' ] ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.formula_plain.run probe
      debug result
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'bracketed formula' ] = ( test ) ->
    probes_and_matchers = [
      [ '(⿱北㓁允)', [ '⿱', [ '北', '㓁', '允' ] ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.formula_bracketed.run probe
      debug result
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'formula' ] = ( test ) ->
    probes_and_matchers = [
      [ '↻正', [ '↻', '正', ], ]
      [ '↔≈匕', [ '↔', [ '≈', '匕' ] ], ]
      [ '↔正', [ '↔', '正', ], ]
      [ '⿱丶乂', [ '⿱', '丶', '乂', ], ]
      [ '⿺走⿹◰口戈日', [ '⿺', '走', [ '⿹', [ '◰', '口', '戈' ], '日' ] ], ]
      [ '(⿱北㓁允)', [ '⿱', [ '北', '㓁', '允' ] ], ]
      # [ '●', [ '⿱', [ '北', '㓁', '允' ] ], ]
      # [ '〓', [ '⿱', [ '北', '㓁', '允' ] ], ]
      # [ '⿺走⿹◰口〓日', [ '⿺', '走', [ '⿹', [ '◰', '口', '戈' ], '日' ] ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.formula.run probe
      debug result
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'expression' ] = ( test ) ->
    probes_and_matchers = [
      [ '↻正', [ '↻', '正', ], ]
      [ '↔≈匕', [ '↔', [ '≈', '匕' ] ], ]
      [ '↔正', [ '↔', '正', ], ]
      [ '⿱丶乂', [ '⿱', '丶', '乂', ], ]
      [ '⿺走⿹◰口戈日', [ '⿺', '走', [ '⿹', [ '◰', '口', '戈' ], '日' ] ], ]
      [ '(⿱北㓁允)', [ '⿱', [ '北', '㓁', '允' ] ], ]
      [ '●', '●', ]
      # [ '〓', [ '⿱', [ '北', '㓁', '允' ] ], ]
      # [ '⿺走⿹◰口〓日', [ '⿺', '走', [ '⿹', [ '◰', '口', '戈' ], '日' ] ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.expression.run probe
      debug result
      test.eq result, matcher



############################################################################################################
ƒ.new.consolidate @



