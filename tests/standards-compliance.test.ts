import { describe, it, expect, beforeEach } from 'vitest';
import {
  initSimnet,
  Simnet,
  Tx,
  Accounts,
  Account
} from './helpers';

describe('Standards Compliance Contract', () => {
  let simnet: Simnet;
  let deployer: Account;
  let supplier: Account;
  let standardId: number;
  
  beforeEach(async () => {
    simnet = await initSimnet();
    const accounts = simnet.getAccounts();
    deployer = accounts.get('deployer');
    supplier = accounts.get('wallet_1');
    
    // Create a standard for testing
    const receipt = await simnet.callPublicFn(
        'standards-compliance',
        'add-standard',
        [
          '"Organic Farming"',
          '"Sustainable farming practices without synthetic pesticides"'
        ],
        deployer.address
    );
    
    // Extract the standard ID from the result
    const result = receipt.result;
    standardId = parseInt(result.substring(result.indexOf('u') + 1));
  });
  
  
  it('should allow admin to record compliance', async () => {
    const receipt = await simnet.callPublicFn(
        'standards-compliance',
        'record-compliance',
        [
          `'${supplier.address}'`,
          `u${standardId}`,
          'true',
          'u10000'
        ],
        deployer.address
    );
    
    expect(receipt.result).toContain('(ok true)');
  });
  
  it('should correctly report compliance status', async () => {
    // Record compliance
    await simnet.callPublicFn(
        'standards-compliance',
        'record-compliance',
        [
          `'${supplier.address}'`,
          `u${standardId}`,
          'true',
          'u10000'
        ],
        deployer.address
    );
    
    // Check compliance status
    const receipt = await simnet.callReadOnlyFn(
        'standards-compliance',
        'check-compliance',
        [
          `'${supplier.address}'`,
          `u${standardId}`
        ],
        deployer.address
    );
    
    expect(receipt.result).toContain('true');
  });
 
});
