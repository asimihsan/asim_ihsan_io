package com.myorg;

import software.amazon.awscdk.core.App;
import software.amazon.awscdk.core.Environment;
import software.amazon.awscdk.core.StackProps;

import java.util.Arrays;

public class CdkApp {
    public static void main(final String[] args) {
        App app = new App();

        final Environment preprod = Environment.builder()
                .account("519160639284")
                .region("us-east-2")
                .build();

        new CdkStack(app, "AsimIhsanIoCdkStack",
                "asim-preprod.ihsan.io",
                StackProps.builder()
                        .env(preprod)
                        .description("Blog pre-prod environment")
                        .build());

        new CdkStack(app, "prod-AsimIhsanIoCdkStack",
                "asim.ihsan.io",
                StackProps.builder()
                        .env(preprod)
                        .description("Blog prod environment")
                        .build());

        app.synth();
    }
}
