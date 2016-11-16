{-# LANGUAGE OverloadedStrings #-}
module Main (
  main
) where

import           Data.Text (Text)
import qualified Data.Text as T

import           Control.Monad ( join )
import           Control.Exception

import           System.Exit

import           Text.Show.Pretty ( ppShow )

import           Test.Tasty
import           Test.Tasty.HUnit

import           Network.Mattermost
import           Network.Mattermost.Logging
import           Network.Mattermost.Util

data Config
  = Config
  { configUsername :: Text
  , configHostname :: Text
  , configTeam     :: Text
  , configPort     :: Int
  , configPassword :: Text
  , configEmail    :: Text
  }

testConfig :: Config
testConfig = Config
  { configUsername = "test"
  , configEmail    = "test@example.com"
  , configHostname = "localhost"
  , configTeam     = "testteam"
  , configPort     = 8065
  , configPassword = "password"
  }

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testCaseSteps "MM Tests" $ \prnt -> do
  prnt "Creating Admin account"
  createAdminAccount prnt
  prnt "Logging into Admin account"
  _token <- loginAdminAccount prnt
  return ()

createAdminAccount :: (String -> IO ()) -> IO ()
createAdminAccount prnt = do
  cd <- initConnectionDataInsecure (T.unpack (configHostname testConfig))
                                   (fromIntegral (configPort testConfig))
  let newAccount = UsersCreate { usersCreateEmail          = configEmail    testConfig
                               , usersCreatePassword       = configPassword testConfig
                               , usersCreateUsername       = configUsername testConfig
                               , usersCreateAllowMarketing = True
                               }
      -- XXX: Use something like this if you want logging (useful when debugging)
      -- cd = cd `withLogger` mmLoggerDebugErr

  newUser <- mmUsersCreate cd newAccount
  let login = Login { username = configUsername testConfig
                    , password = configPassword testConfig
                    }
  prnt "Admin user created"

loginAdminAccount :: (String -> IO ()) -> IO Token
loginAdminAccount prnt = do
  let login = Login { username = configUsername testConfig
                    , password = configPassword testConfig
                    }
  cd <- initConnectionDataInsecure (T.unpack (configHostname testConfig))
                                   (fromIntegral (configPort testConfig))
  (token, mmUser) <- join (hoistE <$> mmLogin cd login)
  prnt "Authenticated as admin user"
  return token
