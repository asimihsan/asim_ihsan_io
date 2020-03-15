package com.myorg;

import software.amazon.awscdk.core.*;
import software.amazon.awscdk.services.certificatemanager.DnsValidatedCertificate;
import software.amazon.awscdk.services.certificatemanager.ICertificate;
import software.amazon.awscdk.services.cloudfront.*;
import software.amazon.awscdk.services.route53.*;
import software.amazon.awscdk.services.route53.targets.CloudFrontTarget;
import software.amazon.awscdk.services.s3.Bucket;
import software.amazon.awscdk.services.s3.BucketEncryption;
import software.amazon.awscdk.services.s3.BucketProps;
import software.amazon.awscdk.services.s3.deployment.BucketDeployment;
import software.amazon.awscdk.services.s3.deployment.ISource;
import software.amazon.awscdk.services.s3.deployment.Source;

import java.util.Collections;
import java.util.List;

public class CdkStack extends Stack {
    public CdkStack(final Construct scope, final String id) {
        this(scope, id, null, null);
    }

    public CdkStack(final Construct scope,
                    final String id,
                    final String domainName,
                    final StackProps props) {
        super(scope, id, props);

        // --------------------------------------------------------------------
        //  S3 bucket for static blog assets.
        // --------------------------------------------------------------------
        final Bucket bucket = new Bucket(this, "BlogBucket", BucketProps.builder()
                .publicReadAccess(true)
                .removalPolicy(RemovalPolicy.DESTROY)
                .versioned(false)
                .encryption(BucketEncryption.S3_MANAGED)
                .websiteIndexDocument("index.html")
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
        //  CloudFront distribution for assets.
        // --------------------------------------------------------------------
        final List<SourceConfiguration> sourceConfigurations = Collections.singletonList(
                SourceConfiguration.builder()
                        .s3OriginSource(S3OriginConfig.builder()
                                .s3BucketSource(bucket)
                                .build())
                        .behaviors(Collections.singletonList(Behavior.builder()
                                .isDefaultBehavior(true)
                                .build()))
                        .build()
        );
        final CloudFrontWebDistribution distribution = new CloudFrontWebDistribution(this, "CloudFront",
                CloudFrontWebDistributionProps.builder()
                        .originConfigs(sourceConfigurations)
                        .viewerCertificate(ViewerCertificate.fromAcmCertificate(certificate,
                                ViewerCertificateOptions.builder()
                                        .aliases(Collections.singletonList(domainName))
                                        .securityPolicy(SecurityPolicyProtocol.TLS_V1_1_2016)
                                        .sslMethod(SSLMethod.SNI)
                                        .build()))
                        .defaultRootObject("index.html")
                        .priceClass(PriceClass.PRICE_CLASS_ALL)
                        .build());
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
                .exportName("CloudfrontDomainNameExport")
                .value(distribution.getDomainName())
                .build();
    }
}