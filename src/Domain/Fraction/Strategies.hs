-----------------------------------------------------------------------------
-- |
-- Maintainer  :  alex.gerdes@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-- (todo)e
--
-----------------------------------------------------------------------------
module Domain.Fraction.Strategies where

import Prelude hiding (repeat)
import Domain.Fraction.Zipper
import Domain.Fraction.Rules
import Common.Strategy

toSimple :: LabeledStrategy FracInContext
toSimple = label "Simplify expression" $ repeat $
           label "Eliminate zero's" eliminateZeros
       <*> label "Eliminate units"  eliminateUnits
       <*> label "Do calculation"   calculate

eliminateZeros :: Strategy FracInContext
eliminateZeros = repeat $ somewhere $
                 liftFracRule ruleDivZero
             <|> liftFracRule ruleMulZero
             <|> liftFracRule ruleUnitAdd
             <|> liftFracRule ruleSubZero

eliminateUnits :: Strategy FracInContext
eliminateUnits = repeat $ somewhere $ 
                 liftFracRule ruleUnitMul
             <|> liftFracRule ruleDivOne
             <|> liftFracRule ruleDivSame
             <|> liftFracRule ruleMulVar
             <|> liftFracRule ruleSubVar

calculate :: Strategy FracInContext
calculate = somewhere $
            liftFracRule ruleMul
        <|> liftFracRule ruleDiv
        <|> liftFracRule ruleAdd
        <|> liftFracRule ruleSub
        <|> liftFracRule ruleGCD
        <|> liftFracRule ruleDistMul
        <|> liftFracRule ruleCommonDenom <*> liftFracRule ruleAddFrac
        <|> liftFracRule ruleCommonDenom <*> liftFracRule ruleSubFrac
--       <|> calcFrac


{-
calcFrac :: Strategy FracInContext
calcFrac =  liftFracRule ruleCommonDenom 
        <*> (liftFracRule ruleAddFrac <|> liftFracRule ruleSubFrac)
        <*> liftFracRule ruleGCD
-}