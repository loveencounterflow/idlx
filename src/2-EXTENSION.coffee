
############################################################################################################
# njs_util                  = require 'util'
# njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'IDLX/2-EXTENSION'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
echo                      = CND.echo.bind CND
rainbow                   = CND.rainbow.bind CND
#...........................................................................................................
ƒ                         = require 'flowmatic'
$new                      = ƒ.new
BASE                      = require './1-BASE'
NCR                       = require 'ncr'

#===========================================================================================================
# OPTIONS
#-----------------------------------------------------------------------------------------------------------
@options =
  'operator-2':           /// [ ⿰ ⿱ ⿴ ⿵ ⿶ ⿷ ⿸ ⿹ ⿺ ⿻ ◰ ] ///
  'operator-1':           /// [ ≈ ↻ ↔ ↕ ] ///


#===========================================================================================================
# CONSTRUCTOR
#-----------------------------------------------------------------------------------------------------------
@constructor = ( G, $ ) ->

  #---------------------------------------------------------------------------------------------------------
  simple_formula_matcher = new RegExp '^' + \
    $[ 'operator-2' ].source + \
    '(?:' + BASE.$[ 'cjk-chr' ].source + ')' + \
    '(?:' + BASE.$[ 'cjk-chr' ].source + ')' + \
    '$'

  #=========================================================================================================
  # RULES
  #---------------------------------------------------------------------------------------------------------
  G.formula         = -> ƒ.or     ( -> G.formula_bracketed ), ( -> G.formula_plain ), ( -> BASE.missing )
  G.formula_plain   = -> ƒ.or     ( -> G.formula_binary ), ( -> G.formula_unary )
  G.formula_unary   = -> ƒ.seq    ( -> G.operator_1 ), ( -> G.term )
  G.formula_binary  = -> ƒ.seq    ( -> G.operator_2 ), ( -> G.term ), ( -> G.term )
  G.term            = -> ƒ.or     ( -> G.term_precise ), ( -> G.term_similar )
  G.terms           = -> ƒ.repeat ( -> G.term ), 1
  G.term_precise    = -> ƒ.or     ( -> G.formula ), ( -> G.component )
  G.term_similar    = -> ƒ.seq    ( -> ƒ.string BASE.$[ 'similarity-mark' ] ), ( -> G.term_precise )
  G.component       = -> ƒ.or     ( -> BASE.$cjk_chr ), ( -> BASE.$ncr ), ( -> BASE.$curvy_line )

  #---------------------------------------------------------------------------------------------------------
  G._expression      = -> ƒ.or     ( -> BASE.$finish ), ( -> G.formula )

  #---------------------------------------------------------------------------------------------------------
  G.expression = ƒ.or -> ƒ.regex /.*/
    .onMatch ( match, state ) ->
      source = match[ 0 ]
      throw new Error "IDL expression cannot be empty" if source is ''
      return R                          if source is ( R = BASE.$[ 'finish-formula'   ] )
      return [ R ]                      if source is ( R = BASE.$[ 'missing-formula'  ] )
      return NCR.chrs_from_text source  if simple_formula_matcher.test source
      return G._expression.run source

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
    probes_and_matchers = [
      [ '↔正', [ '↔', '正', ], ]
      [ '↻正', [ '↻', '正', ], ]
      [ '↔≈匕', [ '↔', [ '≈', '匕' ] ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.formula_unary.run probe
      # debug result
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'binary formula' ] = ( test ) ->
    probes_and_matchers = [
      [ '⿱丶乂', [ '⿱', '丶', '乂', ], ]
      [ '⿺走⿹◰口戈日', [ '⿺', '走', [ '⿹', [ '◰', '口', '戈' ], '日' ] ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.formula_binary.run probe
      # debug result
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
      # debug result
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'bracketed formula' ] = ( test ) ->
    probes_and_matchers = [
      [ '(⿱北㓁允)', [ '⿱', [ '北', '㓁', '允' ] ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.formula_bracketed.run probe
      # debug result
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
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.formula.run probe
      # debug result
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
      ['≈匚', [ '≈', '匚' ], ]
      ['≈&jzr#xe174;', [ '≈', '&jzr#xe174;' ], ]
      ['≈非', [ '≈', '非' ], ]
      [ '⿱§&jzr#xe199;', [ '⿱', '§', '&jzr#xe199;' ], ]
      [ '〓', [ '〓' ], ]
      [ '⿺走⿹◰口〓日', [ '⿺', '走', [ '⿹', [ '◰', '口', '〓' ], '日' ] ], ]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = ƒ.new._delete_grammar_references G.expression.run probe
      # debug result
      test.eq result, matcher

  #---------------------------------------------------------------------------------------------------------
  G.tests[ 'failing expressions' ] = ( test ) ->
    probes = [
      '▽'
      '⿱爫⿸&jzr#xe217;'
      '⿰犭⿱臼u-cjk/7361'
      '⿱&jzr#xe186;田一'
      '⿱屮⿰艸'
      '⿱廿≈㒳巾'
      '⿰&jzr#xe219;⿱(⿰丿壬&cdp#x87c0;)'
      '⿸厂⿱(䀠犬)金'
      '⿴口⿰⿱&jzr#xe21a;𠃌𠃊&jzr#xe1d3;'
      '⿱&jzr#xe238;口小'
      '⿻弋&jzr#e103;'
      '⿻&jzr#xe120;&jzr#e103;'
      '⿰⿱&jzr#xe238;一木欠'
      '⿱䀠目开'
      '⿷匚丨&jzr#xe1f5;'
      '⿺⿸𠂋⿱〢一&jzr#xe150;⿱虫土'
      '⿰𣥚𣥚𣥚'
      '⿳辵𡕝'
      '⿰阝⿱一&jzr#xe109;冋'
      '⿰⿱冫冫&jzr#xe110;⿱&jzr#xe150;&jzr#xe150;'
      '⿰香业≈𠕒'
      '⿰⿱&jzr#xe139;二'
      '⿱亠⿻幺&jzr#xe119;十'
      '(⿰阝(⿸𠂆虍人)(⿸𠂆虍人))虒'
      '⿰魚(⿱亠口⺴)亮'
      ]
    for probe in probes
      whisper probe
      test.throws -> G.expression.run probe




############################################################################################################
ƒ.new.consolidate @



