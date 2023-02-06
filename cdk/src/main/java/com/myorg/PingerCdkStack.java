package com.myorg;

import com.google.common.base.Charsets;
import com.google.common.collect.ImmutableMap;
import com.google.common.hash.Hashing;
import com.google.common.io.Resources;
import software.amazon.awscdk.Duration;
import software.amazon.awscdk.Stack;
import software.amazon.awscdk.StackProps;
import software.amazon.awscdk.services.events.Rule;
import software.amazon.awscdk.services.events.Schedule;
import software.amazon.awscdk.services.events.targets.LambdaFunction;
import software.amazon.awscdk.services.lambda.Code;
import software.amazon.awscdk.services.lambda.Function;
import software.amazon.awscdk.services.lambda.Runtime;
import software.amazon.awscdk.services.logs.RetentionDays;
import software.amazon.awscdk.services.s3.IBucket;
import software.constructs.Construct;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Collections;

public class PingerCdkStack extends Stack {
    public PingerCdkStack(final Construct scope,
                    final String id,
                    final String domainName,
                    final IBucket blogBucket,
                    final StackProps props) throws IOException {
        super(scope, id, props);

        // --------------------------------------------------------------------
        //  Lambda function, needs access to S3 bucket.
        // --------------------------------------------------------------------
        final String pingerLambdaCode = Resources.toString(
                Resources.getResource("pinger.py"), Charsets.UTF_8);
        final String pingerLambdaCodeHash = Hashing.sha256()
                .hashString(pingerLambdaCode, StandardCharsets.UTF_8).toString();
        final Function pingerFunction = Function.Builder.create(this, "PingerLambdaFunction")
                .runtime(Runtime.PYTHON_3_9)
                .handler("pinger.handler")
                .code(Code.fromAsset("src/main/resources/"))
                .memorySize(1024)
                .timeout(Duration.minutes(2))
                .logRetention(RetentionDays.ONE_WEEK)
                .environment(ImmutableMap.<String, String>builder()
                        .put("HOSTNAME", domainName)
                        .put("BLOG_BUCKET_NAME", blogBucket.getBucketName())
                        .put("CODE_HASH", pingerLambdaCodeHash)
                        .build())
                .build();
        blogBucket.grantRead(pingerFunction);
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
