// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use sui_types::base_types::{AuthorityName, EpochId, ObjectID, SuiAddress};
use sui_types::committee::{Committee, StakeUnit};
use sui_types::sui_system_state::sui_system_state_inner_v1::SuiSystemStateInnerV1;
use sui_types::sui_system_state::SuiSystemState;

#[derive(Debug, Serialize, Deserialize, Clone, Eq, PartialEq, JsonSchema)]
#[serde(untagged, rename = "SuiSystemState")]
pub enum SuiSystemStateRpc {
    V1(SuiSystemStateInnerV1),
}

impl From<SuiSystemState> for SuiSystemStateRpc {
    fn from(state: SuiSystemState) -> Self {
        match state {
            SuiSystemState::V1(state) => Self::V1(state),
        }
    }
}

impl From<SuiSystemStateRpc> for SuiSystemState {
    fn from(state: SuiSystemStateRpc) -> Self {
        match state {
            SuiSystemStateRpc::V1(state) => Self::V1(state),
        }
    }
}

/// RPC representation of the [Committee] type.
#[derive(Debug, Serialize, Deserialize, Clone, JsonSchema)]
#[serde(rename = "CommitteeInfo")]
pub struct SuiCommittee {
    pub epoch: EpochId,
    pub validators: Vec<(AuthorityName, StakeUnit)>,
}

impl From<Committee> for SuiCommittee {
    fn from(committee: Committee) -> Self {
        Self {
            epoch: committee.epoch,
            validators: committee.voting_rights,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub struct DelegatedStake {
    pub validator_address: SuiAddress,
    pub staking_pool: ObjectID,
    pub delegations: Vec<Delegation>,
}

#[derive(Debug, Serialize, Deserialize, Clone, JsonSchema)]
#[serde(tag = "status")]
pub enum DelegationStatus {
    Pending,
    #[serde(rename_all = "camelCase")]
    Active {
        estimated_reward: u64,
    },
}

#[derive(Debug, Serialize, Deserialize, Clone, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub struct Delegation {
    /// ID of the stake receipt object
    pub staked_sui_id: ObjectID,
    pub delegation_request_epoch: EpochId,
    pub principal: u64,
    pub token_lock: Option<EpochId>,
    #[serde(flatten)]
    pub status: DelegationStatus,
}
