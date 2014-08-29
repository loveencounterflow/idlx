
############################################################################################################
# njs_util                  = require 'util'
# njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'IDLX/1-BASE'
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


#===========================================================================================================
# OPTIONS
#-----------------------------------------------------------------------------------------------------------
@options =
  # 'assignment-mark':      ':'
  # 'comment-mark':         '#'
  # 'comment-text':         /// ^ [^ \n ]* ///
  'finish-formula':       '●'
  'missing-formula':      '〓'
  'mapped-cp':            '▽'
  'ncr':                  /// & [a-z0-9]* \# (?: x [a-f0-9]+ | [0-9]+ ) ; ///
  # 'ncr':                  /// ^ #{$.ncr-kernel.source} ///
  'operator-2':           /// [⿰⿱⿴⿵⿶⿷⿸⿹⿺⿻] ///
  'operator-3':           /// [⿲⿳] ///
  'similarity-mark':      '≈'
  'curvy-line':           '§'
  #-----------------------------------------------------------------------------------------------------------
  'cjk-chr': ///
    [ \u2e80-\u2eff
      \u2f00-\u2fdf
      \u3005-\u3007
      \u3013
      \u3021-\u3029
      \u3038-\u303d
      \u31c0-\u31ef
      \u3400-\u4dbf
      \u4e00-\u9fff
      \uf900-\ufaff ]
      | (?: [\ud840-\ud868][\udc00-\udfff]|\ud869[\udc00-\uded6]                       ) # \u(20000)-\u(2a6d6)
      | (?: [\ud86a-\ud86c][\udc00-\udfff]|\ud869[\udf00-\udfff]|\ud86d[\udc00-\udf3f] ) # \u(2a700)-\u(2b73f)
      | (?: \ud86d[\udf40-\udfff]|\ud86e[\udc00-\udc1d]                                ) # \u(2b740)-\u(2b81d)
      | (?: \ud87e[\udc00-\ude1d]                                                      ) # \u(2f800)-\u(2fa1d)
      ///g

  # #-----------------------------------------------------------------------------------------------------------
  # @cjkg_chr_kernel_matcher = ///
  #   #{@missing_formula_matcher}
  #   | #{@curvy_line_matcher}
  #   | #{@ncr_kernel_matcher.source}
  #   | #{@cjk_chr_kernel_matcher.source} ///g

  # #-----------------------------------------------------------------------------------------------------------
  # @cjk_chr_matcher         = /// ^ (?:  #{@cjk_chr_kernel_matcher.source} ) ///
  # @cjkg_chr_matcher        = /// ^ (?: #{@cjkg_chr_kernel_matcher.source} ) ///



#===========================================================================================================
# CONSTRUCTOR
#-----------------------------------------------------------------------------------------------------------
@constructor = ( G, $ ) ->

  #=========================================================================================================
  # RULES
  #---------------------------------------------------------------------------------------------------------
  G.$curvy_line     = -> ƒ.or ( ƒ.string $[ 'curvy-line' ] )
  G.$finish         = -> ƒ.or ( ƒ.string $[ 'finish-formula' ] )
  G.component       = -> ƒ.or ( -> G.$cjk_chr ), ( -> G.$ncr ), ( -> G.$curvy_line )
  G.expression      = -> ƒ.or ( -> G.$finish ), ( -> G.formula )
  G.formula         = -> ƒ.or ( -> G.formula_3 ), ( -> G.formula_2 ), ( -> G.missing )
  G.formula_2       = -> ƒ.seq ( -> G.$operator_2 ), ( -> G.term ), ( -> G.term )
  G.formula_3       = -> ƒ.seq ( -> G.$operator_3 ), ( -> G.term ), ( -> G.term ), ( -> G.term )
  G.missing         = -> ƒ.or ( ƒ.string $[ 'missing-formula' ] )
  G.term            = -> ƒ.or ( -> G.term_precise ), ( -> G.term_similar )
  G.term_precise    = -> ƒ.or ( -> G.formula ), ( -> G.component )
  G.term_similar    = -> ƒ.seq ( ƒ.string $[ 'similarity-mark' ] ), ( -> G.term_precise )

  #---------------------------------------------------------------------------------------------------------
  G.$ncr = ƒ.or -> ( ƒ.regex $[ 'ncr' ] )
    .onMatch ( match, state ) -> return match[ 0 ]

  #---------------------------------------------------------------------------------------------------------
  G.$cjk_chr = ƒ.or -> ( ƒ.regex $[ 'cjk-chr' ] )
    .onMatch ( match, state ) -> return match[ 0 ]

  #---------------------------------------------------------------------------------------------------------
  G.$operator_2 = ƒ.or -> ( ƒ.regex $[ 'operator-2' ] )
    .onMatch ( match, state ) -> return match[ 0 ]

  #---------------------------------------------------------------------------------------------------------
  G.$operator_3 = ƒ.or -> ( ƒ.regex $[ 'operator-3' ] )
    .onMatch ( match, state ) -> return match[ 0 ]
    .describe 'BASE/operator-3'



  #=========================================================================================================
  # TESTS
  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'operator 2' ] = ( test ) ->
    probes_and_matchers = [
      [ '⿰', '⿰', ]
      [ '⿴', '⿴', ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.$operator_2.run probe
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'operator 3' ] = ( test ) ->
    probes_and_matchers = [
      [ '⿳', '⿳', ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.$operator_3.run probe
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'CJK character' ] = ( test ) ->
    probes_and_matchers = [
      [ '㐀', '㐀', ]
      [ '𠀎', '𠀎', ]
      [ '𪜀', '𪜀', ]
      [ '〇', '〇', ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.$cjk_chr.run probe
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'similarity term' ] = ( test ) ->
    probes_and_matchers = [
      [ '≈㐀', [ '≈', '㐀', ], ]
      [ '≈𠀎', [ '≈', '𠀎', ], ]
      [ '≈𪜀', [ '≈', '𪜀', ], ]
      [ '≈〇', [ '≈', '〇', ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.term_similar.run probe
      # debug JSON.stringify result
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'precise term' ] = ( test ) ->
    probes_and_matchers = [
      [ '⿻串一', [ '⿻', '串', '一', ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.term_precise.run probe
      # debug JSON.stringify result
      # debug result
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'formula 2' ] = ( test ) ->
    probes_and_matchers = [
      [ '⿻串一', [ '⿻', '串', '一', ], ]
      [ '⿻串⿰立风', [ '⿻', '串', [ '⿰', '立', '风' ] ], ]
      [ '⿻串⿰立&jzr#x1234;', [ '⿻', '串', [ '⿰', '立', '&jzr#x1234;' ] ], ]
      [ '⿻串⿳立风𠃓', [ '⿻', '串', [ '⿳', '立', '风', '𠃓' ] ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.formula_2.run probe
      # debug JSON.stringify result
      # debug result
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'formula 3' ] = ( test ) ->
    probes_and_matchers = [
      [ '⿳立风𠃓', [ '⿳', '立', '风', '𠃓' ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.formula_3.run probe
      # debug JSON.stringify result
      # debug result
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'formula' ] = ( test ) ->
    probes_and_matchers = [
      [ '⿻串一', [ '⿻', '串', '一', ], ]
      [ '⿻串⿰立风', [ '⿻', '串', [ '⿰', '立', '风' ] ], ]
      [ '⿻串⿳立风𠃓', [ '⿻', '串', [ '⿳', '立', '风', '𠃓', ] ], ]
      # [ '●', [ '⿱', [ '北', '㓁', '允' ] ], ]
      # [ '⿻串(⿱立风𠃓)', [ '⿻', '串', [ '⿳', '立', '风', '𠃓', ] ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.formula.run probe
      # debug JSON.stringify result
      # debug result
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'expression' ] = ( test ) ->
    probes_and_matchers = [
      [ '⿻串一', [ '⿻', '串', '一', ], ]
      [ '⿻串⿰立风', [ '⿻', '串', [ '⿰', '立', '风' ] ], ]
      [ '⿻串⿳立风𠃓', [ '⿻', '串', [ '⿳', '立', '风', '𠃓', ] ], ]
      [ '●', '●', ]
      # [ '⿻串(⿱立风𠃓)', [ '⿻', '串', [ '⿳', '立', '风', '𠃓', ] ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.expression.run probe
      # debug JSON.stringify result
      # debug result
      test.eq result, matcher


############################################################################################################
ƒ.new.consolidate @



