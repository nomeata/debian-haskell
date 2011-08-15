module Debian.Relation.Common where

-- Standard GHC Modules

import Data.List
import Text.ParserCombinators.Parsec
import Data.Function

-- Local Modules

import Debian.Version

-- Datatype for relations

type PkgName = String

type Relations = AndRelation
type AndRelation = [OrRelation]
type OrRelation = [Relation]

data Relation = Rel PkgName (Maybe VersionReq) (Maybe ArchitectureReq)
		deriving Eq


class ParseRelations a where
    -- |'parseRelations' parse a debian relation (i.e. the value of a
    -- Depends field). Return a parsec error or a value of type
    -- 'Relations'
    parseRelations :: a -> Either ParseError Relations


instance Show Relation where
    show (Rel name ver arch) =
        name ++ maybe "" show ver ++ maybe "" show arch

instance Ord Relation where
    compare (Rel pkgName1 mVerReq1 _mArch1) (Rel pkgName2 mVerReq2 _mArch2) =
	case compare pkgName1 pkgName2 of
	     LT -> LT
	     GT -> GT
	     EQ -> compare mVerReq1 mVerReq2

data ArchitectureReq
    = ArchOnly [String]
    | ArchExcept [String]
      deriving Eq

instance Show ArchitectureReq where
    show (ArchOnly arch) = " [" ++ intercalate " " arch ++ "]"
    show (ArchExcept arch) = " [!" ++ intercalate " !" arch ++ "]"

data VersionReq
    = SLT DebianVersion
    | LTE DebianVersion
    | EEQ  DebianVersion
    | GRE  DebianVersion
    | SGR DebianVersion
      deriving Eq

instance Show VersionReq where
    show (SLT v) = " (<< " ++ show v ++ ")"
    show (LTE v) = " (<= " ++ show v ++ ")"
    show (EEQ v) = " (= " ++ show v ++ ")"
    show (GRE v) = " (>= " ++ show v ++ ")"
    show (SGR v) = " (>> " ++ show v ++ ")"

-- |The sort order is based on version number first, then on the kind of
-- relation, sorting in the order <<, <= , ==, >= , >>
instance Ord VersionReq where
    compare = compare `on` extr
      where extr (SLT v) = (v,0)
            extr (LTE v) = (v,1)
            extr (EEQ v) = (v,2)
            extr (GRE v) = (v,3)
            extr (SGR v) = (v,4)

-- |Check if a version number satisfies a version requirement.
checkVersionReq :: Maybe VersionReq -> Maybe DebianVersion -> Bool
checkVersionReq Nothing _ = True
checkVersionReq _ Nothing = False
checkVersionReq (Just (SLT v1)) (Just v2) = v2 < v1
checkVersionReq (Just (LTE v1)) (Just v2) = v2 <= v1
checkVersionReq (Just (EEQ v1)) (Just v2) = v2 == v1
checkVersionReq (Just (GRE v1)) (Just v2) = v2 >= v1
checkVersionReq (Just (SGR v1)) (Just v2) = v2 > v1
