package com.myorg;

import com.google.common.base.Charsets;
import com.google.common.hash.Hashing;
import com.google.common.io.Resources;
import software.amazon.awscdk.core.App;
import software.amazon.awscdk.core.Environment;
import software.amazon.awscdk.core.Stack;
import software.amazon.awscdk.core.StackProps;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
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
        final Environment lambdaEdge = Environment.builder()
                .account("519160639284")
                .region("us-east-1")
                .build();

        final List<String> pingerRegions = Arrays.asList(
                "us-west-2",
                "us-west-1",
                "us-east-2",
                "us-east-1",
                "eu-west-2",
                "me-south-1",
                "ca-central-1"
        );


        final String rewriteLambdaCode = Resources.toString(
                Resources.getResource("rewrite.js"), Charsets.UTF_8);
        final String rewriteLambdaCodeHash = Hashing.sha256()
                .hashString(rewriteLambdaCode, StandardCharsets.UTF_8).toString();

        // --------------------------------------------------------------------
        //  Pre-prod.
        //
        //  Lambda@Edge functions must be in us-east-1. Hence separate stack.
        // --------------------------------------------------------------------
        final String preprodHostname = "preprod-asim.ihsan.io";
        final String preprodStackName = "preprod-AsimIhsanIoCdkStack";
        final String preprodRewriteLambdaStackName = "preprod-AsimIhsanIoRewriteLambdaCdkStack";
        final String preprodRewriteLambdaOutputName = "PreprodAsimIhsanIoRewriteLambdaName";
        final String preprodRewriteLambdaVersionNumber = "000015";

        final RewriteLambdaEdgeStack preprodRewriteLambdaEdgeStack = new RewriteLambdaEdgeStack(
                app,
                preprodRewriteLambdaStackName,
                preprodRewriteLambdaOutputName,
                preprodRewriteLambdaVersionNumber,
                StackProps.builder()
                        .env(lambdaEdge)
                        .description("Blog pre-prod Lambda@Edge stack")
                        .build());

        final Stack preprodRootStack = new CdkStack(app, preprodStackName,
                preprodHostname,
                preprodRewriteLambdaStackName,
                preprodRewriteLambdaOutputName,
                rewriteLambdaCodeHash,
                StackProps.builder()
                        .env(environment)
                        .description("Blog pre-prod environment")
                        .build());
        preprodRootStack.addDependency(preprodRewriteLambdaEdgeStack);

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
                    preprodStackName,
                    StackProps.builder()
                            .env(pingerEnvironment)
                            .description(String.format("Blog pre-prod pinger environment for %s", pingerRegion))
                            .build());
            pingerStack.addDependency(preprodRootStack);
        }
        // --------------------------------------------------------------------

        // --------------------------------------------------------------------
        //  Prod.
        //
        //  Lambda@Edge functions must be in us-east-1. Hence separate stack.
        // --------------------------------------------------------------------
        final String prodHostname = "asim.ihsan.io";
        final String prodStackName = "prod-AsimIhsanIoCdkStack";
        final String prodRewriteLambdaStackName = "prod-AsimIhsanIoRewriteLambdaCdkStack";
        final String prodRewriteLambdaOutputName = "ProdAsimIhsanIoRewriteLambdaName";
        final String prodRewriteLambdaVersionNumber = "000015";

        final RewriteLambdaEdgeStack prodRewriteLambdaEdgeStack = new RewriteLambdaEdgeStack(
                app,
                prodRewriteLambdaStackName,
                prodRewriteLambdaOutputName,
                prodRewriteLambdaVersionNumber,
                StackProps.builder()
                        .env(lambdaEdge)
                        .description("Blog prod Lambda@Edge stack")
                        .build());

        final Stack prodRootStack = new CdkStack(app, prodStackName,
                prodHostname,
                prodRewriteLambdaStackName,
                prodRewriteLambdaOutputName,
                rewriteLambdaCodeHash,
                StackProps.builder()
                        .env(environment)
                        .description("Blog prod environment")
                        .build());
        prodRootStack.addDependency(prodRewriteLambdaEdgeStack);

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
                    prodStackName,
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
