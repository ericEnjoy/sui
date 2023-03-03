// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// This file contains tests testing functionalities in `sui_system` that are not
// already tested by the other more themed tests such as `delegation_tests` or
// `rewards_distribution_tests`.

#[test_only]
module sui::sui_system_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::sui::SUI;
    use sui::governance_test_utils::{add_validator, advance_epoch, remove_validator, set_up_sui_system_state, create_sui_system_state_for_testing};
    use sui::sui_system::{Self, SuiSystemState};
    use sui::validator::Self;
    use sui::vec_set;
    use sui::table;
    use std::vector;
    use sui::coin;
    use sui::balance;
    use sui::validator::Validator;
    use sui::test_utils::assert_eq;
    use std::option::Self;
    use sui::url;
    use std::string;
    use std::ascii;

    #[test]
    fun test_report_validator() {
        let scenario_val = test_scenario::begin(@0x0);
        let scenario = &mut scenario_val;

        set_up_sui_system_state(vector[@0x1, @0x2, @0x3], scenario);

        report_helper(@0x1, @0x2, false, scenario);
        assert!(get_reporters_of(@0x2, scenario) == vector[@0x1], 0);
        report_helper(@0x3, @0x2, false, scenario);
        assert!(get_reporters_of(@0x2, scenario) == vector[@0x1, @0x3], 0);

        // Report again and result should stay the same.
        report_helper(@0x1, @0x2, false, scenario);
        assert!(get_reporters_of(@0x2, scenario) == vector[@0x1, @0x3], 0);

        // Undo the report.
        report_helper(@0x3, @0x2, true, scenario);
        assert!(get_reporters_of(@0x2, scenario) == vector[@0x1], 0);

        advance_epoch(scenario);

        // After an epoch ends, report records are reset.
        assert!(get_reporters_of(@0x2, scenario) == vector[], 0);

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = sui_system::ENotValidator)]
    fun test_report_non_validator_failure() {
        let scenario_val = test_scenario::begin(@0x0);
        let scenario = &mut scenario_val;

        set_up_sui_system_state(vector[@0x1, @0x2, @0x3], scenario);
        report_helper(@0x1, @0x42, false, scenario);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = sui_system::ECannotReportOneself)]
    fun test_report_self_failure() {
        let scenario_val = test_scenario::begin(@0x0);
        let scenario = &mut scenario_val;

        set_up_sui_system_state(vector[@0x1, @0x2, @0x3], scenario);
        report_helper(@0x1, @0x1, false, scenario);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = sui_system::EReportRecordNotFound)]
    fun test_undo_report_failure() {
        let scenario_val = test_scenario::begin(@0x0);
        let scenario = &mut scenario_val;

        set_up_sui_system_state(vector[@0x1, @0x2, @0x3], scenario);
        report_helper(@0x2, @0x1, true, scenario);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_staking_pool_mappings() {
        let scenario_val = test_scenario::begin(@0x0);
        let scenario = &mut scenario_val;

        set_up_sui_system_state(vector[@0x1, @0x2, @0x3], scenario);
        test_scenario::next_tx(scenario, @0x1);
        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        let pool_id_1 = sui_system::validator_staking_pool_id(&system_state, @0x1);
        let pool_id_2 = sui_system::validator_staking_pool_id(&system_state, @0x2);
        let pool_id_3 = sui_system::validator_staking_pool_id(&system_state, @0x3);
        let pool_mappings = sui_system::validator_staking_pool_mappings(&system_state);
        assert_eq(table::length(pool_mappings), 3);
        assert_eq(*table::borrow(pool_mappings, pool_id_1), @0x1);
        assert_eq(*table::borrow(pool_mappings, pool_id_2), @0x2);
        assert_eq(*table::borrow(pool_mappings, pool_id_3), @0x3);
        test_scenario::return_shared(system_state);

        let new_validator_addr = @0x1a4623343cd42be47d67314fce0ad042f3c82685544bc91d8c11d24e74ba7357;
        test_scenario::next_tx(scenario, new_validator_addr);
        // This is generated using https://github.com/MystenLabs/sui/blob/375dfb8c56bb422aca8f1592da09a246999bdf4c/crates/sui-types/src/unit_tests/crypto_tests.rs#L38
        let pop = x"aaac77de3581d3d3df0965175435e00e3ade225333e83806aa66f9c6ccffc00a95b4698b02114013aa4552565cdcef25";
        
        // Add a validator
        add_validator(new_validator_addr, 100, pop, scenario);
        advance_epoch(scenario);

        test_scenario::next_tx(scenario, @0x1);
        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        let pool_id_4 = sui_system::validator_staking_pool_id(&system_state, new_validator_addr);
        pool_mappings = sui_system::validator_staking_pool_mappings(&system_state);
        // Check that the previous mappings didn't change as well.
        assert_eq(table::length(pool_mappings), 4);
        assert_eq(*table::borrow(pool_mappings, pool_id_1), @0x1);
        assert_eq(*table::borrow(pool_mappings, pool_id_2), @0x2);
        assert_eq(*table::borrow(pool_mappings, pool_id_3), @0x3);
        assert_eq(*table::borrow(pool_mappings, pool_id_4), new_validator_addr);
        test_scenario::return_shared(system_state);

        // Remove one of the original validators.
        remove_validator(@0x1, scenario);
        advance_epoch(scenario);

        test_scenario::next_tx(scenario, @0x1);
        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        pool_mappings = sui_system::validator_staking_pool_mappings(&system_state);
        // Check that the previous mappings didn't change as well.
        assert_eq(table::length(pool_mappings), 3);
        assert_eq(table::contains(pool_mappings, pool_id_1), false);
        assert_eq(*table::borrow(pool_mappings, pool_id_2), @0x2);
        assert_eq(*table::borrow(pool_mappings, pool_id_3), @0x3);
        assert_eq(*table::borrow(pool_mappings, pool_id_4), new_validator_addr);
        test_scenario::return_shared(system_state);

        test_scenario::end(scenario_val);
    }

    fun report_helper(reporter: address, reported: address, is_undo: bool, scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, reporter);

        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        let ctx = test_scenario::ctx(scenario);
        if (is_undo) {
            sui_system::undo_report_validator(&mut system_state, reported, ctx);
        } else {
            sui_system::report_validator(&mut system_state, reported, ctx);
        };
        test_scenario::return_shared(system_state);
    }

    fun get_reporters_of(addr: address, scenario: &mut Scenario): vector<address> {
        test_scenario::next_tx(scenario, addr);
        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        let res = vec_set::into_keys(sui_system::get_reporters_of(&system_state, addr));
        test_scenario::return_shared(system_state);
        res
    }

    // pop MUST a valid signature using sui_address and protocol_pubkey_bytes. 
    // To produce a valid proof of possession, run [fn test_proof_of_possession]. 
    fun update_metadata(
        scenario: &mut Scenario,
        system_state: &mut SuiSystemState,
        name: vector<u8>,
        protocol_pub_key: vector<u8>,
        pop: vector<u8>,
        network_address: vector<u8>,
        p2p_address: vector<u8>
    ) {
        let ctx = test_scenario::ctx(scenario);
        sui_system::update_validator_name(system_state, name, ctx);
        sui_system::update_validator_description(system_state, b"new_desc", ctx);
        sui_system::update_validator_image_url(system_state, b"new_image_url", ctx);
        sui_system::update_validator_project_url(system_state, b"new_project_url", ctx);
        sui_system::update_validator_next_epoch_network_address(system_state, network_address, ctx);
        sui_system::update_validator_next_epoch_p2p_address(system_state, p2p_address, ctx);
        sui_system::update_validator_next_epoch_primary_address(system_state, vector[4, 168, 168, 168, 168], ctx);
        sui_system::update_validator_next_epoch_worker_address(system_state, vector[4, 168, 168, 168, 168], ctx);
        sui_system::update_validator_next_epoch_protocol_pubkey(
            system_state,
            protocol_pub_key,
            pop,
            ctx
        );
        sui_system::update_validator_next_epoch_worker_pubkey(system_state, vector[215, 64, 85, 185, 231, 116, 69, 151, 97, 79, 4, 183, 20, 70, 84, 51, 211, 162, 115, 221, 73, 241, 240, 171, 192, 25, 232, 106, 175, 162, 176, 43], ctx);
        sui_system::update_validator_next_epoch_network_pubkey(system_state, vector[148, 117, 212, 171, 44, 104, 167, 11, 177, 100, 4, 55, 17, 235, 117, 45, 117, 84, 159, 49, 14, 159, 239, 246, 237, 21, 83, 166, 112, 53, 62, 199], ctx);
    }

    fun verify_metadata(
        validator: &Validator,
        name: vector<u8>,
        protocol_pub_key: vector<u8>,
        pop: vector<u8>,
        network_address: vector<u8>,
        p2p_address: vector<u8>,
        new_protocol_pub_key: vector<u8>,
        new_pop: vector<u8>,
        new_network_address: vector<u8>,
        new_p2p_address: vector<u8>,
    ) {
        // Current epoch
        assert!(validator::name(validator) == &string::from_ascii(ascii::string(name)), 0);
        assert!(validator::description(validator) == &string::from_ascii(ascii::string(b"new_desc")), 0);
        assert!(validator::image_url(validator) == &url::new_unsafe_from_bytes(b"new_image_url"), 0);
        assert!(validator::project_url(validator) == &url::new_unsafe_from_bytes(b"new_project_url"), 0);
        assert!(validator::network_address(validator) == &network_address, 0);
        assert!(validator::p2p_address(validator) == &p2p_address, 0);
        assert!(validator::primary_address(validator) == &vector[4, 127, 0, 0, 1], 0);
        assert!(validator::worker_address(validator) == &vector[4, 127, 0, 0, 1], 0);
        assert!(validator::protocol_pubkey_bytes(validator) == &protocol_pub_key, 0);
        assert!(validator::proof_of_possession(validator) == &pop, 0);
        assert!(validator::network_pubkey_bytes(validator) == &vector[32, 219, 38, 23, 242, 109, 116, 235, 225, 192, 219, 45, 40, 124, 162, 25, 33, 68, 52, 41, 123, 9, 98, 11, 184, 150, 214, 62, 60, 210, 121, 62], 0);
        assert!(validator::worker_pubkey_bytes(validator) == &vector[68, 55, 206, 25, 199, 14, 169, 53, 68, 92, 142, 136, 174, 149, 54, 215, 101, 63, 249, 206, 197, 98, 233, 80, 60, 12, 183, 32, 216, 88, 103, 25], 0);

        // Next epoch
        assert!(validator::next_epoch_network_address(validator) == &option::some(new_network_address), 0);
        assert!(validator::next_epoch_p2p_address(validator) == &option::some(new_p2p_address), 0);
        assert!(validator::next_epoch_primary_address(validator) == &option::some(vector[4, 168, 168, 168, 168]), 0);
        assert!(validator::next_epoch_worker_address(validator) == &option::some(vector[4, 168, 168, 168, 168]), 0);
        assert!(
            validator::next_epoch_protocol_pubkey_bytes(validator) == &option::some(new_protocol_pub_key),
            0
        );
        assert!(
            validator::next_epoch_proof_of_possession(validator) == &option::some(new_pop),
            0
        );
        assert!(
            validator::next_epoch_worker_pubkey_bytes(validator) == &option::some(vector[215, 64, 85, 185, 231, 116, 69, 151, 97, 79, 4, 183, 20, 70, 84, 51, 211, 162, 115, 221, 73, 241, 240, 171, 192, 25, 232, 106, 175, 162, 176, 43]),
            0
        );
        assert!(
            validator::next_epoch_network_pubkey_bytes(validator) == &option::some(vector[148, 117, 212, 171, 44, 104, 167, 11, 177, 100, 4, 55, 17, 235, 117, 45, 117, 84, 159, 49, 14, 159, 239, 246, 237, 21, 83, 166, 112, 53, 62, 199]),
            0
        );
    }

    fun verify_metadata_after_advancing_epoch(
        validator: &Validator,
        name: vector<u8>,
        protocol_pub_key: vector<u8>,
        pop: vector<u8>,
        network_address: vector<u8>,
        p2p_address: vector<u8>,
    ) {
        // Current epoch
        assert!(validator::name(validator) == &string::from_ascii(ascii::string(name)), 0);
        assert!(validator::description(validator) == &string::from_ascii(ascii::string(b"new_desc")), 0);
        assert!(validator::image_url(validator) == &url::new_unsafe_from_bytes(b"new_image_url"), 0);
        assert!(validator::project_url(validator) == &url::new_unsafe_from_bytes(b"new_project_url"), 0);
        assert!(validator::network_address(validator) == &network_address, 0);
        assert!(validator::p2p_address(validator) == &p2p_address, 0);
        assert!(validator::primary_address(validator) == &vector[4, 168, 168, 168, 168], 0);
        assert!(validator::worker_address(validator) == &vector[4, 168, 168, 168, 168], 0);
        assert!(validator::protocol_pubkey_bytes(validator) == &protocol_pub_key, 0);
        assert!(validator::proof_of_possession(validator) == &pop, 0);
        assert!(validator::worker_pubkey_bytes(validator) == &vector[215, 64, 85, 185, 231, 116, 69, 151, 97, 79, 4, 183, 20, 70, 84, 51, 211, 162, 115, 221, 73, 241, 240, 171, 192, 25, 232, 106, 175, 162, 176, 43], 0);
        assert!(validator::network_pubkey_bytes(validator) == &vector[148, 117, 212, 171, 44, 104, 167, 11, 177, 100, 4, 55, 17, 235, 117, 45, 117, 84, 159, 49, 14, 159, 239, 246, 237, 21, 83, 166, 112, 53, 62, 199], 0);

        // Next epoch
        assert!(option::is_none(validator::next_epoch_network_address(validator)), 0);
        assert!(option::is_none(validator::next_epoch_p2p_address(validator)), 0);
        assert!(option::is_none(validator::next_epoch_primary_address(validator)), 0);
        assert!(option::is_none(validator::next_epoch_worker_address(validator)), 0);
        assert!(option::is_none(validator::next_epoch_protocol_pubkey_bytes(validator)), 0);
        assert!(option::is_none(validator::next_epoch_proof_of_possession(validator)), 0);
        assert!(option::is_none(validator::next_epoch_worker_pubkey_bytes(validator)), 0);
        assert!(option::is_none(validator::next_epoch_network_pubkey_bytes(validator)), 0);
    }

    #[test]
    fun test_active_validator_update_metadata() {
        let validator_addr = @0xaf76afe6f866d8426d2be85d6ef0b11f871a251d043b2f11e15563bf418f5a5a;
        let scenario_val = test_scenario::begin(validator_addr);
        let scenario = &mut scenario_val;

        // Set up SuiSystemState with an active validator
        let validators = vector::empty();
        let ctx = test_scenario::ctx(scenario);
        let validator = validator::new_for_testing(
            validator_addr,
            x"99f25ef61f8032b914636460982c5cc6f134ef1ddae76657f2cbfec1ebfc8d097374080df6fcf0dcb8bc4b0d8e0af5d80ebbff2b4c599f54f42d6312dfc314276078c1cc347ebbbec5198be258513f386b930d02c2749a803e2330955ebd1a10",
            vector[32, 219, 38, 23, 242, 109, 116, 235, 225, 192, 219, 45, 40, 124, 162, 25, 33, 68, 52, 41, 123, 9, 98, 11, 184, 150, 214, 62, 60, 210, 121, 62],
            vector[68, 55, 206, 25, 199, 14, 169, 53, 68, 92, 142, 136, 174, 149, 54, 215, 101, 63, 249, 206, 197, 98, 233, 80, 60, 12, 183, 32, 216, 88, 103, 25],
            x"b0695ec40ca7c424173ade60def554f5d8e71c113f2fc6333c0cbf8a3622b89b8b89c49bf325c1a25ce7052eb2605257",
            b"ValidatorName",
            b"description",
            b"image_url",
            b"project_url",
            vector[4, 127, 0, 0, 1],
            vector[4, 127, 0, 0, 1],
            vector[4, 127, 0, 0, 1],
            vector[4, 127, 0, 0, 1],
            balance::create_for_testing<SUI>(100),
            option::none(),
            1,
            0,
            0,
            ctx
        );
        vector::push_back(&mut validators, validator);
        create_sui_system_state_for_testing(validators, 1000, 0, ctx);

        test_scenario::next_tx(scenario, validator_addr);

        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);

        // Test active validator metadata changes
        test_scenario::next_tx(scenario, validator_addr); 
        {
            update_metadata(
                scenario,
                &mut system_state,
                b"validator_new_name",
                x"96d19c53f1bee2158c3fcfb5bb2f06d3a8237667529d2d8f0fbb22fe5c3b3e64748420b4103674490476d98530d063271222d2a59b0f7932909cc455a30f00c69380e6885375e94243f7468e9563aad29330aca7ab431927540e9508888f0e1c",
                x"8b9794dfd11b88e16ba8f6a4a2c1e7580738dce2d6910ee594bebd88297b22ae8c34d1ee3f5a081159d68e076ef5d30b",
                vector[4, 42, 42, 42, 42],
                vector[4, 43, 43, 43, 43],
            );
        };

        test_scenario::next_tx(scenario, validator_addr);
        let validator = sui_system::active_validator_by_address(&system_state, validator_addr);
        verify_metadata(
            validator,
            b"validator_new_name",
            x"99f25ef61f8032b914636460982c5cc6f134ef1ddae76657f2cbfec1ebfc8d097374080df6fcf0dcb8bc4b0d8e0af5d80ebbff2b4c599f54f42d6312dfc314276078c1cc347ebbbec5198be258513f386b930d02c2749a803e2330955ebd1a10",
            x"b0695ec40ca7c424173ade60def554f5d8e71c113f2fc6333c0cbf8a3622b89b8b89c49bf325c1a25ce7052eb2605257",
            vector[4, 127, 0, 0, 1],
            vector[4, 127, 0, 0, 1],
            x"96d19c53f1bee2158c3fcfb5bb2f06d3a8237667529d2d8f0fbb22fe5c3b3e64748420b4103674490476d98530d063271222d2a59b0f7932909cc455a30f00c69380e6885375e94243f7468e9563aad29330aca7ab431927540e9508888f0e1c",
            x"8b9794dfd11b88e16ba8f6a4a2c1e7580738dce2d6910ee594bebd88297b22ae8c34d1ee3f5a081159d68e076ef5d30b",
            vector[4 ,42, 42, 42, 42],
            vector[4, 43, 43, 43, 43],
        );

        test_scenario::return_shared(system_state);
        test_scenario::end(scenario_val);

        // Test pending validator metadata changes
        let new_validator_addr = @0x8e3446145b0c7768839d71840df389ffa3b9742d0baaff326a3d453b595f87d7;
        let scenario_val = test_scenario::begin(new_validator_addr);
        let scenario = &mut scenario_val;
        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        test_scenario::next_tx(scenario, new_validator_addr);
        {
            let ctx = test_scenario::ctx(scenario);
            sui_system::request_add_validator(
                &mut system_state,
                x"96d19c53f1bee2158c3fcfb5bb2f06d3a8237667529d2d8f0fbb22fe5c3b3e64748420b4103674490476d98530d063271222d2a59b0f7932909cc455a30f00c69380e6885375e94243f7468e9563aad29330aca7ab431927540e9508888f0e1c",
                vector[32, 219, 38, 23, 242, 109, 116, 235, 225, 192, 219, 45, 40, 124, 162, 25, 33, 68, 52, 41, 123, 9, 98, 11, 184, 150, 214, 62, 60, 210, 121, 62],
                vector[68, 55, 206, 25, 199, 14, 169, 53, 68, 92, 142, 136, 174, 149, 54, 215, 101, 63, 249, 206, 197, 98, 233, 80, 60, 12, 183, 32, 216, 88, 103, 25],
                x"aab2e79154f15ba57b059ced2bc3e30fdcfd2d5e2cbe93d2a4fe3f9559dd7d0e571d44e48c79cf35a9ace3a7e09ef41a",
                b"ValidatorName2",
                b"description2",
                b"image_url2",
                b"project_url2",
                vector[4, 127, 0, 0, 2],
                vector[4, 127, 0, 0, 2],
                vector[4, 127, 0, 0, 1],
                vector[4, 127, 0, 0, 1],
                coin::mint_for_testing(100, ctx),
                1,
                0,
                ctx,
            );
        };

        test_scenario::next_tx(scenario, new_validator_addr); 
        {
            update_metadata(
                scenario,
                &mut system_state,
                b"new_validator_new_name",
                x"adf2e2350fe9a58f3fa50777499f20331c4550ab70f6a4fb25a58c61b50b5366107b5c06332e71bb47aa99ce2d5c07fe0dab04b8af71589f0f292c50382eba6ad4c90acb010ab9db7412988b2aba1018aaf840b1390a8b2bee3fde35b4ab7fdf",
                x"a8feb7fa8b85c5712c4613df09c7dd0df9c727ef000e17a1ea3e0d023eb5e426e3ab16251cdd35053b5807da123566c0",
                vector[4, 66, 66, 66, 66],
                vector[4, 77, 77, 77, 77],
            );
        };

        test_scenario::next_tx(scenario, new_validator_addr);
        let validator = sui_system::pending_validator_by_address(&system_state, new_validator_addr);
        verify_metadata(
            validator,
            b"new_validator_new_name",
            x"96d19c53f1bee2158c3fcfb5bb2f06d3a8237667529d2d8f0fbb22fe5c3b3e64748420b4103674490476d98530d063271222d2a59b0f7932909cc455a30f00c69380e6885375e94243f7468e9563aad29330aca7ab431927540e9508888f0e1c",
            x"aab2e79154f15ba57b059ced2bc3e30fdcfd2d5e2cbe93d2a4fe3f9559dd7d0e571d44e48c79cf35a9ace3a7e09ef41a",
            vector[4, 127, 0, 0, 2],
            vector[4, 127, 0, 0, 2],
            x"adf2e2350fe9a58f3fa50777499f20331c4550ab70f6a4fb25a58c61b50b5366107b5c06332e71bb47aa99ce2d5c07fe0dab04b8af71589f0f292c50382eba6ad4c90acb010ab9db7412988b2aba1018aaf840b1390a8b2bee3fde35b4ab7fdf",
            x"a8feb7fa8b85c5712c4613df09c7dd0df9c727ef000e17a1ea3e0d023eb5e426e3ab16251cdd35053b5807da123566c0",
            vector[4, 66, 66, 66, 66],
            vector[4, 77, 77, 77, 77],
        );

        test_scenario::return_shared(system_state);

        // Advance epoch to effectuate the metadata changes.
        test_scenario::next_tx(scenario, new_validator_addr);
        advance_epoch(scenario);

        // Now both validators are active, verify their metadata.
        test_scenario::next_tx(scenario, new_validator_addr);
        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        let validator = sui_system::active_validator_by_address(&system_state, validator_addr);
        verify_metadata_after_advancing_epoch(
            validator,
            b"validator_new_name",
            x"96d19c53f1bee2158c3fcfb5bb2f06d3a8237667529d2d8f0fbb22fe5c3b3e64748420b4103674490476d98530d063271222d2a59b0f7932909cc455a30f00c69380e6885375e94243f7468e9563aad29330aca7ab431927540e9508888f0e1c",
            x"8b9794dfd11b88e16ba8f6a4a2c1e7580738dce2d6910ee594bebd88297b22ae8c34d1ee3f5a081159d68e076ef5d30b",
            vector[4, 42, 42, 42, 42],
            vector[4, 43, 43, 43, 43],
        );

        let validator = sui_system::active_validator_by_address(&system_state, new_validator_addr);
        verify_metadata_after_advancing_epoch(
            validator,
            b"new_validator_new_name",
            x"adf2e2350fe9a58f3fa50777499f20331c4550ab70f6a4fb25a58c61b50b5366107b5c06332e71bb47aa99ce2d5c07fe0dab04b8af71589f0f292c50382eba6ad4c90acb010ab9db7412988b2aba1018aaf840b1390a8b2bee3fde35b4ab7fdf",
            x"a8feb7fa8b85c5712c4613df09c7dd0df9c727ef000e17a1ea3e0d023eb5e426e3ab16251cdd35053b5807da123566c0",
            vector[4, 66, 66, 66, 66],
            vector[4, 77, 77, 77, 77],
        );

        test_scenario::return_shared(system_state);
        test_scenario::end(scenario_val);
    }
}
