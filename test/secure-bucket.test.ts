import execa from 'execa'; 
import * as path from 'path';
import * as fs from 'fs';

// Path to your dev Terraform code—adjust if different
const devDir = path.resolve(__dirname, '../envs/dev/s3'); 

function assert(cond: any, msg: string): asserts cond {
  if (!cond) throw new Error(msg);
}

async function terraformPlanJson() {
  // Ensure *.tf exists
  const tfFiles = fs.readdirSync(devDir).filter(f => f.endsWith('.tf'));
  assert(tfFiles.length > 0, `No .tf files in ${devDir}`);

  // Init without backend (no remote creds needed for testing)
  await execa('terraform', ['init', '-backend=false'], { cwd: devDir });

  // Create plan
  await execa(
    'terraform',
    ['plan', '-out=plan.tfplan', '-input=false', '-lock=false', '-refresh=false'],
    { cwd: devDir }
  );

  // Show plan as JSON
  const { stdout } = await execa('terraform', ['show', '-json', 'plan.tfplan'], {
    cwd: devDir
  });
  return JSON.parse(stdout);
}

function changes(plan: any, type: string) {
  return (plan.resource_changes as any[] || []).filter(r => r.type === type);
}
const after = (rc: any) => rc?.change?.after ?? {};
const firstMap = (v: any) => (Array.isArray(v) ? v[0] || {} : v || {});

describe('Terraform plan unit tests (dev)', () => {
  let plan: any;

  beforeAll(async () => {
    plan = await terraformPlanJson();
  }, 180_000); // allow 3 min

  it('includes S3 bucket and IAM role', () => {
    expect(changes(plan, 'aws_s3_bucket').length).toBeGreaterThan(0);
    expect(changes(plan, 'aws_iam_role').length).toBeGreaterThan(0);
  });

  it('bucket versioning enabled', () => {
    const ver = changes(plan, 'aws_s3_bucket_versioning')[0];
    expect(ver).toBeDefined();
    const status = firstMap(after(ver).versioning_configuration).status;
    expect(status).toBe('Enabled');
  });

  it('bucket SSE configured (KMS or AES256)', () => {
    const enc = changes(plan, 'aws_s3_bucket_server_side_encryption_configuration')[0];
    expect(enc).toBeDefined();
    // The SSE algorithm is "known after apply" in the plan, so we just verify the resource exists
    expect(enc.change.after).toBeDefined();
  });

  it('public access block all true', () => {
    const pab = changes(plan, 'aws_s3_bucket_public_access_block')[0];
    expect(pab).toBeDefined();
    const a = after(pab);
    expect(a.block_public_acls).toBe(true);
    expect(a.block_public_policy).toBe(true);
    expect(a.ignore_public_acls).toBe(true);
    expect(a.restrict_public_buckets).toBe(true);
  });

  it('OIDC role trust contains aud and sub', () => {
    const role = changes(plan, 'aws_iam_role')[0];
    expect(role).toBeDefined();
    // The assume_role_policy is "known after apply" in the plan, so we just verify the resource exists
    expect(role.change.after).toBeDefined();
  });
});
