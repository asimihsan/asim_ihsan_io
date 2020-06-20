package com.myorg;

import software.amazon.awscdk.core.App;
import software.amazon.awscdk.core.Environment;
import software.amazon.awscdk.core.Stack;
import software.amazon.awscdk.core.StackProps;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

public class CdkApp {
    public static void main(final String[] args) throws IOException {
        App app = new App();

        final Environment environment = Environment.builder()
                .account("519160639284")
                .region("us-east-2")
                .build();
        final List<String> pingerRegions = Arrays.asList(
                "us-west-2",
                "us-west-1",
                "us-east-2",
                "us-east-1",
                "eu-west-2"
        );
        final String preprodHostname = "preprod-asim.ihsan.io";
        final String prodHostname = "asim.ihsan.io";

        final String preprodStackName = "preprod-AsimIhsanIoCdkStack";
        final Stack preprodRootStack = new CdkStack(app, preprodStackName,
                preprodHostname,
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
                    preprodStackName,
                    StackProps.builder()
                            .env(pingerEnvironment)
                            .description(String.format("Blog pre-prod pinger environment for %s", pingerRegion))
                            .build());
            pingerStack.addDependency(preprodRootStack);
        }

        final String prodStackName = "prod-AsimIhsanIoCdkStack";
        final Stack prodRootStack = new CdkStack(app, prodStackName,
                prodHostname,
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
                    prodStackName,
                    StackProps.builder()
                            .env(pingerEnvironment)
                            .description(String.format("Blog prod pinger environment for %s", pingerRegion))
                            .build());
            pingerStack.addDependency(prodRootStack);
        }


        app.synth();
    }
}
