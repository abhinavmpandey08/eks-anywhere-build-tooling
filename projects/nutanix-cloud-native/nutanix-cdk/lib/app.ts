#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { NutanixInfrastructureStack } from './nutanix-cdk-stack';

const app = new cdk.App();

const stack = new NutanixInfrastructureStack(app, 'NutanixInfrastructureStack', {
  env: {
    account: process.env.DEPLOYMENT_ACCOUNT_ID,
    region: process.env.DEPLOYMENT_ACCOUNT_REGION
  },
});

console.log(stack.environment)