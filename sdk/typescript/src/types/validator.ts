// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import {
  array,
  boolean,
  literal,
  number,
  object,
  string,
  union,
  Infer,
  nullable,
  tuple,
  optional,
} from 'superstruct';
import { ObjectId, SuiAddress } from './common';
import { AuthorityName, EpochId } from './transactions';

/* -------------- Types for the SuiSystemState Rust definition -------------- */

export const ValidatorMetaData = object({
  suiAddress: SuiAddress,
  protocolPubkeyBytes: string(),
  networkPubkeyBytes: string(),
  workerPubkeyBytes: string(),
  proofOfPossessionBytes: string(),
  name: string(),
  description: string(),
  imageUrl: string(),
  projectUrl: string(),
  p2pAddress: string(),
  netAddress: string(),
  primaryAddress: string(),
  workerAddress: string(),
  nextEpochProtocolPubkeyBytes: nullable(string()),
  nextEpochProofOfPossession: nullable(string()),
  nextEpochNetworkPubkeyBytes: nullable(string()),
  nextEpochWorkerPubkeyBytes: nullable(string()),
  nextEpochNetAddress: nullable(string()),
  nextEpochP2pAddress: nullable(string()),
  nextEpochPrimaryAddress: nullable(string()),
  nextEpochWorkerAddress: nullable(string()),
});

export type DelegatedStake = Infer<typeof DelegatedStake>;
export type ValidatorMetaData = Infer<typeof ValidatorMetaData>;
export type CommitteeInfo = Infer<typeof CommitteeInfo>;

// Staking

export const Balance = object({
  value: number(),
});

export const DelegationObject = object({
  stakedSuiId: ObjectId,
  delegationRequestEpoch: EpochId,
  principal: number(),
  tokenLock: nullable(EpochId),
  status: union([literal('Active'), literal('Pending')]),
  estimatedReward: optional(number()),
});

export const DelegatedStake = object({
  validatorAddress: SuiAddress,
  stakingPool: ObjectId,
  delegations: array(DelegationObject),
});

export const StakeSubsidyFields = object({
  balance: object({ value: number() }),
  currentEpochAmount: number(),
  epochCounter: number(),
});

export const StakeSubsidy = object({
  type: string(),
  fields: StakeSubsidyFields,
});

export const SuiSupplyFields = object({
  value: number(),
});

export const ContentsFields = object({
  id: string(),
  size: number(),
  head: object({ vec: array() }),
  tail: object({ vec: array() }),
});

export const ContentsFieldsWithdraw = object({
  id: string(),
  size: number(),
});

export const Contents = object({
  type: string(),
  fields: ContentsFields,
});

export const DelegationStakingPoolFields = object({
  exchangeRates: object({
    id: string(),
    size: number(),
  }),
  id: string(),
  pendingDelegation: number(),
  pendingPoolTokenWithdraw: number(),
  pendingTotalSuiWithdraw: number(),
  poolTokenBalance: number(),
  rewardsPool: object({ value: number() }),
  startingEpoch: number(),
  deactivationEpoch: object({ vec: array() }),
  suiBalance: number(),
});

export const DelegationStakingPool = object({
  type: string(),
  fields: DelegationStakingPoolFields,
});

export const CommitteeInfo = object({
  epoch: number(),
  /** Array of (validator public key, stake unit) tuple */
  validators: optional(array(tuple([AuthorityName, number()]))),
});

export const SystemParameters = object({
  minValidatorStake: number(),
  maxValidatorCandidateCount: number(),
  governanceStartEpoch: number(),
  storageGasPrice: optional(number()),
});

export const Validator = object({
  metadata: ValidatorMetaData,
  votingPower: number(),
  gasPrice: number(),
  stakingPool: DelegationStakingPoolFields,
  commissionRate: number(),
  nextEpochStake: number(),
  nextEpochGasPrice: number(),
  nextEpochCommissionRate: number(),
});
export type Validator = Infer<typeof Validator>;

export const ValidatorPair = object({
  from: SuiAddress,
  to: SuiAddress,
});

export const ValidatorSet = object({
  totalStake: number(),
  activeValidators: array(Validator),
  pendingValidators: object({
    contents: object({
      id: string(),
      size: number(),
    }),
  }),
  pendingRemovals: array(number()),
  stakingPoolMappings: object({
    id: string(),
    size: number(),
  }),
  inactivePools: object({
    id: string(),
    size: number(),
  }),
});

export const SuiSystemState = object({
  epoch: number(),
  protocolVersion: number(),
  validators: ValidatorSet,
  storageFund: Balance,
  parameters: SystemParameters,
  referenceGasPrice: number(),
  validatorReportRecords: object({ contents: array() }),
  stakeSubsidy: StakeSubsidyFields,
  safeMode: boolean(),
  epochStartTimestampMs: optional(number()),
});

export type SuiSystemState = Infer<typeof SuiSystemState>;

export const SuiValidatorSummary = object({
  sui_address: SuiAddress,
  protocol_pubkey_bytes: array(number()),
  network_pubkey_bytes: array(number()),
  worker_pubkey_bytes: array(number()),
  proof_of_possession_bytes: array(number()),
  name: string(),
  description: string(),
  image_url: string(),
  project_url: string(),
  p2p_address: array(number()),
  net_address: array(number()),
  primary_address: array(number()),
  worker_address: array(number()),
  next_epoch_protocol_pubkey_bytes: nullable(array(number())),
  next_epoch_proof_of_possession: nullable(array(number())),
  next_epoch_network_pubkey_bytes: nullable(array(number())),
  next_epoch_worker_pubkey_bytes: nullable(array(number())),
  next_epoch_net_address: nullable(array(number())),
  next_epoch_p2p_address: nullable(array(number())),
  next_epoch_primary_address: nullable(array(number())),
  next_epoch_worker_address: nullable(array(number())),
  voting_power: number(),
  gas_price: number(),
  commission_rate: number(),
  next_epoch_stake: number(),
  next_epoch_gas_price: number(),
  next_epoch_commission_rate: number(),
  staking_pool_starting_epoch: number(),
  staking_pool_deactivation_epoch: nullable(number()),
  staking_pool_sui_balance: number(),
  rewards_pool: number(),
  pool_token_balance: number(),
  pending_delegation: number(),
  pending_pool_token_withdraw: number(),
  pending_total_sui_withdraw: number(),
});

export type SuiValidatorSummary = Infer<typeof SuiValidatorSummary>;

export const SuiSystemStateSummary = object({
  epoch: number(),
  protocol_version: number(),
  storage_fund: number(),
  reference_gas_price: number(),
  safe_mode: boolean(),
  epoch_start_timestamp_ms: number(),
  min_validator_stake: number(),
  max_validator_candidate_count: number(),
  governance_start_epoch: number(),
  stake_subsidy_epoch_counter: number(),
  stake_subsidy_balance: number(),
  stake_subsidy_current_epoch_amount: number(),
  total_stake: number(),
  active_validators: array(SuiValidatorSummary),
});

export type SuiSystemStateSummary = Infer<typeof SuiSystemStateSummary>;
