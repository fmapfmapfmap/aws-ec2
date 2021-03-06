{-# LANGUAGE TemplateHaskell
           , MultiParamTypeClasses
           , TypeFamilies
           #-}

module Aws.Ec2.Commands.DescribeSubnets where

import Aws.Ec2.TH

data DescribeSubnets = DescribeSubnets [Text]
                       deriving (Show)

EC2VALUETRANSACTIONDEF(DescribeSubnets,"DescribeSubnets","subnetSet","SubnetId")
