// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use move_core_types::language_storage::StructTag;
use serde::{Deserialize, Serialize};
use serde_with::serde_as;
use serde_with::Bytes;
use std::convert::{From, TryFrom};
use sui_types::base_types::{ObjectDigest, SequenceNumber, TransactionDigest};
use sui_types::crypto::{sha3_hash, Signable};
use sui_types::error::SuiError;
use sui_types::move_package::MovePackage;
use sui_types::object::{Data, MoveObject, Object, Owner};

// Versioning process:
//
// Object storage versioning is done lazily (at read time) - therefore we must always preserve the
// code for reading the very first storage version. For all versions, a migration function
//
//   f(V_n) -> V_(n+1)
//
// must be defined. This way we can iteratively migrate the very oldest version to the very newest
// version at any point in the future.
//
// To change the format of the object table value types (StoreObject and StoreMoveObject), use the
// following process:
// - Add a new variant to the enum to store the new version type.
// - Extend the `migrate` functions to migrate from the previous version to the new version.
// - Change `From<Object> for StoreObjectPair` to create the newest version only.
//
// Additionally, the first time we version these formats, we will need to:
// - Add a check in the `TryFrom<StoreObjectPair> for Object` to see if the object that was just
//   read is the latest version.
// - If it is not, use the migration function (as explained above) to migrate it to the next
//   version.
// - Repeat until we have arrive at the current version.

/// Enum wrapper for versioning
#[derive(Eq, PartialEq, Debug, Clone, Deserialize, Serialize, Hash)]
pub enum StoreObject {
    V1(StoreObjectV1),
}

impl StoreObject {
    fn new(v1: StoreObjectV1) -> Self {
        Self::V1(v1)
    }

    pub fn migrate(s: Self) -> Self {
        // TODO: when there are multiple versions, we must iteratively migrate from version N to
        // N+1 until we arrive at the latest version
        s
    }

    // Always returns the most recent version. Older versions are migrated to the latest version at
    // read time, so there is never a need to access older versions.
    pub fn inner(&self) -> &StoreObjectV1 {
        match self {
            Self::V1(v1) => v1,

            // can remove #[allow] when there are multiple versions
            #[allow(unreachable_patterns)]
            _ => panic!("object should have been migrated to latest version at read time"),
        }
    }
    pub fn into_inner(self) -> StoreObjectV1 {
        match self {
            Self::V1(v1) => v1,

            // can remove #[allow] when there are multiple versions
            #[allow(unreachable_patterns)]
            _ => panic!("object should have been migrated to latest version at read time"),
        }
    }
}

/// Forked version of [`sui_types::object::Object`]
/// Used for efficient storing of move objects in the database
#[derive(Eq, PartialEq, Debug, Clone, Deserialize, Serialize, Hash)]
pub struct StoreObjectV1 {
    pub data: StoreData,
    pub owner: Owner,
    pub previous_transaction: TransactionDigest,
    pub storage_rebate: u64,
}

/// Forked version of [`sui_types::object::Data`]
/// Adds extra enum value `IndirectObject`, which represents a reference to an object stored separately
#[derive(Eq, PartialEq, Debug, Clone, Deserialize, Serialize, Hash)]
pub enum StoreData {
    Move(MoveObject),
    Package(MovePackage),
    IndirectObject(IndirectObjectMetadata),
}

/// Metadata of stored moved object
#[derive(Eq, PartialEq, Debug, Clone, Deserialize, Serialize, Hash)]
pub struct IndirectObjectMetadata {
    version: SequenceNumber,
    pub digest: ObjectDigest,
}

/// Enum wrapper for versioning
#[derive(Eq, PartialEq, Debug, Clone, Deserialize, Serialize, Hash)]
pub enum StoreMoveObject {
    V1(StoreMoveObjectV1),
}

impl StoreMoveObject {
    fn new(v1: StoreMoveObjectV1) -> Self {
        Self::V1(v1)
    }

    pub fn migrate(s: Self) -> Self {
        // TODO: when there are multiple versions, we must iteratively migrate from version N to
        // N+1 until we arrive at the latest version
        s
    }

    // Always returns the most recent version. Older versions are migrated to the latest version at
    // read time, so there is never a need to access older versions.
    pub fn inner(&self) -> &StoreMoveObjectV1 {
        match self {
            Self::V1(v1) => v1,

            // can remove #[allow] when there are multiple versions
            #[allow(unreachable_patterns)]
            _ => panic!("object should have been migrated to latest version at read time"),
        }
    }
    pub fn into_inner(self) -> StoreMoveObjectV1 {
        match self {
            Self::V1(v1) => v1,

            // can remove #[allow] when there are multiple versions
            #[allow(unreachable_patterns)]
            _ => panic!("object should have been migrated to latest version at read time"),
        }
    }
}

/// Separately stored move object
#[serde_as]
#[derive(Eq, PartialEq, Debug, Clone, Deserialize, Serialize, Hash)]
pub struct StoreMoveObjectV1 {
    pub type_: StructTag,
    has_public_transfer: bool,
    #[serde_as(as = "Bytes")]
    contents: Vec<u8>,
    /// reference count of `MoveMetadata` that point to the same content
    /// once it hits 0, the object gets deleted by a compaction job
    ref_count: usize,
}

impl<W> Signable<W> for StoreMoveObject
where
    W: std::io::Write,
{
    fn write(&self, writer: &mut W) {
        write!(writer, "StoreMoveObject::").expect("Hasher should not fail");
        bcs::serialize_into(writer, &self).expect("Message serialization should not fail");
    }
}

impl StoreMoveObject {
    pub fn digest(&self) -> ObjectDigest {
        ObjectDigest::new(sha3_hash(self))
    }
}

pub struct StoreObjectPair(pub StoreObject, pub Option<StoreMoveObject>);

impl From<Object> for StoreObjectPair {
    fn from(object: Object) -> Self {
        let mut indirect_object = None;

        let data = match object.data {
            Data::Package(package) => StoreData::Package(package),
            Data::Move(move_obj) => {
                // TODO: add real heuristic to decide if object needs to be stored indirectly
                if cfg!(test) {
                    let move_object = StoreMoveObject::new(StoreMoveObjectV1 {
                        type_: move_obj.type_.clone(),
                        has_public_transfer: move_obj.has_public_transfer(),
                        contents: move_obj.contents().to_vec(),
                        ref_count: 1,
                    });
                    let digest = move_object.digest();
                    indirect_object = Some(move_object);
                    StoreData::IndirectObject(IndirectObjectMetadata {
                        version: move_obj.version(),
                        digest,
                    })
                } else {
                    StoreData::Move(move_obj)
                }
            }
        };
        let store_object = StoreObject::new(StoreObjectV1 {
            data,
            owner: object.owner,
            previous_transaction: object.previous_transaction,
            storage_rebate: object.storage_rebate,
        });
        Self(store_object, indirect_object)
    }
}

impl TryFrom<StoreObjectPair> for Object {
    type Error = SuiError;

    fn try_from(object: StoreObjectPair) -> Result<Self, Self::Error> {
        let StoreObjectPair(store_object, indirect_object) = object;

        // Ensure we have latest format
        let store_object = StoreObject::migrate(store_object).into_inner();
        let indirect_object = indirect_object.map(|i| StoreMoveObject::migrate(i).into_inner());

        let data = match (store_object.data, indirect_object) {
            (StoreData::Move(object), None) => Data::Move(object),
            (StoreData::Package(package), None) => Data::Package(package),
            (StoreData::IndirectObject(metadata), Some(indirect_obj)) => unsafe {
                Data::Move(MoveObject::new_from_execution_with_limit(
                    indirect_obj.type_,
                    indirect_obj.has_public_transfer,
                    metadata.version,
                    indirect_obj.contents,
                    // verification is already done during initial execution
                    u64::MAX,
                )?)
            },
            _ => {
                return Err(SuiError::StorageCorruptedFieldError(
                    "inconsistent object representation".to_string(),
                ))
            }
        };

        Ok(Self {
            data,
            owner: store_object.owner,
            previous_transaction: store_object.previous_transaction,
            storage_rebate: store_object.storage_rebate,
        })
    }
}
