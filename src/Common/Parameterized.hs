{-# LANGUAGE GADTs, TypeOperators #-}
-----------------------------------------------------------------------------
-- Copyright 2011, Open Universiteit Nederland. This file is distributed
-- under the terms of the GNU General Public License. For more information,
-- see the file "LICENSE.txt", which is included in the distribution.
-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan.heeren@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-- Arrow for annotated functions (inputs/outputs) with bindings
--
-----------------------------------------------------------------------------
module Common.Parameterized 
   ( -- * Data type for annotated functions
     (:>->), module Control.Arrow
     -- * Special operations
   , bindValue, replaceValues
   , toFunction, annotatedFunction, annotations
   , -- * Utility functions
     parameter1, parameter2, parameter3
   ) where

import Common.Environment
import Common.Id
import qualified Control.Category as C
import Control.Arrow
import Data.Monoid
import Data.Typeable

--------------------------------------------------------------------
-- * Data type for annotated functions

data a :>-> b where
   Pure :: (a -> b) -> (a :>-> b)
   Comp :: (a :>-> b) -> (b :>-> c) -> (a :>-> c)
   Star :: (a :>-> c) -> (b :>-> d) -> ((a, b) :>-> (c, d))
   App  :: (a :>-> b, a) :>-> b
   Loop :: ((a, c) :>-> (b, c)) -> (a :>-> b)
   Bind :: Typeable a => Ref a -> (a :>-> a)

instance Functor ((:>->) a) where
   fmap = (^<<)

instance C.Category (:>->) where
   id  = arr id
   (.) = flip Comp

instance Arrow (:>->) where
   arr    = Pure
   (***)  = Star
   first  = flip Star C.id
   second = Star C.id

instance ArrowChoice (:>->) where
   left = leftApp

instance ArrowApply (:>->) where
   app = App

instance ArrowLoop (:>->) where
   loop = Loop

--------------------------------------------------------------------
-- * Special operations

bindValue :: (IsId n, Reference a) => n -> (a :>-> a)
bindValue = Bind . makeRef

replaceValues :: Environment -> (a :>-> b) -> (a :>-> b)
replaceValues env = rec
 where
   rec :: (a :>-> b) -> (a :>-> b)
   rec fun = 
      case fun of
         Pure _   -> fun
         Comp f g -> Comp (rec f) (rec g)
         Star f g -> Star (rec f) (rec g) 
         App      -> App
         Loop f   -> Loop (rec f)
         Bind ref -> maybe fun (arr . const) (ref ? env)

toFunction :: (a :>-> b) -> a -> b
toFunction f = fst . annotatedFunction f

annotatedFunction :: (a :>-> b) -> a -> (b, Environment)
annotatedFunction fun a =
   case fun of
      Pure f   -> (f a, mempty)
      Comp f g -> let (b, ef) = annotatedFunction f a
                      (c, eg) = annotatedFunction g b
                  in (c, ef `mappend` eg)
      Star f g -> let (b, ef) = annotatedFunction f (fst a)
                      (c, eg) = annotatedFunction g (snd a)
                  in ((b, c), ef `mappend` eg)
      App      -> uncurry annotatedFunction a
      Loop f   -> let ((b, c), env) = annotatedFunction f (a, c)
                  in (b, env)
      Bind ref -> (a, singleBinding ref a)

annotations :: (a :>-> b) -> [Id]
annotations fun =
   case fun of
      Comp f g -> annotations f ++ annotations g
      Star f g -> annotations f ++ annotations g
      Loop f   -> annotations f
      Bind ref -> [getId ref]
      _        -> []

--------------------------------------------------------------------
-- * Utility functions

parameter1 :: (IsId n1, Reference a) => n1 -> (a -> b) -> (a :>-> b)
parameter1 n1 f = bindValue n1 >>> arr f

parameter2 :: (IsId n1, IsId n2, Reference a, Reference b) 
           => n1 -> n2 -> (a -> b -> c) -> ((a, b) :>-> c)
parameter2 n1 n2 f = bindValue n1 *** bindValue n2 >>> arr (uncurry f)

parameter3 :: (IsId n1, IsId n2, IsId n3, Reference a, Reference b, Reference c)
           => n1 -> n2 -> n3 -> (a -> b -> c -> d) -> ((a, b, c) :>-> d)
parameter3 n1 n2 n3 f = 
   (\(a, b, c) -> (a, (b, c))) ^>> 
   first (fmap (parameter2 n2 n3) (parameter1 n1 f)) >>> App