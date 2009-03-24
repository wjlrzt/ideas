module Domain.Math.ExercisesDWO
   ( calculateResults, fillInResult
   , coverUpEquations, linearEquations, higherDegreeEquations 
   ) where

import Prelude hiding ((^))
import Domain.Math.Equation
import Domain.Math.Expr
import Domain.Math.Symbolic

calculateResults :: [[Expr]]
calculateResults = [level1, level2, level3]
 where
   level1 = 
      [ -8*(-3)
      , -3-9
      , 55/(-5)
      , -6*9
      , -11- (-3)
      , 6-(-9)
      , -10+3
      , 6+(-5)
      ]
      
   level2 = 
      [ -3-(6*(-3))
      , -12/3 - 3
      , -4*(2+3)
      , 2-6*6
      , -27/(4-(-5))
      , (-24/(-6)) - 3
      , 8-(-77/(-11))
      , 4/(-4+5)
      ]
      
   level3 = 
      [ 4*(3-(6-2))
      , (-16-9)/5 - 3
      , 4- (4-13)/(-3)
      , (3*(-3))-5-4
      , -55/(3*(-5)+4)
      , -4*(-2+ (-4)+7)
      , -8 - (140/4*5)
      , 13-(2-1) / 3
      ]

fillInResult :: [[Equation Expr]]
fillInResult = [level1, level2, level3]
 where
   level1 = 
      let x = variable "x" in
      [ x-2    :==: 2
      , -4*x   :==: -28
      , -8*x   :==: 72
      , x+4    :==: 09
      , 4+x    :==: 2
      , -10-x  :==: -7
      , x/(-8) :==: -3
      , 11-x   :==: 14
      ]
      
   level2 = 
      let x = variable "x" in
      [ -5-3*x      :==: -23
      , 21/x - 4    :==: 3
      , -3*(x+3)    :==: -27
      , 2-5*x       :==: 47
      , 18/(7-x)    :==: 6
      , -77/x  + 4  :==: -7
      , -7-(x/(-5)) :==: -15
      , -18/(-3+x)  :==: 3
      ]

   level3 = 
      let x = variable "x" in
      [ -5*(5-(3-x))    :==: -20
      , (-20-x)/(-5)-2  :==: 3
      , 4-(x-14)/(-3)   :==: 1
      , 3*x - 3 - 7     :==: 8
      , -42/(-2*x+2)    :==: 7
      , 3*(4+x+2)       :==: 12
      , -6-(-54/(-3*x)) :==: -12
      , 14-(x-3)/4      :==: 3
      ]

coverUpEquations :: [[Equation Expr]]
coverUpEquations = [level1, level2]
 where
   level1 = 
      let x = variable "x" in
      [ 38-7*x       :==: 3
      , sqrt (125/x) :==: 5
      , 4*(12-x) + 7 :==: 35
      , 5*x^2        :==: 80 
      , 5*(5-x)      :==: 35
      , 32/sqrt x    :==: 8
      , (21/x)-8     :==: -1
      , 180/x^2      :==: 5
      , 3*(x-8)^2    :==: 12
      , (8-x)/3 + 7  :==: 9
      ]
   
   level2 = 
      let x = variable "x" in
      [ sqrt (x+9)/2       :==: 3
      , (4*x-18)^2         :==: 4
      , 3*(13-2*x)^2 - 20  :==: 55
      , 5*((x/3) - 8)^2    :==: 20
      , (6/(sqrt (x-7)))^3 :==: 8
      , 8-(15/(sqrt (31-x)))         :==: 5
      , sqrt (4*(x^2-21))            :==: 4
      , 3 + (44/(sqrt (87 + x)))     :==: 7
      , 13-(56 / (21 + (70/(3+x))))  :==: 12
      , 12/(2+(24/(8+(28/(2+9/x))))) :==: 3
      ]  

linearEquations :: [[Equation Expr]]
linearEquations = [level1, level2, level3, level4, level5]
 where
   level1 :: [Equation Expr]
   level1 = 
      let x = variable "x" in
      [ 5*x + 3   :==: 18
      , 11*x - 12 :==: 21
      , 19 - 3*x  :==: -5
      , -12 + 5*x :==: 33
      , 15 - 9*x  :==: 6
      , 4*x + 18  :==: 0
      , 11*x - 12 :==: -34
      , -2*x - 3  :==: -4
      , 6*x - 12  :==: 2
      , -4*x - 13 :==: -11
      ]

   level2 :: [Equation Expr]
   level2 = 
      let x = variable "x" in
      [ 6*x-2    :==: 2*x+14
      , 3+6*x    :==: 3*x+24
      , 5*x+7    :==: 2*x - 10
      , 2*x-8    :==: 18 - x
      , 4*x - 6  :==: 7*x - 14
      , -1 -5*x  :==: 3*x - 20
      , 4*x - 7  :==: -5*x - 24
      , 4*x - 18 :==: 14 + 11*x
      , 17       :==: 4 - 10*x
      , -5*x + 6 :==: 2 - 3*x
      ]

   level3 :: [Equation Expr]
   level3 = 
      let x = variable "x" in
      [ 4*(x-1)          :==: 11*x - 12
      , 4*(x-4)          :==: 5*(2*x+1)
      , 2*(5-3*x)        :==: 6-x
      , 4*x - (x-2)      :==: 12 + 5*(x-1)
      , -3*(x-2)         :==: 3*(x+4) - 7
      , 3*(4*x-1) + 3    :==: 7*x - 14
      , 4*(4*x - 1) - 2  :==: -3*x + 3*(2*x -5)
      , 2*x - (3*x + 5)  :==: 10 + 5*(x-1)
      , -5*(x+1)         :==: 9*(x+4)-5
      , 18 - 2*(4*x + 2) :==: 7*x - 4*(4*x -2)
      ]

   level4 :: [Equation Expr]
   level4 = 
      let x = variable "x" in
      [ (1/2)*x - 4            :==: 2*x + 2+(1/2)
      , (1/4)*x + (1/2)        :==: (5/2)*x + 2
      , (1/4)*x - (3/4)        :==: 2*x + (1/2)
      , -(1/2)*x + (3/4)       :==: (5/2)*x + 3
      , -(1/2)*x + 1+(1/2)     :==: 2*x - 5
      , -(1/3)*x + (3/4)       :==: (1/4)*x + (1/6)
      , (3/4)*x - (1/3)        :==: (2/3)*x - (3/4)
      , (2/5)*x - (1/4)        :==: (1/2)*x + (3/4)
      , (2/3)*x - 2            :==: (1/5)*x - (3/5)
      , (-1+(2/5))*x + 3+(1/2) :==: (3/5)*x + (9/10)
      ]

   level5 :: [Equation Expr]
   level5 = 
      let x = variable "x" in
      [ (1/4)*(x-3)         :==: (1/2)*x - 4
      , (x+3)/2             :==: 5*((1/2)*x + 1 + (1/2))
      , (1/2)*(7-(2/3)*x)   :==: 2 + (1/9)*x
      , (3/4)*x - (x-1)     :==: 3 + (2+(1/2))*(x-1)
      , -(5/4)*(x-7)        :==: (3/4)*(x+2) - (4+(1/2))
      , 3*((1/5)*x - 1) + 5 :==: 7*x - 14
      , ((5*x - 1) / 6) - 2 :==: -4*x + (3*x - 6)/2
      , 2*x - ((2*x+2)/5)   :==: 12 + (x-1)/6
      , (-3*(x+2))/6        :==: 9*((2/3)*x + (1/3)) - (5/3)
      , 1 - ((4*x + 2)/3)   :==: 3*x - ((5*x - 1) / 4)
      ]

higherDegreeEquations :: [Equation Expr]
higherDegreeEquations = 
   let x = variable "x" in
   [ x^3 + x^2 :==: 0
   , x^3 - 5*x :==: 0
   , x^3 - 11*x^2 + 18*x :==: 0
   , x^3 + 36*x :==: 13*x^2
   , x^3 + 2*x^2 :==: 24*x
   , 7*x^3 :==: 8*x^2
   , x^4 :==: 9*x^2
   , 64*x^7 :==: x^5
   , x^3 - 4*x^2 - 9*x :==: 0
   , (x-1)*(x^3 - 6*x) :==: 3*x^3 - 3*x^2
   ]