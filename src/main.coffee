



############################################################################################################
LODASH                    = require 'lodash'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'IDLX'
warn                      = CND.get_logger 'warn',    badge
#...........................................................................................................
BASE                      = require './1-BASE'
EXTENSION                 = require './2-EXTENSION'


#-----------------------------------------------------------------------------------------------------------
@parse = ( text ) ->
  return EXTENSION.expression.run text

#-----------------------------------------------------------------------------------------------------------
@correct_formula_ordering = ( formula ) ->
  ### In general, the ordering of components given in a IDL (Ideographic Description Language) formula for
  a given reflects the order in which those components are written, for example:

  * 信:  ⿰亻言
  * 冥:  (⿱冖日六)

  As long as this statement holds, it remains true when components are recursively replaced by their
  respective formulas; for example, the two glyphs given above can also be written:

  ```
  * 信:  ⿰亻言       -> ⿰亻言          ->   ⿰亻(⿱亠二口)
                                       ->  ⿰亻(⿱丶三口)
                                       ->  ⿰亻(⿱亠一𠮛)
  * 冥:  (⿱冖日六)    -> (⿱冖日亠八)
  ```

  Thus, formulas are an important tool to define not only which components are used to form glyphs, but also
  where they are placed inside the glyph.

  However, there are cases where IDL notations fail to reflect correct ordering:

  ```
  * 術:  ⿴行术         (correct order: 彳术亍)
  * 𠚍:  ⿶凵𠂭         (correct order: 𠂭凵)
  * 這:  ⿺辶言         (correct order: 言辶)
  * 建:  ⿺廴聿         (correct order: 聿廴)
  ```

  The last two cases are examples for the most frequent class of mis-ordering, and the only one that is
  currently addressed by `IDLX/correct_formula_ordering`. Here are sample outputs:

  * 這: ( IDLX.correct_formula_ordering '⿺辶言' ) gives '⿺言辶'
  * 建: ( IDLX.correct_formula_ordering '⿺廴聿' ) gives '⿺聿廴'
  ```

  At the time being, formulas that do not contain `辶` and/or `廴` are returned unchanged; this may change
  in the future.

  Note that the resulting formulas are not anymore geometrically correct; this is because appropriate IDL
  operators are lacking for these cases. The corrected formulas can, however, be used to determine the
  correct order of writing when one disregards the operators and keeps only the components. Thus:

  ```
  * 這: 言辶         ->  亠二口辶
                    ->  丶三口辶
                    ->  亠一𠮛辶
  ```
  are all correct descriptions of the character `這`.

  ###
  try
    return formula unless @_naive_formula_matcher.test formula
    return ( LODASH.flatten @_correct_formula_ordering @parse formula ).join ''
  catch error
    warn()
    warn '----------------------------------------------------------------------'
    warn "an error occurred when trying to parse formula #{rpr formula}:"
    warn error[ 'message' ]
    warn '----------------------------------------------------------------------'
    warn()
    throw error

#-----------------------------------------------------------------------------------------------------------
@_correct_formula_ordering = ( elements ) ->
  idx       = -1
  last_idx  = elements.length - 1
  #.........................................................................................................
  loop
    idx      += 1
    element   = elements[ idx ]
    if CND.isa_list element
      @_correct_formula_ordering element
      continue
    if @_naive_formula_matcher.test element
      [ elements[ idx ], elements[ idx + 1 ] ] = [ elements[ idx + 1 ], elements[ idx ] ]
      @_correct_formula_ordering sub_element if CND.isa_list ( sub_element = elements[ idx ] )
      idx += 1
    break if idx >= last_idx
  #.........................................................................................................
  # whisper '©0z1', elements
  # whisper '©0z1', ( LODASH.flatten elements )
  # whisper '©0z1', ( LODASH.flatten elements ).join ''
  # whisper '©0z1', [ '⿺', '⿱', '𦍌', '次', '辶' ].join ''
  # whisper '©0z1', CHR.chrs_from_text [ '⿺', '⿱', '𦍌', '次', '辶' ].join ''
  # whisper '©0z1', '⿺⿱𦍌次辶'
  # whisper '©0z1', '⿺⿱𦍌次'
  # help '©0z1', '⿺⿱𦍌次'
  # console.log 'xxx'
  # process.stdout.write '⿺⿱𦍌次' + '\n'
  return elements

#-----------------------------------------------------------------------------------------------------------
@_naive_formula_matcher = /辶|廴/

#-----------------------------------------------------------------------------------------------------------
@find_all_cjk_chrs = ( text ) ->
  return CND.find_all text, BASE.$[ 'cjk-chr' ]

#-----------------------------------------------------------------------------------------------------------
@find_all_non_operators = ( text ) ->
  return CND.find_all text, BASE.cjkg_chr_matcher





