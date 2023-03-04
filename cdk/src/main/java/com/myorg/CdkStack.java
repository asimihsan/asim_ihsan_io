package com.myorg;

import software.amazon.awscdk.CfnOutput;
import software.amazon.awscdk.Duration;
import software.amazon.awscdk.PhysicalName;
import software.amazon.awscdk.RemovalPolicy;
import software.amazon.awscdk.Stack;
import software.amazon.awscdk.StackProps;
import software.amazon.awscdk.services.certificatemanager.DnsValidatedCertificate;
import software.amazon.awscdk.services.certificatemanager.ICertificate;
import software.amazon.awscdk.services.cloudfront.*;
import software.amazon.awscdk.services.cloudfront.origins.S3Origin;
import software.amazon.awscdk.services.route53.ARecord;
import software.amazon.awscdk.services.route53.HostedZone;
import software.amazon.awscdk.services.route53.HostedZoneProviderProps;
import software.amazon.awscdk.services.route53.IHostedZone;
import software.amazon.awscdk.services.route53.RecordTarget;
import software.amazon.awscdk.services.route53.targets.CloudFrontTarget;
import software.amazon.awscdk.services.s3.BlockPublicAccess;
import software.amazon.awscdk.services.s3.Bucket;
import software.amazon.awscdk.services.s3.BucketEncryption;
import software.amazon.awscdk.services.s3.BucketProps;
import software.amazon.awscdk.services.s3.IBucket;
import software.amazon.awscdk.services.s3.LifecycleRule;
import software.amazon.awscdk.services.s3.deployment.BucketDeployment;
import software.amazon.awscdk.services.s3.deployment.ISource;
import software.amazon.awscdk.services.s3.deployment.Source;
import software.constructs.Construct;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class CdkStack extends Stack {
    public final IBucket blogBucket;

    public CdkStack(final Construct scope,
                    final String id,
                    final String domainName,
                    final String rewriteLambdaCode,
                    final StackProps props) throws IOException {
        super(scope, id, props);

        // --------------------------------------------------------------------
        //  S3 bucket for static blog assets.
        // --------------------------------------------------------------------
        final Bucket bucket = new Bucket(this, "BlogBucket", BucketProps.builder()
                .bucketName(PhysicalName.GENERATE_IF_NEEDED)
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
        //  S3 bucket for CloudFront access logs.
        // --------------------------------------------------------------------
        final Bucket cloudFrontAccessLogsBucket = new Bucket(this, "CloudFrontAccessLogsBucket", BucketProps.builder()
                .publicReadAccess(false)
                .blockPublicAccess(BlockPublicAccess.BLOCK_ALL)
                .removalPolicy(RemovalPolicy.DESTROY)
                .versioned(false)
                .encryption(BucketEncryption.S3_MANAGED)
                .lifecycleRules(Collections.singletonList(
                        LifecycleRule.builder()
                                .expiration(Duration.days(60))
                                .enabled(true)
                                .build()
                ))
                .build());
        // -------------------------------------------------------------------

        // --------------------------------------------------------------------
        //  CloudFront distribution for assets.
        // --------------------------------------------------------------------
        final Function distributionFunction = Function.Builder.create(this, "CloudFrontFunction")
                .functionName(id + "-RewriteDefaultIndexRequest")
                .code(FunctionCode.fromInline(rewriteLambdaCode))
                .build();
        final Distribution distribution = Distribution.Builder.create(this, "CloudFront")
                .enabled(true)
                .httpVersion(HttpVersion.HTTP2_AND_3)
                .certificate(certificate)
                .domainNames(Collections.singletonList(domainName))
                .defaultRootObject("")
                .priceClass(PriceClass.PRICE_CLASS_100)
                .enableLogging(false)
                .defaultBehavior(BehaviorOptions.builder()
                        .allowedMethods(AllowedMethods.ALLOW_GET_HEAD_OPTIONS)
                        .cachedMethods(CachedMethods.CACHE_GET_HEAD_OPTIONS)
                        .cachePolicy(CachePolicy.Builder.create(this, "CachePolicy")
                                .defaultTtl(Duration.days(1))
                                .minTtl(Duration.days(1))
                                .maxTtl(Duration.days(1))
                                .enableAcceptEncodingBrotli(true)
                                .enableAcceptEncodingGzip(true)
                                .build())
                        .compress(true)
                        .origin(S3Origin.Builder.create(bucket)
                                .originShieldRegion(this.getRegion())
                                .build())
                        .viewerProtocolPolicy(ViewerProtocolPolicy.REDIRECT_TO_HTTPS)
                        .functionAssociations(Collections.singletonList(
                                FunctionAssociation.builder()
                                        .eventType(FunctionEventType.VIEWER_REQUEST)
                                        .function(distributionFunction)
                                        .build()
                        ))
                        .build())
                .minimumProtocolVersion(SecurityPolicyProtocol.TLS_V1_2_2021)
                .build();
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
        //  Athena for querying the CloudFront access logs.
        // --------------------------------------------------------------------
//        final String athenaNamedQueryTemplate = Resources.toString(
//                Resources.getResource("athena_cloudfront_query.txt"), Charsets.UTF_8);
//        final String athenaNamedQueryString = String.format(athenaNamedQueryTemplate,
//                cloudFrontAccessLogsBucket.getBucketName());
//        final CfnNamedQuery athenaNamedQuery = new CfnNamedQuery(this, "AthenaCloudFrontQuery",
//                CfnNamedQueryProps.builder()
//                        .database("default")
//                        .name("cloudfront_logs")
//                        .queryString(athenaNamedQueryString)
//                        .build());
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

        this.blogBucket = bucket;

        CfnOutput.Builder.create(this, "CloudfrontDomainNameExport")
                .value(distribution.getDistributionDomainName())
                .build();

        CfnOutput.Builder.create(this, "CloudfrontDistribution")
                .value(distribution.getDistributionId())
                .build();

        CfnOutput.Builder.create(this, "BlogBucketName")
                .value(bucket.getBucketName())
                .build();

        CfnOutput.Builder.create(this, "BlogBucketArn")
                .value(bucket.getBucketArn())
                .build();

        CfnOutput.Builder.create(this, "CloudFrontAccessLogsBucketName")
                .value(cloudFrontAccessLogsBucket.getBucketName())
                .build();

        CfnOutput.Builder.create(this, "CloudFrontAccessLogsBucketArn")
                .value(cloudFrontAccessLogsBucket.getBucketArn())
                .build();
    }
}