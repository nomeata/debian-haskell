{-# LANGUAGE OverloadedStrings #-}
module SourcesList where

import Data.Text (Text)
import Data.Monoid (mconcat, (<>))
import Debian.Pretty (PP(PP))
import Debian.Sources
import Test.HUnit
import Text.PrettyPrint (render)
import Text.PrettyPrint.HughesPJClass (pPrint)

-- * Unit Tests

-- TODO: add test cases that test for unterminated double-quote or bracket
testQuoteWords :: Test
testQuoteWords =
    test [ assertEqual "Space seperate words, no quoting" ["hello", "world","!"] (quoteWords "  hello    world !  ")
         , assertEqual "Space seperate words, double quotes" ["hello  world","!"] (quoteWords "  hel\"lo  world\" !  ")
         , assertEqual "Space seperate words, square brackets" ["hel[lo  worl]d","!"] (quoteWords "  hel[lo  worl]d ! ")
         , assertEqual "Space seperate words, square-bracket at end" ["hel[lo world]"] (quoteWords " hel[lo world]")
         , assertEqual "Space seperate words, double quote at end" ["hello world"] (quoteWords " hel\"lo world\"")
         , assertEqual "Space seperate words, square-bracket at beginning" ["[hello wo]rld","!"] (quoteWords "[hello wo]rld !")
         , assertEqual "Space seperate words, double quote at beginning" ["hello world","!"] (quoteWords "\"hello wor\"ld !")
         ]

testSourcesList :: Test
testSourcesList =
    test [ assertEqual "valid sources.list" validSourcesListExpected (render . pPrint . PP . parseSourcesList $ validSourcesListStr) ]
    where
      validSourcesListStr =
          unlines $ [ " # A comment only line "
                    , " deb ftp://ftp.debian.org/debian unstable main contrib non-free # typical deb line"
                    , " deb-src ftp://ftp.debian.org/debian unstable main contrib non-free # typical deb-src line"
                    , ""
                    , "# comment line"
                    , "deb http://pkg-kde.alioth.debian.org/kde-3.5.0/ ./ # exact path"
                    , "deb http://ftp.debian.org/whee \"space dist\" main"
                    , "deb http://ftp.debian.org/whee dist space%20section"
                    ]
      validSourcesListExpected =
          unlines $ [ "deb ftp://ftp.debian.org/debian unstable main contrib non-free"
                    , "deb-src ftp://ftp.debian.org/debian unstable main contrib non-free"
                    , "deb http://pkg-kde.alioth.debian.org/kde-3.5.0/ ./"
                    , "deb http://ftp.debian.org/whee space%20dist main"
                    , "deb http://ftp.debian.org/whee dist space%20section"
                    ]
      _invalidSourcesListStr1 = "deb http://pkg-kde.alioth.debian.org/kde-3.5.0/ ./ main contrib non-free # exact path with sections" :: Text

testSourcesListParse :: Test
testSourcesListParse =
    test [ assertEqual "" gutsy (mconcat . map (<> "\n") . map (render . pPrint) . parseSourcesList $ gutsy) ]
    where
      gutsy = concat ["deb http://us.archive.ubuntu.com/ubuntu/ gutsy main restricted universe multiverse\n",
	              "deb-src http://us.archive.ubuntu.com/ubuntu/ gutsy main restricted universe multiverse\n",
                      "deb http://us.archive.ubuntu.com/ubuntu/ gutsy-updates main restricted universe multiverse\n",
                      "deb-src http://us.archive.ubuntu.com/ubuntu/ gutsy-updates main restricted universe multiverse\n",
                      "deb http://us.archive.ubuntu.com/ubuntu/ gutsy-backports main restricted universe multiverse\n",
                      "deb-src http://us.archive.ubuntu.com/ubuntu/ gutsy-backports main restricted universe multiverse\n",
                      "deb http://security.ubuntu.com/ubuntu/ gutsy-security main restricted universe multiverse\n",
                      "deb-src http://security.ubuntu.com/ubuntu/ gutsy-security main restricted universe multiverse\n"]

sourcesListTests :: [Test]
sourcesListTests =
    [ testQuoteWords, testSourcesList, testSourcesListParse ]
