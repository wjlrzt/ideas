module Domain.Math.Constrained where

import Control.Monad
import Domain.Math.Classes
import Data.Monoid

-----------------------------------------------------------------------
-- Constrained values

data Constrained c a = C (Prop c) a
   deriving (Show, Eq)

instance Functor (Constrained c) where
   fmap f (C p a) = C p (f a)

instance Monad (Constrained c) where
   return = C mempty
   C p a >>= f = case f a of
                    C q b -> C (p /\ q) b

constrain :: Prop c -> Constrained c ()
constrain p = C p ()

{- infixl 2 #

(#) :: Constrained c a -> Prop c -> Constrained c a
c # p = constrain p >> c -}

-----------------------------------------------------------------------
-- Propositions

data Prop a = T | F | Not (Prop a) | Prop a :/\: Prop a | Prop a :\/: Prop a | Atom a
   deriving (Show, Eq)

instance Functor Prop where
   fmap f = mapProp (Atom . f)

instance Monad Prop where
   return = Atom
   (>>=)  = flip mapProp

instance MonadPlus Prop where
   mzero = mempty
   mplus = mappend

instance Monoid (Prop a) where
   mempty  = T
   mappend = (/\)

joinProp :: Prop (Prop a) -> Prop a
joinProp = mapProp id

mapProp :: (a -> Prop b) -> Prop a -> Prop b
mapProp f = foldProp (T, F, Not, (:/\:), (:\/:), f)

foldProp :: (b, b, b -> b, b -> b -> b, b -> b -> b, a -> b) -> Prop a -> b
foldProp (true, false, not, and, or, atom) = rec
 where
   rec prop =
      case prop of
         T        -> true
         F        -> false
         Not p    -> not (rec p)
         p :/\: q -> rec p `and` rec q
         p :\/: q -> rec p `or`  rec q
         Atom a   -> atom a
  
simplifyProp :: Prop a -> Prop a
simplifyProp = foldProp (T, F, notP, (/\), (\/), Atom)
   
-- smart constructor
(/\) :: Prop a -> Prop a -> Prop a
T /\ p = p
p /\ T = p
F /\ _ = F
_ /\ F = F
p /\ q = p :/\: q

-- smart constructor
(\/) :: Prop a -> Prop a -> Prop a
T \/ _ = T
_ \/ T = T
F \/ p = p
p \/ F = p
p \/ q = p :\/: q

-- smart constructor
notP :: Prop a -> Prop a
notP (Not p)    = p
notP T          = F
notP F          = T
notP (p :/\: q) = notP p \/ notP q
notP (p :\/: q) = notP p /\ notP q
notP p          = Not p

-- simple implementation for now
contradiction :: Prop a -> Bool
contradiction prop = 
   case simplifyProp prop of
      F -> True
      _ -> False


-----------------------------------------------------------------------
-- Elementary constraints (implied by sqrt and /)
 
infix 3 :==:, :<:
 
data Con a = a :==: a   -- equality
           | a :<:  a   -- ordering
           | WF a       -- well-formedness
   deriving (Show, Eq)

instance Functor Con where
   fmap f con =
      case con of
         x :==: y -> f x :==: f y
         x :<:  y -> f x :<:  f y
         WF x     -> WF (f x)

-----------------------------------------------------------------------
-- Numeric instances

instance (Show c, Eq c, Num a) => Num (Constrained c a) where
   (+) = liftM2 (+)
   (*) = liftM2 (*)
   (-) = liftM2 (-)
   negate      = liftM negate
   fromInteger = return . fromInteger
   abs         = liftM abs
   signum      = liftM signum
   
instance (Show c, Eq c, Fractional a) => Fractional (Constrained c a) where
   (/) = liftM2 (/)
   fromRational = return . fromRational
   
instance (Show c, Eq c, Floating a) => Floating (Constrained c a) where
   pi      = return pi
   sqrt    = liftM  sqrt
   (**)    = liftM2 (**)
   logBase = liftM2 logBase
   exp     = liftM  exp
   log     = liftM  log
   sin     = liftM  sin
   tan     = liftM  tan
   cos     = liftM  cos
   asin    = liftM  asin
   atan    = liftM  atan
   acos    = liftM  acos
   sinh    = liftM  sinh
   tanh    = liftM  tanh
   cosh    = liftM  cosh
   asinh   = liftM  asinh
   atanh   = liftM  atanh
   acosh   = liftM  acosh
   
instance (Show c, Eq c, Symbolic a) => Symbolic (Constrained c a) where
   variable   = return . variable
   function s = liftM (function s) . sequence

-----------------------------------------------------------------------
-- Various instances

{- instance Arbitrary a => Arbitrary (Constrained a) where
   arbitrary = liftM toConstrained arbitrary
   coarbitrary (C a x) = coarbitrary a . coarbitrary x

instance Arbitrary (Prop a) 

instance Uniplate (Constrained a) 

instance UniplateConstr (Constrained a) 

instance ShallowEq (Constrained a)

instance Constructor (Constrained a)

instance MetaVar (Constrained a) -}

-----------------------------------------------------------------------
-- Remaining functions

fromConstrained :: Constrained c a -> a
fromConstrained (C _ a) = a

proposition :: Constrained c a -> Prop c
proposition (C a _) = a

infix 3 .==, .<, ./=, .>=

wf :: a -> Prop (Con a)
wf = Atom . WF

(.==), (.<), (./=), (.>=) :: a -> a -> Prop (Con a)
a .== b = return $ a :==: b
a .<  b = return $ a :<:  b
a ./= b = Not $ return $ a :==: b
a .>= b = Not $ return $ a :<: b