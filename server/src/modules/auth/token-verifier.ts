/// Authenticated principal extracted from a *verified* access token.
///
/// This is identity only. Workspace ownership is deliberately NOT a token
/// claim (Phase 3.2): a personal workspace is a database-owned concept
/// resolved by the WorkspaceProvisioner, so revoking or remapping access
/// never depends on re-issuing tokens.
export interface Principal {
  readonly subject: string;
  readonly email?: string;
}

/// Validates a bearer access token and returns the principal, or throws.
///
/// The runtime implementation (Keycloak, via `jose`) MUST reject:
/// - a bad signature or unknown key,
/// - a token not issued by the configured issuer,
/// - an expired / not-yet-valid token,
/// - a token whose audience is not the RDMS API.
///
/// That audience rule is the Phase 3.1 guarantee that an OIDC *ID* token
/// or a Google *Drive* access token cannot be replayed against this API:
/// neither carries the RDMS API audience.
///
/// It is an interface so delivery tests can inject a stub verifier and
/// exercise authorization without a live identity provider.
export interface TokenVerifier {
  verify(accessToken: string): Promise<Principal>;
}
