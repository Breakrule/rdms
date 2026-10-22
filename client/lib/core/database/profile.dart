/// Identifies the local profile that owns data on THIS device.
///
/// Rev. 2 P0 introduces the concept for metric scoping; P1 threads it onto
/// every document row (Drift `v6`) and P2.5 turns it into real profile
/// partitioning. There is deliberately no login involved — see
/// `implementation_plan_major.md` §0.1 commitments 2 and 4.
///
/// The value is the SAME UUID that server migration `004_add_identity.sql`
/// seeds for the no-login "local device" workspace, so an unauthenticated
/// install and its metadata mirror agree on the scope without a handshake.
/// A future authenticated profile gets its own UUID from the verified token
/// and does NOT reuse this constant.
library;

const String kPersonalWorkspaceId =
    '00000000-0000-4000-8000-000000000001';
