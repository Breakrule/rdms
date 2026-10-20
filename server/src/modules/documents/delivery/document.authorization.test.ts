import { after, before, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import type { AddressInfo } from 'node:net';
import type { Express } from 'express';

import { createApp } from '../../../app.js';
import { requireAuth } from '../../auth/auth.middleware.js';
import type { Principal, TokenVerifier } from '../../auth/token-verifier.js';
import type { WorkspaceProvisioner } from '../../auth/workspace-provisioner.js';
import { MockDocumentRepository } from '../infra/mock-document.repository.js';
import type { DocumentSyncPayload } from '../domain/document.entity.js';

const WS_A = 'ws-A';
const WS_B = 'ws-B';

// token -> principal, and principal.subject -> workspace. Mirrors what a
// real Keycloak + DbWorkspaceProvisioner would resolve, without needing
// either at runtime.
const PRINCIPALS: Record<string, Principal> = {
  'tok-a': { subject: 'user-a', email: 'a@example.gov' },
  'tok-b': { subject: 'user-b', email: 'b@example.gov' },
};
const WORKSPACES: Record<string, string> = {
  'user-a': WS_A,
  'user-b': WS_B,
};

class StubVerifier implements TokenVerifier {
  async verify(accessToken: string): Promise<Principal> {
    const principal = PRINCIPALS[accessToken];
    if (!principal) throw new Error('unverified token');
    return principal;
  }
}
class StubProvisioner implements WorkspaceProvisioner {
  async ensurePersonalWorkspace(principal: Principal): Promise<string> {
    return WORKSPACES[principal.subject];
  }
}

const sampleDoc = (overrides: Partial<DocumentSyncPayload> = {}): DocumentSyncPayload => ({
  clientLocalId: 'doc-1',
  title: 'Rahasia Negara A',
  categoryCode: 'SK',
  documentDate: '2026-01-15',
  fiscalYear: 2026,
  fileName: 'doc_1.pdf',
  fileSizeBytes: 1024,
  mimeType: 'application/pdf',
  sha256Hash: 'a'.repeat(64),
  ...overrides,
});

describe('Phase 3.1 requireAuth middleware', () => {
  const makeRes = () => {
    const res = {
      statusCode: 200,
      body: undefined as unknown,
      status(code: number) {
        res.statusCode = code;
        return res;
      },
      json(b: unknown) {
        res.body = b;
        return res;
      },
    };
    return res;
  };
  const makeReq = (authHeader?: string) => ({
    requestId: 'r-1',
    header(name: string) {
      if (name.toLowerCase() === 'authorization') return authHeader;
      return undefined;
    },
  });

  const mw = requireAuth({
    verifier: new StubVerifier(),
    workspaceProvisioner: new StubProvisioner(),
    enforce: true,
    localSubject: 'local-device',
    localWorkspaceId: 'ws-local',
  });

  it('rejects a request with no bearer token (401, fail closed)', async () => {
    const req = makeReq(undefined) as never;
    const res = makeRes();
    let called = false;
    await mw(req, res as never, () => {
      called = true;
    });
    assert.equal(res.statusCode, 401);
    assert.equal(called, false);
  });

  it('rejects a token the verifier cannot validate (401)', async () => {
    const req = makeReq('Bearer nonsense') as never;
    const res = makeRes();
    let called = false;
    await mw(req, res as never, () => {
      called = true;
    });
    assert.equal(res.statusCode, 401);
    assert.equal(called, false);
  });

  it('attaches the resolved workspace on a good token', async () => {
    const req = makeReq('Bearer tok-a') as never;
    const res = makeRes();
    let nextCalled = false;
    await mw(req, res as never, () => {
      nextCalled = true;
    });
    assert.equal(nextCalled, true);
    const auth = (req as unknown as { auth?: { workspaceId: string } }).auth;
    assert.equal(auth?.workspaceId, WS_A);
  });

  it('no-login (optional) mode assigns the local workspace when there is no token', async () => {
    const optional = requireAuth({
      verifier: new StubVerifier(),
      workspaceProvisioner: new StubProvisioner(),
      enforce: false,
      localSubject: 'local-device',
      localWorkspaceId: 'ws-local',
    });
    const req = makeReq(undefined) as never;
    const res = makeRes();
    let nextCalled = false;
    await optional(req, res as never, () => {
      nextCalled = true;
    });
    assert.equal(nextCalled, true);
    const auth = (req as unknown as { auth?: { workspaceId: string } }).auth;
    assert.equal(auth?.workspaceId, 'ws-local');
  });

  it('no-login (optional) mode still rejects a present-but-invalid token', async () => {
    const optional = requireAuth({
      verifier: new StubVerifier(),
      workspaceProvisioner: new StubProvisioner(),
      enforce: false,
      localSubject: 'local-device',
      localWorkspaceId: 'ws-local',
    });
    const req = makeReq('Bearer nonsense') as never;
    const res = makeRes();
    let nextCalled = false;
    await optional(req, res as never, () => {
      nextCalled = true;
    });
    assert.equal(res.statusCode, 401);
    assert.equal(nextCalled, false);
  });
});

describe('Phase 3.3 authorization across v1 and v2 (end to end)', () => {
  let app: Express;
  let server: ReturnType<Express['listen']>;
  let base = '';
  const repo = new MockDocumentRepository();

  before(async () => {
    app = createApp({
      tokenVerifier: new StubVerifier(),
      workspaceProvisioner: new StubProvisioner(),
      repository: repo,
      requireAuthentication: true,
    });
    server = app.listen(0);
    await new Promise<void>((resolve) => server.once('listening', () => resolve()));
    const { port } = server.address() as AddressInfo;
    base = `http://127.0.0.1:${port}`;
  });

  after(async () => {
    await new Promise<void>((resolve, reject) =>
      server.close((err) => (err ? reject(err) : resolve())),
    );
  });

  const call = async (
    method: string,
    path: string,
    opts: { token?: string; body?: unknown } = {},
  ) => {
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (opts.token) headers.Authorization = `Bearer ${opts.token}`;
    const res = await fetch(`${base}${path}`, {
      method,
      headers,
      body: opts.body === undefined ? undefined : JSON.stringify(opts.body),
    });
    const json = await res.json().catch(() => undefined);
    return { status: res.status, json: json as any };
  };

  it('returns 401 for unauthenticated document reads on both versions', async () => {
    const v1 = await call('GET', '/api/v1/documents');
    assert.equal(v1.status, 401);
    const v2 = await call('POST', '/api/v2/sync/batch', { body: { operations: [] } });
    assert.equal(v2.status, 401);
  });

  it('leaves the health probe reachable without a token (never 401)', async () => {
    const res = await call('GET', '/api/v1/health');
    assert.notEqual(res.status, 401);
  });

  it('isolates list/search/getById between two workspaces', async () => {
    // Workspace A writes a document through the API.
    const write = await call('POST', '/api/v1/sync/batch-metadata', {
      token: 'tok-a',
      body: { documents: [sampleDoc()] },
    });
    assert.equal(write.status, 200);
    assert.equal(write.json.data.inserted, 1);

    // A sees it.
    const listA = await call('GET', '/api/v1/documents', { token: 'tok-a' });
    assert.equal(listA.status, 200);
    assert.equal(listA.json.data.length, 1);

    // B sees nothing.
    const listB = await call('GET', '/api/v1/documents', { token: 'tok-b' });
    assert.equal(listB.json.data.length, 0);

    // B cannot find it by search either.
    const searchB = await call('GET', '/api/v1/documents/search?q=Rahasia', { token: 'tok-b' });
    assert.equal(searchB.json.data.length, 0);

    // The server id belongs to A; B gets 404, never A's row.
    const serverId = listA.json.data[0].id as string;
    const getB = await call('GET', `/api/v1/documents/${serverId}`, { token: 'tok-b' });
    assert.equal(getB.status, 404);
  });

  it('scopes reconcile per workspace', async () => {
    const reconcileB = await call('POST', '/api/v1/sync/reconcile', {
      token: 'tok-b',
      body: { items: [{ clientLocalId: 'doc-1', sha256Hash: 'a'.repeat(64) }] },
    });
    // doc-1 lives only in A; from B it is simply absent (missing), not a
    // leaked "match".
    assert.deepEqual(reconcileB.json.data.missingOnServer, ['doc-1']);
  });

  it('v2 batch is workspace-scoped: B cannot mutate or read A\'s document, and the ledger is isolated', async () => {
    // A creates doc-2 via v2.
    const a = await call('POST', '/api/v2/sync/batch', {
      token: 'tok-a',
      body: {
        operations: [
          { operationId: 'op-x', clientLocalId: 'doc-2', baseRevision: 0, kind: 'upsert', payload: sampleDoc({ clientLocalId: 'doc-2', title: 'A punya' }) },
        ],
      },
    });
    assert.equal(a.json.data.results[0].outcome, 'applied');
    assert.equal(a.json.data.results[0].revisionAfter, 1);

    // B uses the SAME operationId. If the ledger were global it would
    // return A's receipt; scoped, B must get its own fresh result.
    const b = await call('POST', '/api/v2/sync/batch', {
      token: 'tok-b',
      body: {
        operations: [
          { operationId: 'op-x', clientLocalId: 'doc-2', baseRevision: 0, kind: 'upsert', payload: sampleDoc({ clientLocalId: 'doc-2', title: 'B punya' }) },
        ],
      },
    });
    assert.equal(b.json.data.results[0].outcome, 'applied');

    // The two workspaces now hold independent documents that share a
    // clientLocalId — only possible because uniqueness is per-workspace.
    const listA = await call('GET', '/api/v1/documents', { token: 'tok-a' });
    const listB = await call('GET', '/api/v1/documents', { token: 'tok-b' });
    const aTitles = listA.json.data.map((d: { title: string }) => d.title);
    const bTitles = listB.json.data.map((d: { title: string }) => d.title);
    assert.ok(aTitles.includes('A punya'));
    assert.ok(!aTitles.includes('B punya'));
    assert.ok(bTitles.includes('B punya'));
    assert.ok(!bTitles.includes('A punya'));
  });
});

describe('Phase 3 no-login default (end to end)', () => {
  let server: ReturnType<Express['listen']>;
  let base = '';
  const repo = new MockDocumentRepository();

  before(async () => {
    const app = createApp({
      tokenVerifier: new StubVerifier(),
      workspaceProvisioner: new StubProvisioner(),
      repository: repo,
      requireAuthentication: false,
    });
    server = app.listen(0);
    await new Promise<void>((resolve) => server.once('listening', () => resolve()));
    const { port } = server.address() as AddressInfo;
    base = `http://127.0.0.1:${port}`;
  });

  after(async () => {
    await new Promise<void>((resolve, reject) =>
      server.close((err) => (err ? reject(err) : resolve())),
    );
  });

  const call = async (
    method: string,
    path: string,
    opts: { token?: string; body?: unknown } = {},
  ) => {
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (opts.token) headers.Authorization = `Bearer ${opts.token}`;
    const res = await fetch(`${base}${path}`, {
      method,
      headers,
      body: opts.body === undefined ? undefined : JSON.stringify(opts.body),
    });
    const json = await res.json().catch(() => undefined);
    return { status: res.status, json: json as any };
  };

  it('reads and writes documents with no token at all', async () => {
    const emptyList = await call('GET', '/api/v1/documents');
    assert.equal(emptyList.status, 200);

    const write = await call('POST', '/api/v1/sync/batch-metadata', {
      body: { documents: [sampleDoc()] },
    });
    assert.equal(write.status, 200);
    assert.equal(write.json.data.inserted, 1);

    const list = await call('GET', '/api/v1/documents');
    assert.equal(list.json.data.length, 1);
  });

  it('still isolates an authenticated workspace from the anonymous local one', async () => {
    // tok-a resolves to WS_A, which must not see the anonymous local write.
    const listA = await call('GET', '/api/v1/documents', { token: 'tok-a' });
    assert.equal(listA.status, 200);
    assert.equal(listA.json.data.length, 0);
  });
});
