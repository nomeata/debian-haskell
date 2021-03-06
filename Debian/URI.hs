{-# LANGUAGE PackageImports #-}
{-# OPTIONS -fno-warn-orphans #-}
module Debian.URI
    ( module Network.URI
    , URI'
    , toURI'
    , fromURI'
    , readURI'
    , uriToString'
    , fileFromURI
    , fileFromURIStrict
    , dirFromURI
    ) where

import Control.Exception (SomeException, try)
import Data.ByteString.Lazy.UTF8 as L
import qualified Data.ByteString.Lazy.Char8 as L
import Data.Maybe (catMaybes, fromJust)
import Network.URI (URI(..), URIAuth(..), parseURI, uriToString)
import System.Directory (getDirectoryContents)
-- import System.Process.ByteString (readProcessWithExitCode)
import System.Process.ByteString.Lazy (readProcessWithExitCode)
import Text.Regex (mkRegex, matchRegex)

-- | A wrapper around a String containing a known parsable URI.  Not
-- absolutely safe, because you could say read "URI' \"bogus string\""
-- :: URI'.  But enough to save me from myself.
newtype URI' = URI' String deriving (Read, Show, Eq, Ord)

readURI' :: String -> Maybe URI'
readURI' s = maybe Nothing (const (Just (URI' s))) (parseURI s)

fromURI' :: URI' -> URI
fromURI' (URI' s) = fromJust (parseURI s)

-- | Using the bogus Show instance of URI here.  If it ever gets fixed
-- this will stop working.  Worth noting that show will obscure any
-- password info embedded in the URI, so that's nice.
toURI' :: URI -> URI'
toURI' = URI' . show

uriToString' :: URI -> String
uriToString' uri = uriToString id uri ""

fileFromURI :: URI -> IO (Either SomeException L.ByteString)
fileFromURI uri = fileFromURIStrict uri

fileFromURIStrict :: URI -> IO (Either SomeException L.ByteString)
fileFromURIStrict uri = try $
    case (uriScheme uri, uriAuthority uri) of
      ("file:", Nothing) -> L.readFile (uriPath uri)
      -- ("ssh:", Just auth) -> cmdOutputStrict ("ssh " ++ uriUserInfo auth ++ uriRegName auth ++ uriPort auth ++ " cat " ++ show (uriPath uri))
      ("ssh:", Just auth) -> do
          let cmd = "ssh"
              args = [uriUserInfo auth ++ uriRegName auth ++ uriPort auth, "cat", uriPath uri]
          (_code, out, _err) <- readProcessWithExitCode cmd args L.empty
          return out
      _ -> do
          let cmd = "curl"
              args = ["-s", "-g", uriToString' uri]
          (_code, out, _err) <- readProcessWithExitCode cmd args L.empty
          return out

-- | Parse the text returned when a directory is listed by a web
-- server.  This is currently only known to work with Apache.
-- NOTE: there is a second copy of this function in
-- Extra:Extra.Net. Please update both locations if you make changes.
webServerDirectoryContents :: L.ByteString -> [String]
webServerDirectoryContents text =
    catMaybes . map (second . matchRegex re) . Prelude.lines . L.toString $ text
    where
      re = mkRegex "( <A HREF|<a href)=\"([^/][^\"]*)/\""
      second (Just [_, b]) = Just b
      second _ = Nothing


dirFromURI :: URI -> IO (Either SomeException [String])
dirFromURI uri = try $
    case (uriScheme uri, uriAuthority uri) of
      ("file:", Nothing) -> getDirectoryContents (uriPath uri)
      ("ssh:", Just auth) ->
          do let cmd = "ssh"
                 args = [uriUserInfo auth ++ uriRegName auth ++ uriPort auth, "ls", "-1", uriPath uri]
             (_code, out, _err) <- readProcessWithExitCode cmd args L.empty
             return . Prelude.lines . L.toString $ out
      _ ->
          do let cmd = "curl"
                 args = ["-s", "-g", uriToString' uri]
             (_code, out, _err) <- readProcessWithExitCode cmd args L.empty
             return . webServerDirectoryContents $ out
