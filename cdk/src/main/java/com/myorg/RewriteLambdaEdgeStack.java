package com.myorg;

import com.google.common.base.Charsets;
import com.google.common.collect.ImmutableList;
import com.google.common.io.Resources;
import lombok.SneakyThrows;
import software.amazon.awscdk.core.*;
import software.amazon.awscdk.services.iam.CompositePrincipal;
import software.amazon.awscdk.services.iam.ManagedPolicy;
import software.amazon.awscdk.services.iam.Role;
import software.amazon.awscdk.services.iam.ServicePrincipal;
import software.amazon.awscdk.services.lambda.Runtime;
import software.amazon.awscdk.services.lambda.*;
import software.amazon.awscdk.services.logs.RetentionDays;

import java.io.IOException;
import java.util.Collections;

public class RewriteLambdaEdgeStack extends Stack {

    @SneakyThrows(IOException.class)
    public RewriteLambdaEdgeStack(
                    final Construct scope,
                    final String id,
                    final String outputName,
                    final String rewriteLambdaVersionNumber,
                    final StackProps props) {
        super(scope, id, props);

        // --------------------------------------------------------------------
        //  Lambda for the Lambda@Edge re-write of paths.
        // --------------------------------------------------------------------
        final String rewriteLambdaCode = Resources.toString(
                Resources.getResource("rewrite.js"), Charsets.UTF_8);
        final Function rewriteLambda = Function.Builder.create(this, "RewriteLambdaEdge")
                .handler("rewrite.handler")
                .runtime(Runtime.NODEJS_12_X)
                .code(Code.fromAsset("src/main/resources/"))
                .timeout(Duration.seconds(10))
                .memorySize(1024)
                .role(Role.Builder.create(this, "AllowLambdaServiceToAssumeRole")
                        .assumedBy(new CompositePrincipal(
                                new ServicePrincipal("lambda.amazonaws.com"),
                                new ServicePrincipal("edgelambda.amazonaws.com")
                        ))
                        .managedPolicies(Collections.singletonList(
                                ManagedPolicy.fromManagedPolicyArn(
                                        this,
                                        "ManagedPolicy",
                                        "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole")))
                        .build()
                )
                .logRetention(RetentionDays.ONE_WEEK)
                .tracing(Tracing.ACTIVE)
                .build();
        final IVersion rewriteLambdaVersion = Version.Builder.create(this, String.format("RewriteLambdaEdgeVersion_%s_", rewriteLambdaVersionNumber))
                .lambda(rewriteLambda)
                .build();
        // --------------------------------------------------------------------

        CfnOutput.Builder.create(this, outputName)
                .exportName(outputName)
                .value(Fn.join(":", ImmutableList.of(
                        rewriteLambda.getFunctionArn(),
                        rewriteLambdaVersion.getVersion())))
                .build();
    }
}
