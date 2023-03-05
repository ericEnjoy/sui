// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import type { Validator } from '@mysten/sui.js';

import { roundFloat } from '~/utils/roundFloat';

const APY_DECIMALS = 4;

export function calculateAPY(validator: Validator, epoch: number) {
    const { suiBalance, startingEpoch, poolTokenBalance } =
        validator.stakingPool;

    const num_epochs_participated = +epoch - +startingEpoch;
    const apy =
        Math.pow(
            1 + (+suiBalance - +poolTokenBalance) / +poolTokenBalance,
            365 / num_epochs_participated
        ) - 1;

    //guard against NaN
    const apyReturn = apy ? roundFloat(apy, APY_DECIMALS) : 0;

    // guard against very large numbers (e.g. 1e+100)
    return apyReturn > 100_000 ? 0 : apyReturn;
}
