import { createRemoteJWKSet, jwtVerify } from 'jose';
import type { Principal, TokenVerifier } from './token-verifier.js';

/// Production `TokenVerifier` for a Keycloak (or any standards OIDC)
/// issuer.
///
/// `jose.jwtVerify` checks signature (against the remote JWKS), issuer,
/// audience, and the time claims in one call. `createRemoteJWKSet` caches
/// keys and follows the token `kid`, so IdP key rotation is handled
/// without a restart (Phase 3.1).
export class KeycloakTokenVerifier implements TokenVerifier {
  private readonly jwks: ReturnType<typeof createRemoteJWKSet>;
  private readonly issuer: string;
  private readonly audience: string;

  constructor(opts: { issuer: string; audience: string; jwksUri: string }) {
    this.issuer = opts.issuer;
    this.audience = opts.audience;
    this.jwks = createRemoteJWKSet(new URL(opts.jwksUri));
  }

  async verify(accessToken: string): Promise<Principal> {
    const { payload } = await jwtVerify(accessToken, this.jwks, {
      issuer: this.issuer,
      audience: this.audience,
    });
    if (!payload.sub) {
      throw new Error('verified token has no subject');
    }
    return {
      subject: payload.sub,
      email: typeof payload.email === 'string' ? payload.email : undefined,
    };
  }
}
