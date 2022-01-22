package com.myorg;

import com.google.common.base.Charsets;
import com.google.common.collect.ImmutableMap;
import com.google.common.hash.Hashing;
import com.google.common.io.Resources;
import software.amazon.awscdk.CustomResource;
import software.amazon.awscdk.Duration;
import software.amazon.awscdk.Stack;
import software.amazon.awscdk.StackProps;
import software.amazon.awscdk.customresources.Provider;
import software.amazon.awscdk.services.events.Rule;
import software.amazon.awscdk.services.events.Schedule;
import software.amazon.awscdk.services.events.targets.LambdaFunction;
import software.amazon.awscdk.services.iam.Effect;
import software.amazon.awscdk.services.iam.PolicyStatement;
import software.amazon.awscdk.services.iam.Role;
import software.amazon.awscdk.services.iam.ServicePrincipal;
import software.amazon.awscdk.services.lambda.Code;
import software.amazon.awscdk.services.lambda.Function;
import software.amazon.awscdk.services.lambda.Runtime;
import software.amazon.awscdk.services.lambda.SingletonFunction;
import software.amazon.awscdk.services.logs.RetentionDays;
import software.amazon.awscdk.services.s3.Bucket;
import software.amazon.awscdk.services.s3.IBucket;
import software.constructs.Construct;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Collections;

public class PingerCdkStack extends Stack {
    public PingerCdkStack(final Construct scope,
                    final String id,
                    final String domainName,
                    final String blogStackName,
                    final StackProps props) throws IOException {
        super(scope, id, props);


        // --------------------------------------------------------------------
        //  Custom resource to get the BlogBucketArn value from the us-east-2 stack. CDK does not support this because
        //  it's in a different region.
        // --------------------------------------------------------------------
        final String blogStackBlogBucketArnOutputName = "BlogBucketArn";
        final String stackLookupLambdaCode = Resources.toString(
                Resources.getResource("cfn_stack_lookup.js"), Charsets.UTF_8);
        final String stackLookupLambdaCodeHash = Hashing.sha256()
                .hashString(stackLookupLambdaCode, StandardCharsets.UTF_8).toString();

        final SingletonFunction stackLookupLambda = SingletonFunction.Builder.create(this, "StackLookupLambda2")
                .uuid("07a5e6c6-136f-438e-8abf-ace443ace0ef")
                .handler("index.handler")
                .runtime(Runtime.NODEJS_12_X)
                .code(Code.fromInline(stackLookupLambdaCode))
                .timeout(Duration.seconds(60))
                .build();

        final Role stackLookupProviderRole =
                Role.Builder.create(this, "StackLookupProviderRole")
                        .assumedBy(new ServicePrincipal("lambda.amazonaws.com"))
                        .build();
        stackLookupProviderRole.addToPolicy(PolicyStatement.Builder.create()
                .effect(Effect.ALLOW)
                .actions(Collections.singletonList("cloudformation:DescribeStacks"))
                .resources(Collections.singletonList(
                        String.format("arn:aws:cloudformation:*:*:stack/%s/*", blogStackName)))
                .build());
        final Provider stackLookupProvider = Provider.Builder.create(this, "StackLookupProvider2")
                .onEventHandler(stackLookupLambda)
                .logRetention(RetentionDays.ONE_YEAR)
                .role(stackLookupProviderRole)
                .build();
        final CustomResource stackLookup = CustomResource.Builder.create(this, "BlogBucketCfnStackLookupOutput2")
                .serviceToken(stackLookupProvider.getServiceToken())
                .properties(ImmutableMap.of(
                        "StackName", blogStackName,
                        "OutputKey", blogStackBlogBucketArnOutputName,
                        "Region", "us-east-2",

                        // Need a key that changes when the stack lookup Lambda code changes, or else we never re-deploy
                        // it.
                        "LambdaHash", stackLookupLambdaCodeHash

                ))
                .build();
        final String blogBucketArn = stackLookup.getAttString("Output");
        final IBucket bucket = Bucket.fromBucketArn(this, "BlogBucketArn", blogBucketArn);
        // --------------------------------------------------------------------

        // --------------------------------------------------------------------
        //  Lambda function, needs access to S3 bucket.
        // --------------------------------------------------------------------
        final String pingerLambdaCode = Resources.toString(
                Resources.getResource("pinger.py"), Charsets.UTF_8);
        final String pingerLambdaCodeHash = Hashing.sha256()
                .hashString(pingerLambdaCode, StandardCharsets.UTF_8).toString();
        final Function pingerFunction = Function.Builder.create(this, "PingerLambdaFunction")
                .runtime(Runtime.PYTHON_3_8)
                .handler("pinger.handler")
                .code(Code.fromAsset("src/main/resources/"))
                .memorySize(1024)
                .timeout(Duration.minutes(2))
                .logRetention(RetentionDays.ONE_WEEK)
                .environment(ImmutableMap.<String, String>builder()
                        .put("HOSTNAME", domainName)
                        .put("BLOG_BUCKET_NAME", bucket.getBucketName())
                        .put("CODE_HASH", pingerLambdaCodeHash)
                        .build())
                .build();
        bucket.grantRead(pingerFunction);
        // --------------------------------------------------------------------

        // --------------------------------------------------------------------
        //  Run pinger periodically.
        // --------------------------------------------------------------------
        final LambdaFunction ruleTarget = LambdaFunction.Builder.create(pingerFunction).build();
        final Rule eventRule = Rule.Builder.create(this, "PingerRule")
                .schedule(Schedule.rate(Duration.hours(1)))
                .targets(Collections.singletonList(ruleTarget))
                .build();
        // --------------------------------------------------------------------
    }
}
