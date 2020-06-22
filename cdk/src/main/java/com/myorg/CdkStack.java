package com.myorg;

import com.google.common.base.Charsets;
import com.google.common.collect.ImmutableMap;
import com.google.common.io.Resources;
import software.amazon.awscdk.core.*;
import software.amazon.awscdk.services.certificatemanager.DnsValidatedCertificate;
import software.amazon.awscdk.services.certificatemanager.ICertificate;
import software.amazon.awscdk.services.cloudformation.CustomResource;
import software.amazon.awscdk.services.cloudfront.*;
import software.amazon.awscdk.services.iam.Effect;
import software.amazon.awscdk.services.iam.PolicyStatement;
import software.amazon.awscdk.services.lambda.*;
import software.amazon.awscdk.services.lambda.Runtime;
import software.amazon.awscdk.services.route53.*;
import software.amazon.awscdk.services.route53.targets.CloudFrontTarget;
import software.amazon.awscdk.services.s3.Bucket;
import software.amazon.awscdk.services.s3.BucketEncryption;
import software.amazon.awscdk.services.s3.BucketProps;
import software.amazon.awscdk.services.s3.deployment.BucketDeployment;
import software.amazon.awscdk.services.s3.deployment.ISource;
import software.amazon.awscdk.services.s3.deployment.Source;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class CdkStack extends Stack {
    public CdkStack(final Construct scope,
                    final String id,
                    final String domainName,
                    final String rewriteLambdaStackName,
                    final String rewriteLambdaOutputName,
                    final String rewriteLambdaCodeHash,
                    final StackProps props) throws IOException {
        super(scope, id, props);

        // --------------------------------------------------------------------
        //  S3 bucket for static blog assets.
        // --------------------------------------------------------------------
        final Bucket bucket = new Bucket(this, "BlogBucket", BucketProps.builder()

                // TODO couldn't get S3 working without public access. I've had to add it as a static website
                // origin rather than an S3 origin, that may be the reason.
                .publicReadAccess(true)
                //.blockPublicAccess(BlockPublicAccess.BLOCK_ALL)

                .removalPolicy(RemovalPolicy.DESTROY)
                .versioned(false)
                .encryption(BucketEncryption.S3_MANAGED)
                .build());
        // --------------------------------------------------------------------

        // --------------------------------------------------------------------
        //  Create the certificate.
        // --------------------------------------------------------------------
        final IHostedZone hostedZone = HostedZone.fromLookup(this, "HostedZone",
                HostedZoneProviderProps.builder()
                        .domainName("ihsan.io")
                        .privateZone(false)
                        .build());
        final ICertificate certificate = DnsValidatedCertificate.Builder.create(
                this,
                "BlogCertificate"
        )
                .domainName(domainName)

                // CloudFront requires ACM certificates be in us-east-1
                .region("us-east-1")

                .hostedZone(hostedZone)
                .build();

        // --------------------------------------------------------------------

        // --------------------------------------------------------------------
        //  Custom resource to get the Lambda@Edge name from the us-east-1 stack. CDK does not support this because
        //  it's in a different region, and Lambda@Edge only supports functions created in us-east-1.
        //
        //  See: https://github.com/aws/aws-cdk/issues/1575#issuecomment-480738659
        // --------------------------------------------------------------------
        final String stackLookupLambdaCode = Resources.toString(
                Resources.getResource("cfn_stack_lookup.js"), Charsets.UTF_8);
        final SingletonFunction stackLookupLambda = SingletonFunction.Builder.create(this, "StackLookupLambda")
                .uuid("f7d4f730-4ee1-11e8-9c2d-fa7ae01bbebc")
                .handler("index.handler")
                .runtime(Runtime.NODEJS_12_X)
                .code(Code.fromInline(stackLookupLambdaCode))
                .timeout(Duration.seconds(60))
                .build();

        final software.amazon.awscdk.services.cloudformation.CustomResourceProvider stackLookupProvider = software.amazon.awscdk.services.cloudformation.CustomResourceProvider.fromLambda(stackLookupLambda);
        stackLookupLambda.addToRolePolicy(PolicyStatement.Builder.create()
                .effect(Effect.ALLOW)
                .actions(Collections.singletonList("cloudformation:DescribeStacks"))
                .resources(Collections.singletonList(
                        String.format("arn:aws:cloudformation:*:*:stack/%s/*", rewriteLambdaStackName)))
                .build());
        final software.amazon.awscdk.services.cloudformation.CustomResource stackLookup =
                CustomResource.Builder.create(this, "RewriteLambdaArnCfnStackLookupOutput")
                .provider(stackLookupProvider)
                .properties(ImmutableMap.of(
                        "StackName", rewriteLambdaStackName,
                        "OutputKey", rewriteLambdaOutputName,
                        "Region", "us-east-1",

                        // Need a key that changes when the rewrite Lambda code changes, or else we never re-deploy it.
                        "LambdaHash", rewriteLambdaCodeHash

                ))
                .build();
        final String rewriteLambdaArn = stackLookup.getAttString("Output");
        final IVersion rewriteLambdaVersion = Version.fromVersionArn(this, "RewriteLambda", rewriteLambdaArn);
        // --------------------------------------------------------------------

        // --------------------------------------------------------------------
        //  CloudFront distribution for assets.
        // --------------------------------------------------------------------
        final List<SourceConfiguration> sourceConfigurations = Collections.singletonList(
                SourceConfiguration.builder()
                        .s3OriginSource(S3OriginConfig.builder()
                                .s3BucketSource(bucket)
                                .build())
                        .behaviors(Collections.singletonList(Behavior.builder()
                                .isDefaultBehavior(true)
                                .compress(false)
                                .lambdaFunctionAssociations(Arrays.asList(
                                        LambdaFunctionAssociation.builder()
                                                .eventType(LambdaEdgeEventType.ORIGIN_REQUEST)
                                                .lambdaFunction(rewriteLambdaVersion)
                                                .build(),

                                        // Note that S3 deployment bucket does not set Content-Type or Content-Encoding
                                        // correctly, so for now use Lambda@Edge to set this.
                                        // https://github.com/aws/aws-cdk/issues/7090
                                        LambdaFunctionAssociation.builder()
                                                .eventType(LambdaEdgeEventType.ORIGIN_RESPONSE)
                                                .lambdaFunction(rewriteLambdaVersion)
                                                .build()))
                                .allowedMethods(CloudFrontAllowedMethods.GET_HEAD_OPTIONS)
                                .forwardedValues(CfnDistribution.ForwardedValuesProperty.builder()
                                        .queryString(false)
                                        .headers(Collections.singletonList("Accept-Encoding"))
                                        .build())
                                .build()))
                        .build()
        );
        final CloudFrontWebDistribution distribution = new CloudFrontWebDistribution(this, "CloudFront",
                CloudFrontWebDistributionProps.builder()
                        .httpVersion(HttpVersion.HTTP2)
                        .originConfigs(sourceConfigurations)
                        .viewerCertificate(ViewerCertificate.fromAcmCertificate(certificate,
                                ViewerCertificateOptions.builder()
                                        .aliases(Collections.singletonList(domainName))
                                        .securityPolicy(SecurityPolicyProtocol.TLS_V1_2_2018)
                                        .sslMethod(SSLMethod.SNI)
                                        .build()))
                        .viewerProtocolPolicy(ViewerProtocolPolicy.REDIRECT_TO_HTTPS)
                        .priceClass(PriceClass.PRICE_CLASS_200)
                        .defaultRootObject("")
                        .build());
        // --------------------------------------------------------------------

        // --------------------------------------------------------------------
        //  Only grant CloudFront read access to the S3 bucket, the S3 bucket
        //  should not be publicly readable.
        //
        //  Only seems to matter if you're using S3 origin as the origin. Here we use the S3 static website
        //  endpoint because we want to default to index.html as the object for Hugo posts.
        //
        //  References
        //  - https://github.com/aws-samples/serverless-retail-workshop/blob/master/infrastructure/src/main/java/fishing/lee/infrastructure/ContentDistribution.java
        // --------------------------------------------------------------------
//        final OriginAccessIdentity cloudFrontIdentity = OriginAccessIdentity.Builder.create(
//                this, "CloudFrontIdentity"
//        )
//                .comment("Allow CloudFront to reach the blog bucket")
//                .build();
//        bucket.addToResourcePolicy(PolicyStatement.Builder.create()
//                .actions(Collections.singletonList("s3:GetObject"))
//                .resources(Collections.singletonList(bucket.arnForObjects("*")))
//                .principals(Collections.singletonList(cloudFrontIdentity.getGrantPrincipal()))
//                .build());
        // --------------------------------------------------------------------

        // --------------------------------------------------------------------

        // --------------------------------------------------------------------
        //  The CloudFront distribution is using the domain as a CNAME, but you
        //  need the DNS A record from the domain name to CloudFront.
        // --------------------------------------------------------------------
        ARecord.Builder.create(this, "BlogDnsAlias")
                .zone(hostedZone)
                .recordName(domainName + ".")
                .target(RecordTarget.fromAlias(new CloudFrontTarget(distribution)))
                .build();
        // --------------------------------------------------------------------

        // --------------------------------------------------------------------
        //  Deploy local Hugo build to the S3 bucket, and invalidate the
        //  CloudFront distribution
        // --------------------------------------------------------------------
        final List<ISource> bucketDeploymentSources = Collections.singletonList(
                Source.asset("./../hugo/build")
        );
        BucketDeployment.Builder.create(this, "DeployWebsite")
                .sources(bucketDeploymentSources)
                .destinationBucket(bucket)
                .distribution(distribution)
                .build();
        // --------------------------------------------------------------------

        CfnOutput.Builder.create(this, "CloudfrontDomainNameExport")
                .value(distribution.getDomainName())
                .build();

        CfnOutput.Builder.create(this, "BlogBucketName")
                .value(bucket.getBucketName())
                .build();

        CfnOutput.Builder.create(this, "BlogBucketArn")
                .value(bucket.getBucketArn())
                .build();
    }
}