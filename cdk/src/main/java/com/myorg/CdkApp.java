package com.myorg;

import com.google.common.base.Charsets;
import com.google.common.io.Resources;
import software.amazon.awscdk.App;
import software.amazon.awscdk.Environment;
import software.amazon.awscdk.Stack;
import software.amazon.awscdk.StackProps;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

// TODO: refactor stacks into a construct that is re-usable for preprod and prod
public class CdkApp {
    public static void main(final String[] args) throws IOException {
        App app = new App();

        final Environment environment = Environment.builder()
                .account("519160639284")
                .region("us-east-2")
                .build();

        // Only useful to have pingers in regions where there is a CloudFront regional edge. The point is that
        // even a Lambda function pinging via CloudFront may go to a POP that isn't used by regular website viewers,
        // but falls back to an L2 regional edge cache which **is** used. We're tring to keep regional edge caches
        // warm.
        //
        // See: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowCloudFrontWorks.html
        // See: https://aws.amazon.com/cloudfront/pricing/
        final List<String> pingerRegions = Arrays.asList(
                // "us-west-2",
                // "us-west-1",
                // "us-east-2",
                // "us-east-1",
                // "eu-west-2"
        );


        final String rewriteLambdaCode = Resources.toString(
                Resources.getResource("rewrite.js"), Charsets.UTF_8);

        // --------------------------------------------------------------------
        //  Pre-prod.
        // --------------------------------------------------------------------
        final String preprodHostname = "preprod-asim.ihsan.io";
        final String preprodStackName = "preprod-AsimIhsanIoCdkStack";

        final CdkStack preprodRootStack = new CdkStack(app, preprodStackName,
                preprodHostname,
                rewriteLambdaCode,
                StackProps.builder()
                        .env(environment)
                        .description("Blog pre-prod environment")
                        .build());

        for (final String pingerRegion : pingerRegions) {
            final Environment pingerEnvironment = Environment.builder()
                    .account(environment.getAccount())
                    .region(pingerRegion)
                    .build();
            final String pingerStackName = String.format("preprod-AsimIhsanIoCdkPingerStack-%s", pingerRegion);
            final Stack pingerStack = new PingerCdkStack(
                    app,
                    pingerStackName,
                    preprodHostname,
                    preprodRootStack.blogBucket,
                    StackProps.builder()
                            .env(pingerEnvironment)
                            .description(String.format("Blog pre-prod pinger environment for %s", pingerRegion))
                            .build());
            pingerStack.addDependency(preprodRootStack);
        }
        // --------------------------------------------------------------------

        // --------------------------------------------------------------------
        //  Prod.
        // --------------------------------------------------------------------
        final String prodHostname = "asim.ihsan.io";
        final String prodStackName = "prod-AsimIhsanIoCdkStack";

        final CdkStack prodRootStack = new CdkStack(app, prodStackName,
                prodHostname,
                rewriteLambdaCode,
                StackProps.builder()
                        .env(environment)
                        .description("Blog prod environment")
                        .build());

        for (final String pingerRegion : pingerRegions) {
            final Environment pingerEnvironment = Environment.builder()
                    .account(environment.getAccount())
                    .region(pingerRegion)
                    .build();
            final String pingerStackName = String.format("prod-AsimIhsanIoCdkPingerStack-%s", pingerRegion);
            final Stack pingerStack = new PingerCdkStack(
                    app,
                    pingerStackName,
                    prodHostname,
                    prodRootStack.blogBucket,
                    StackProps.builder()
                            .env(pingerEnvironment)
                            .description(String.format("Blog prod pinger environment for %s", pingerRegion))
                            .build());
            pingerStack.addDependency(prodRootStack);
        }
        // --------------------------------------------------------------------

        app.synth();
    }
}
