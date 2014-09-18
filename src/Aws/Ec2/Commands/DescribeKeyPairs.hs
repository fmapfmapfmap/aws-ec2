{-# LANGUAGE TemplateHaskell
           , MultiParamTypeClasses
           , TypeFamilies
           #-}

module Aws.Ec2.Commands.DescribeKeyPairs where

import Aws.Ec2.TH

data DescribeKeyPairs = DescribeKeyPairs [Text]
                       deriving (Show)

ec2ValueTransactionDef ''DescribeKeyPairs 'DescribeKeyPairs "keySet" "KeyName"
