// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module sui::validator_cap {
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    friend sui::sui_system;
    friend sui::validator;
    friend sui::validator_set;

    #[test_only]
    friend sui::sui_system_tests;
    #[test_only]
    friend sui::rewards_distribution_tests;

    /// The capability object is created when creating a new `Validator` or when the
    /// validator explicitly creates a new capability object for rotation/revocation.
    /// The holder address of this object can perform some validator operations on behalf of
    /// the authorizer validator. Thus, if a validator wants to separate the keys for operation
    /// (such as reference gas price setting or tallying rule reporting) from fund/staking, it
    /// could transfer this capability object to another address.

    /// To facilitate rotating/revocation, `Validator` stores the ID of currently valid
    /// `UnverifiedValidatorOperationCap`. Thus, before converting `UnverifiedValidatorOperationCap`
    /// to `VerifiedValidatorOperationCap`, verification needs to be done to make sure
    /// the cap object is still valid.
    struct UnverifiedValidatorOperationCap has key, store {
        id: UID,
        authorizer_validator_address: address,
    }

    /// Privileged operations require `VerifiedValidatorOperationCap` for permission check.
    /// This is a Hot Potato, only constructed after successful verification,
    /// and deconstructed after use.
    struct VerifiedValidatorOperationCap {
        authorizer_validator_address: address,
    }

    public(friend) fun unverified_operation_cap_address(cap: &UnverifiedValidatorOperationCap): &address {
        &cap.authorizer_validator_address
    }

    public(friend) fun verified_operation_cap_address(cap: &VerifiedValidatorOperationCap): &address {
        &cap.authorizer_validator_address
    }

    /// Should be only called by the friend modules when adding a `Validator`
    /// or rotating an existing validaotr's `operation_cap_id`.
    public(friend) fun new_unverified_validator_operation_cap_and_transfer(
        validator_address: address,
        ctx: &mut TxContext,
    ): ID {
        // TODO: If possible, modify tests to make TxContext's address to match validator_address
        // and assert the equivalence here.
        let operation_cap = UnverifiedValidatorOperationCap {
            id: object::new(ctx),
            authorizer_validator_address: validator_address,
        };
        let operation_cap_id = object::id(&operation_cap);
        transfer::transfer(operation_cap, validator_address);
        operation_cap_id
    }

    /// Convert an `UnverifiedValidatorOperationCap` to VerifiedValidatorOperationCap.
    /// Should only be called by `validator_set` module AFTER verification.
    public(friend) fun new_from_unverified(
        cap: &UnverifiedValidatorOperationCap,
    ): VerifiedValidatorOperationCap {
        VerifiedValidatorOperationCap {
            authorizer_validator_address: cap.authorizer_validator_address
        }
    }

    public(friend) fun deconstruct_verified_cap(
        verified_cap: VerifiedValidatorOperationCap,
    ): address {
        let VerifiedValidatorOperationCap { authorizer_validator_address } = verified_cap;
        authorizer_validator_address
    }
}
