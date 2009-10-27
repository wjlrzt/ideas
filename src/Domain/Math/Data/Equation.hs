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
-- Mathematical equations
--
-----------------------------------------------------------------------------
module Domain.Math.Data.Equation 
   ( module Domain.Math.Data.Equation
   , module Domain.Math.Data.Relation
   ) where

import Common.Uniplate
import Common.Rewriting
import Domain.Math.Data.Relation
import Control.Monad
{-
infix 1 :==:

type Equations a = [Equation a]

data Equation  a = a :==: a
   deriving (Eq, Ord)
  
instance Functor Equation where
   fmap f (x :==: y) = f x :==: f y
   
instance Once Equation where 
   onceM f (lhs :==: rhs) = 
      liftM (:==: rhs) (f lhs) `mplus` liftM (lhs :==:) (f rhs)

instance Switch Equation where 
   switch (ma :==: mb) = liftM2 (:==:) ma mb
   
instance Crush Equation where
   crush (a :==: b) = [a, b]
   
instance Show a => Show (Equation a) where
   show (x :==: y) = show x ++ " == " ++ show y
-} 
 
getLHS, getRHS :: Equation a -> a
getLHS (x :==: _) = x
getRHS (_ :==: y) = y

evalEquation :: Eq a => Equation a -> Bool
evalEquation (x :==: y) = x == y

substEquation :: (Uniplate a, MetaVar a) => Substitution a -> Equation a -> Equation a
substEquation sub = fmap (sub |->)

substEquations :: (Uniplate a, MetaVar a) => Substitution a -> Equations a -> Equations a
substEquations = map . substEquation

combineWith :: (a -> a -> a) -> Equation a -> Equation a -> Equation a
combineWith f (x1 :==: x2) (y1 :==: y2) = f x1 y1 :==: f x2 y2