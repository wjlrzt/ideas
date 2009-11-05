-----------------------------------------------------------------------------
-- Copyright 2009, Open Universiteit Nederland. This file is distributed 
-- under the terms of the GNU General Public License. For more information, 
-- see the file "LICENSE.txt", which is included in the distribution.
-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan.heeren@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-- A prefix encodes a sequence of steps already performed (a so-called trace), 
-- and allows to continue the derivation at that particular point.
--
-----------------------------------------------------------------------------
module Common.Strategy.Prefix 
   ( Prefix, emptyPrefix, makePrefix
   , Step(..), prefixToSteps, prefixTree, stepsToRules, lastStepInPrefix
   ) where

import Common.Apply
import Common.Utils
import Common.Strategy.Abstract
import Common.Strategy.Core
import Common.Transformation
import Common.Derivation
import Common.Strategy.Location

-----------------------------------------------------------
--- Prefixes

-- | Abstract data type for a (labeled) strategy with a prefix (a sequence of 
-- executed rules). A prefix is still "aware" of the labels that appear in the 
-- strategy. A prefix is encoded as a list of integers (and can be reconstructed 
-- from such a list: see @makePrefix@). The list is stored in reversed order.
data Prefix a = P [Step a] (StrategyTree Step a)

instance Show (Prefix a) where
   show (P _ t) = show (reverse (root t))

instance Eq (Prefix a) where
   P _ t1 == P _ t2 = root t1 == root t2

-- | Construct the empty prefix for a labeled strategy
emptyPrefix :: LabeledStrategy a -> Prefix a
emptyPrefix = makePrefix []

-- | Construct a prefix for a given list of integers and a labeled strategy.
makePrefix :: [Int] -> LabeledStrategy a -> Prefix a
makePrefix is ls = rec [] is start
 where
   mkCore = addLocation . toCore . toStrategy
   start  = strategyTree (markLabel forLabel forRule) (mkCore ls)
 
   forLabel (loc, _) = (Begin loc, End loc)
   forRule = Step
 
   rec acc [] t = P acc t
   rec acc (n:ns) t =
      case drop n (branches t) of
         (step, st):_ -> rec (step:acc) ns st
         _            -> P [] start -- invalid prefix: start over

-- | The @Step@ data type can be used to inspect the structure of the strategy
data Step a = Begin StrategyLocation 
            | Step (Rule a) 
            | End StrategyLocation
   deriving (Show, Eq)

instance Apply Step where
   applyAll (Step r)  = applyAll r
   applyAll (Begin _) = return
   applyAll (End _)   = return

instance Apply Prefix where
   applyAll p = results . prefixTree p

-- | Create a derivation tree with a "prefix" as annotation.
prefixTree :: Prefix a -> a -> DerivationTree (Prefix a) a
prefixTree (P xs t) = rec xs t
 where
   rec ps t a = 
      let list = concatMap make (branches t)
          make (step, subTree) = 
             [ (P new subTree, rec new subTree b)
             | b <- applyAll step a
             , let new = step:ps
             ] 
      in addBranches list (singleNode a (endpoint t))
 
-- | Returns the steps that belong to the prefix
prefixToSteps :: Prefix a -> [Step a]
prefixToSteps (P xs _) = reverse xs
 
-- | Retrieves the rules from a list of steps
stepsToRules :: [Step a] -> [Rule a]
stepsToRules steps = [ r | Step r <- steps ]

-- | Returns the last rule of a prefix (if such a rule exists)
lastStepInPrefix :: Prefix a -> Maybe (Step a)
lastStepInPrefix (P xs _) = safeHead xs