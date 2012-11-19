{-# LANGUAGE TemplateHaskell #-}

{-| Implementation of the opcodes.

-}

{-

Copyright (C) 2009, 2010, 2011, 2012 Google Inc.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301, USA.

-}

module Ganeti.OpCodes
  ( OpCode(..)
  , TagObject(..)
  , tagObjectFrom
  , encodeTagObject
  , decodeTagObject
  , ReplaceDisksMode(..)
  , DiskIndex
  , mkDiskIndex
  , unDiskIndex
  , opID
  , allOpIDs
  ) where

import Text.JSON (readJSON, showJSON, JSON())

import Ganeti.THH

import Ganeti.OpParams

-- | OpCode representation.
--
-- We only implement a subset of Ganeti opcodes: those which are actually used
-- in the htools codebase.
$(genOpCode "OpCode"
  [ ("OpTestDelay",
     [ simpleField "duration"  [t| Double   |]
     , simpleField "on_master" [t| Bool     |]
     , simpleField "on_nodes"  [t| [String] |]
     ])
  , ("OpInstanceReplaceDisks",
     [ pInstanceName
     , pRemoteNode
     , simpleField "mode"  [t| ReplaceDisksMode |]
     , simpleField "disks" [t| [DiskIndex] |]
     , pIallocator
     ])
  , ("OpInstanceFailover",
     [ pInstanceName
     , simpleField "ignore_consistency" [t| Bool   |]
     , pMigrationTargetNode
     ])
  , ("OpInstanceMigrate",
     [ pInstanceName
     , simpleField "live"           [t| Bool   |]
     , simpleField "cleanup"        [t| Bool   |]
     , defaultField [| False |] $ simpleField "allow_failover" [t| Bool |]
     , pMigrationTargetNode
     ])
  , ("OpTagsSet",
     [ pTagsObject
     , pTagsList
     ])
  , ("OpTagsDel",
     [ pTagsObject
     , pTagsList
     ])
  , ("OpClusterPostInit", [])
  , ("OpClusterDestroy", [])
  , ("OpClusterQuery", [])
  , ("OpClusterVerify",
     [ pDebugSimulateErrors
     , pErrorCodes
     , pSkipChecks
     , pIgnoreErrors
     , pVerbose
     , pOptGroupName
     ])
  , ("OpClusterVerifyConfig",
     [ pDebugSimulateErrors
     , pErrorCodes
     , pIgnoreErrors
     , pVerbose
     ])
  , ("OpClusterVerifyGroup",
     [ pGroupName
     , pDebugSimulateErrors
     , pErrorCodes
     , pSkipChecks
     , pIgnoreErrors
     , pVerbose
     ])
  , ("OpClusterVerifyDisks", [])
  , ("OpGroupVerifyDisks",
     [ pGroupName
     ])
  , ("OpClusterRepairDiskSizes",
     [ pInstances
     ])
  , ("OpClusterConfigQuery",
     [ pOutputFields
     ])
  , ("OpClusterRename",
     [ pName
     ])
  , ("OpClusterSetParams",
     [ pHvState
     , pDiskState
     , pVgName
     , pEnabledHypervisors
     , pClusterHvParams
     , pClusterBeParams
     , pOsHvp
     , pOsParams
     , pDiskParams
     , pCandidatePoolSize
     , pUidPool
     , pAddUids
     , pRemoveUids
     , pMaintainNodeHealth
     , pPreallocWipeDisks
     , pNicParams
     , pNdParams
     , pIpolicy
     , pDrbdHelper
     , pDefaultIAllocator
     , pMasterNetdev
     , pReservedLvs
     , pHiddenOs
     , pBlacklistedOs
     , pUseExternalMipScript
     ])
  , ("OpClusterRedistConf", [])
  , ("OpClusterActivateMasterIp", [])
  , ("OpClusterDeactivateMasterIp", [])
  , ("OpQuery",
     [ pQueryWhat
     , pUseLocking
     , pQueryFields
     , pQueryFilter
     ])
  , ("OpQueryFields",
     [ pQueryWhat
     , pQueryFields
     ])
  , ("OpOobCommand",
     [ pNodeNames
     , pOobCommand
     , pOobTimeout
     , pIgnoreStatus
     , pPowerDelay
     ])
  , ("OpNodeRemove", [ pNodeName ])
  , ("OpNodeAdd",
     [ pNodeName
     , pHvState
     , pDiskState
     , pPrimaryIp
     , pSecondaryIp
     , pReadd
     , pNodeGroup
     , pMasterCapable
     , pVmCapable
     , pNdParams
    ])
  , ("OpNodeQuery",
     [ pOutputFields
     , pUseLocking
     , pNames
     ])
  , ("OpNodeQueryvols",
     [ pOutputFields
     , pNodes
     ])
  , ("OpNodeQueryStorage",
     [ pOutputFields
     , pStorageType
     , pNodes
     , pStorageName
     ])
  , ("OpNodeModifyStorage",
     [ pNodeName
     , pStorageType
     , pStorageName
     , pStorageChanges
     ])
  , ("OpRepairNodeStorage",
     [ pNodeName
     , pStorageType
     , pStorageName
     , pIgnoreConsistency
     ])
  , ("OpNodeSetParams",
     [ pNodeName
     , pForce
     , pHvState
     , pDiskState
     , pMasterCandidate
     , pOffline
     , pDrained
     , pAutoPromote
     , pMasterCapable
     , pVmCapable
     , pSecondaryIp
     , pNdParams
     ])
  , ("OpNodePowercycle",
     [ pNodeName
     , pForce
     ])
  , ("OpNodeMigrate",
     [ pNodeName
     , pMigrationMode
     , pMigrationLive
     , pMigrationTargetNode
     , pAllowRuntimeChgs
     , pIgnoreIpolicy
     , pIallocator
     ])
  , ("OpNodeEvacuate",
     [ pEarlyRelease
     , pNodeName
     , pRemoteNode
     , pIallocator
     , pEvacMode
     ])
  ])

-- | Returns the OP_ID for a given opcode value.
$(genOpID ''OpCode "opID")

-- | A list of all defined/supported opcode IDs.
$(genAllOpIDs ''OpCode "allOpIDs")

instance JSON OpCode where
  readJSON = loadOpCode
  showJSON = saveOpCode
