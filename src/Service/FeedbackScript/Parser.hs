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
-- Simple parser for feedback scripts
--
-----------------------------------------------------------------------------
module Service.FeedbackScript.Parser (parseScript, Script) where

import Common.Id
import Control.Monad.Error
import Data.Char
import Data.Monoid hiding ((<>))
import Service.FeedbackScript.Syntax
import Text.ParserCombinators.Parsec
import Text.Parsing

-- chases all included script files
parseScript :: Maybe FilePath -> FilePath -> IO Script
parseScript path file = rec [] [file]
 where
   rec _ [] = return mempty
   rec hist (a:as)
      | a `elem` hist = rec hist as
      | otherwise = do
           s1 <- parseOneScriptFile path a
           let new = [ b | Include bs <- scriptDecls s1, b <- bs ]
           s2 <- rec (a:hist) (new++as) -- depth-first
           return (s1 <> s2) -- included parts are inserted at the end

parseOneScriptFile :: Maybe FilePath -> FilePath -> IO Script
parseOneScriptFile path file = do
   result <- parseFromFile script full
   case result of
      Left e   -> print e >> return mempty
      Right xs -> return xs
 where
   full = maybe id (\p a -> p ++ "/" ++ a) path file

script :: Parser Script
script = makeScript <$> complete decls

decls :: Parser [Decl]
decls = many $ do
   pos <- getPosition
   guard (sourceColumn pos == 1)
   decl

decl :: Parser Decl
decl = do
   dt <- declType
   a  <- identifiers
   f  <- simpleDecl <|> guardedDecl
   return (f dt a)
 <|>
   NameSpace <$ lexString "namespace" <*>  identifiers
 <|>
   Supports <$ lexString "supports" <*> identifiers
 <|>
   Include <$ lexString "include" <*> filenames
 <?> "declaration"

simpleDecl, guardedDecl :: Parser (DeclType -> [Id] -> Decl)
simpleDecl  =  (\t dt a -> Simple dt a t)
           <$> text
guardedDecl =  (\xs dt a -> Guarded dt a xs)
           <$> many1 ((,) <$> (lexChar '|' *> condition) <*> text)

declType :: Parser DeclType
declType =  (TextForId  <$ lexString "text")
        <|> (StringDecl <$ lexString "string")
        <|> (Feedback   <$ lexString "feedback")

condition :: Parser Condition
condition = choice
   [ CondRef         <$> lexeme attribute
   , RecognizedIs    <$  lexString "recognize" <*> identifier
   , CondConst True  <$  lexString "true"
   , CondConst False <$  lexString "false"
   , CondNot         <$  lexString "not" <*> condition
   ]

text :: Parser Text
text = lexChar '=' *> (singleLineText <|> multiLineText)

singleLineText :: Parser Text
singleLineText =
   mconcat <$> manyTill textItem (lexeme (skip newline <|> comment))

multiLineText :: Parser Text
multiLineText =
   mconcat <$  char '{'
           <*> manyTill (textItem <|> (mempty <$ newline)) (lexChar '}')

textItem :: Parser Text
textItem = makeText <$> many1 (noneOf "@#{}\n" <|> try escaped)
       <|> TextRef  <$> attribute
 where
   escaped = char '@' *> satisfy (not . isAlphaNum)

identifiers :: Parser [Id]
identifiers = sepBy1 identifier (lexChar ',')

-- Lexical units
identifier :: Parser Id
identifier = lexeme (mconcat . map newId <$> idPart `sepBy1` char '.')
 <?> "identifier"
 where
   idPart   = many1 idLetter
   idLetter = alphaNum <|> oneOf "-_"

attribute :: Parser Id
attribute = newId <$ skip (char '@') <*>  many1 (alphaNum <|> oneOf "-_")
   <?> "attribute"

filenames :: Parser [FilePath]
filenames = sepBy1 filename (lexChar ',')

filename :: Parser FilePath
filename = lexeme $ many1 (alphaNum <|> oneOf "+-_./\\:;|")

lexChar :: Char -> Parser ()
lexChar = skip . lexeme . char

lexString :: String -> Parser ()
lexString s = skip (lexeme (try (string s))) <?> "string " ++ show s

comment :: Parser ()
comment = skip (char '#' <* manyTill (noneOf "\n") (skip newline <|> eof))

-- parse white space and comments afterwards
lexeme :: Parser a -> Parser a
lexeme p = p <* skipMany (skip space <|> comment)