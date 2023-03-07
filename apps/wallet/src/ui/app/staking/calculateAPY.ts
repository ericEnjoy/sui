// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { type SuiValidatorSummary } from '@mysten/sui.js';

import { roundFloat } from '_helpers';

const APY_DECIMALS = 4;

export function calculateAPY(validators: SuiValidatorSummary, epoch: number) {
    const {
        staking_pool_sui_balance,
        staking_pool_starting_epoch,
        pool_token_balance,
    } = validators;

    const num_epochs_participated = +epoch - +staking_pool_starting_epoch;
    const apy =
        Math.pow(
            1 +
                (+staking_pool_sui_balance - +pool_token_balance) /
                    +pool_token_balance,
            365 / num_epochs_participated
        ) - 1;

    //guard against NaN
    const apyReturn = apy ? roundFloat(apy, APY_DECIMALS) : 0;

    // guard against very large numbers (e.g. 1e+100)
    return apyReturn > 100_000 ? 0 : apyReturn;
}
