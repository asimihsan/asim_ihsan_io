'use strict';

// See: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-lambda-function-code-cfnresponsemodule.html

const aws = require("aws-sdk");
const response = require('cfn-response');

exports.handler = (event, context) => {
  console.log("REQUEST RECEIVED:\n" + JSON.stringify(event));
  const {RequestType, ResourceProperties: {StackName, OutputKey}} = event;
  console.log("StackName: " + StackName);
  console.log("OutputKey: " + OutputKey);

  if (RequestType === 'Delete') {
    return response.send(event, context, response.SUCCESS);
  }

  const cfn = new aws.CloudFormation({region: 'us-east-2'});

  cfn.describeStacks({StackName}, (err, data) => {
    console.log("err: " + err);
    console.log("data: " + data);
    if (err) {
      console.log("Error during stack describe:\n", err);
      return response.send(event, context, response.FAILED, err);
    }
    const {Stacks} = data;
    const Output = Stacks[0].Outputs
      .filter(out => out.OutputKey === OutputKey)
      .map(out => out.OutputValue)
      .join();

    const responseData = {
        "Output": Output
    };
    response.send(event, context, response.SUCCESS, responseData);

  });
};