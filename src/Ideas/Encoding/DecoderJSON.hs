{-# LANGUAGE GADTs #-}
-----------------------------------------------------------------------------
-- Copyright 2019, Ideas project team. This file is distributed under the
-- terms of the Apache License 2.0. For more information, see the files
-- "LICENSE.txt" and "NOTICE.txt", which are included in the distribution.
-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan.heeren@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-- Services using JSON notation
--
-----------------------------------------------------------------------------

module Ideas.Encoding.DecoderJSON
   ( JSONDecoder, jsonDecoder
   ) where

import Control.Monad.State (mplus, foldM, get, gets, put)
import Data.Char
import Data.Maybe
import Ideas.Common.Library hiding (exerciseId, symbol)
import Ideas.Common.Traversal.Navigator
import Ideas.Encoding.Encoder
import Ideas.Service.State
import Ideas.Service.Types hiding (String)
import Ideas.Text.JSON
import Ideas.Utils.Decoding (symbol)
import qualified Ideas.Service.Types as Tp

type JSONDecoder a t = DecoderX a JSON t

jsonDecoder :: TypedDecoder a JSON
jsonDecoder tp = get >>= \json ->
   case json of
      Array xs -> decodeType tp // xs
      _ -> fail "expecting an array"

decodeType :: Type a t -> DecoderX a [JSON] t
decodeType tp =
   case tp of
      Tag _ t -> decodeType t
      Iso p t -> from p <$> decodeType t
      Pair t1 t2 -> do
         a <- decodeType t1
         b <- decodeType t2
         return (a, b)
      t1 :|: t2 ->
         (Left  <$> decodeType t1) `mplus`
         (Right <$> decodeType t2)
      Unit         -> return ()
      Const QCGen  -> getQCGen
      Const Script -> getScript
      Const t      -> symbol >>= \a -> decodeConst t // a
      _ -> fail $ "No support for argument type: " ++ show tp

decodeConst :: Const a t -> JSONDecoder a t
decodeConst tp =
   case tp of
      State       -> decodeState
      Context     -> decodeContext
      Exercise    -> getExercise
      Environment -> decodeEnvironment
      Location    -> decodeLocation
      Term        -> gets jsonToTerm
      Int         -> get >>= fromJSON
      Tp.String   -> get >>= fromJSON
      Id          -> decodeId
      Rule        -> decodeRule
      _           -> fail $ "No support for argument type: " ++ show tp

decodeRule :: JSONDecoder a (Rule (Context a))
decodeRule = do
   ex <- getExercise
   get >>= \json ->
      case json of
         String s -> getRule ex (newId s)
         _        -> fail "expecting a string for rule"

decodeId :: JSONDecoder a Id
decodeId = get >>= \json ->
   case json of
      String s -> return (newId s)
      _        -> fail "expecting a string for id"

decodeLocation :: JSONDecoder a Location
decodeLocation = get >>= \json ->
   case json of
      String s -> toLocation <$> readM s
      _        -> fail "expecting a string for a location"

decodeState :: JSONDecoder a (State a)
decodeState = do
   ex <- getExercise
   get >>= \json ->
      case json of
         Array [a] -> put a >> decodeState
         Array (String _code : pref : term : jsonContext : rest) -> do
            pts  <- decodePaths       // pref
            a    <- decodeExpression  // term
            env  <- decodeEnvironment // jsonContext
            let loc = envToLoc env
                ctx = navigateTowards loc $ deleteRef locRef $
                         setEnvironment env $ inContext ex a
                prfx = pts (strategy ex) ctx
            case rest of
               [] -> return $ makeState ex prfx ctx
               [Array [String user, String session, String startterm]] ->
                  return (makeState ex prfx ctx)
                     { stateUser      = Just user
                     , stateSession   = Just session
                     , stateStartTerm = Just startterm
                     }
               _  -> fail $ "invalid state" ++ show json
         _ -> fail $ "invalid state" ++ show json

envToLoc :: Environment -> Location
envToLoc env = toLocation $ fromMaybe [] $ locRef ? env >>= readM

locRef :: Ref String
locRef = makeRef "location"

decodePaths :: JSONDecoder a (LabeledStrategy (Context a) -> Context a -> Prefix (Context a))
decodePaths =
   get >>= \json ->
      case json of
         String p
            | p ~= "noprefix" -> return (\_ _ -> noPrefix)
            | otherwise       -> replayPaths <$> readPaths p
         _ -> fail "invalid prefixes"
 where
   x ~= y = filter isAlphaNum (map toLower x) == y

decodeEnvironment :: JSONDecoder a Environment
decodeEnvironment = get >>= \json ->
   case json of
      String "" -> return mempty
      Object xs -> foldM (flip add) mempty xs
      _         -> fail $ "invalid context: " ++ show json
 where
   add (k, String s) = return . insertRef (makeRef k) s
   add (k, Number n) = return . insertRef (makeRef k) (show n)
   add _             = fail "invalid item in context"

decodeContext :: JSONDecoder a (Context a)
decodeContext = do
   ex <- getExercise
   inContext ex <$> decodeExpression

decodeExpression :: JSONDecoder a a
decodeExpression = withJSONTerm $ \b -> getExercise >>= \ex -> get >>= f b ex
 where
   f True ex json =
      case hasJSONView ex of
         Just v  -> matchM v json
         Nothing -> fail "JSON encoding not supported by exercise"
   f False ex json =
      case json of
         String s -> either fail return (parser ex s)
         _ -> fail "Expecting a string when reading a term"