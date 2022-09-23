import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';

export class NutanixInfrastructureStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    new cdk.CfnOutput(this, "test-output", {
      exportName: "test-output",
      value: "testing-123",
    });
  }
}
