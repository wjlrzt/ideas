-----------------------------------------------------------------------------
-- Copyright 2010, Open Universiteit Nederland. This file is distributed 
-- under the terms of the GNU General Public License. For more information, 
-- see the file "LICENSE.txt", which is included in the distribution.
-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan.heeren@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-----------------------------------------------------------------------------
module Documentation.TestsPage (makeTestsPage) where

import Control.Monad
import Common.TestSuite
import Documentation.DefaultPage
import Documentation.SelfCheck
import Service.DomainReasoner
import Text.HTML
import qualified Text.XML as XML

makeTestsPage :: String -> String -> DomainReasoner ()
makeTestsPage docDir testDir = do
   checks <- selfCheck testDir
   result <- liftIO (runTestSuiteResult checks)
   generatePage docDir testsPageFile (testsPage result)

testsPage :: TestSuiteResult -> HTMLBuilder
testsPage result = do 
   h1 "Summary"
   preText (makeSummary result)
   h1 "Tests"
   formatResult [] result

formatResult :: [Int] -> TestSuiteResult -> HTMLBuilder
formatResult loc result = do
   ttText (show result)
   br
   forM_ (topMessages result) $ \m -> 
      (if isError m then bold . colorRed else colorOrange) 
      (ttText (show m) >> br)
   let subs = zip [1::Int ..] (subResults result) 
   forM_ subs $ \(i, (s, a)) -> do
      let newloc = loc ++ [i]
      showHeader newloc s
      formatResult newloc a

showHeader :: [Int] -> String -> HTMLBuilder
showHeader [a]   s = h2 (show a ++ ". " ++ s)
showHeader [a,b] s = h3 (show a ++ "." ++ show b ++ ". " ++ s)
showHeader _     s = para (bold (text s))

colorRed :: HTMLBuilder -> HTMLBuilder
colorRed body = XML.element "font" $ do
   "color" XML..=. "red"
   body
   
colorOrange :: HTMLBuilder -> HTMLBuilder
colorOrange body = XML.element "font" $ do
   "color" XML..=. "#FE9A2E"
   body