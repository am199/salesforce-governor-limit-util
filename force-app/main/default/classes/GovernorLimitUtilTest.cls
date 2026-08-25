@IsTest
private class GovernorLimitUtilTest {

    @IsTest
    static void getAllLimits_shouldReturnGovernorLimits() {

        Test.startTest();

        List<GovernorLimitUtil.LimitStatus> results =
            GovernorLimitUtil.getAllLimits();

        Test.stopTest();

        System.assertNotEquals(
            null,
            results,
            'Governor limit results should not be null.'
        );

        System.assert(
            results.size() > 0,
            'At least one governor limit should be returned.'
        );
    }


    @IsTest
    static void getAllLimits_shouldReturnValidMetrics() {

        Test.startTest();

        List<GovernorLimitUtil.LimitStatus> results =
            GovernorLimitUtil.getAllLimits();

        Test.stopTest();

        for (GovernorLimitUtil.LimitStatus result : results) {

            System.assertNotEquals(
                null,
                result.name,
                'Limit name should be populated.'
            );

            System.assert(
                result.used >= 0,
                'Used limit cannot be negative.'
            );

            System.assert(
                result.maximum > 0,
                'Maximum limit should be greater than zero.'
            );

            System.assert(
                result.remaining >= 0,
                'Remaining limit cannot be negative.'
            );

            System.assert(
                result.usagePercentage >= 0,
                'Usage percentage cannot be negative.'
            );

            System.assert(
                result.usagePercentage <= 100,
                'Usage percentage cannot exceed 100.'
            );
        }
    }


    @IsTest
    static void getApproachingLimits_shouldUseCustomThreshold() {

        Test.startTest();

        List<GovernorLimitUtil.LimitStatus> results =
            GovernorLimitUtil.getApproachingLimits(0);

        Test.stopTest();

        System.assertNotEquals(
            null,
            results,
            'Result should not be null.'
        );

        System.assert(
            results.size() > 0,
            'A 0% threshold should identify all monitored limits.'
        );

        for (GovernorLimitUtil.LimitStatus result : results) {

            System.assert(
                result.approachingLimit,
                'Returned limits should be marked as approaching.'
            );
        }
    }


    @IsTest
    static void getApproachingLimits_shouldUseDefaultThreshold() {

        Test.startTest();

        List<GovernorLimitUtil.LimitStatus> results =
            GovernorLimitUtil.getApproachingLimits();

        Test.stopTest();

        System.assertNotEquals(
            null,
            results,
            'Result should not be null.'
        );
    }


    @IsTest
    static void isApproachingLimit_shouldReturnBoolean() {

        Test.startTest();

        Boolean defaultResult =
            GovernorLimitUtil.isApproachingLimit();

        Boolean customResult =
            GovernorLimitUtil.isApproachingLimit(0);

        Test.stopTest();

        System.assertNotEquals(
            null,
            defaultResult,
            'Default result should be returned.'
        );

        System.assertEquals(
            true,
            customResult,
            'At a 0% threshold, at least one limit should be approaching.'
        );
    }


    @IsTest
    static void logLimits_shouldExecuteSuccessfully() {

        Test.startTest();

        GovernorLimitUtil.logLimits(
            'GovernorLimitUtilTest'
        );

        Test.stopTest();

        System.assert(
            true,
            'Governor limit logging should complete without errors.'
        );
    }


    @IsTest
    static void logLimits_shouldHandleBlankContext() {

        Test.startTest();

        GovernorLimitUtil.logLimits(null);

        Test.stopTest();

        System.assert(
            true,
            'Null logging context should be handled safely.'
        );
    }


    @IsTest
    static void invalidThreshold_shouldThrowException() {

        Boolean exceptionThrown = false;

        try {

            GovernorLimitUtil.getApproachingLimits(101);

        } catch (IllegalArgumentException exception) {

            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Threshold greater than 100 should throw an exception.'
        );
    }


    @IsTest
    static void negativeThreshold_shouldThrowException() {

        Boolean exceptionThrown = false;

        try {

            GovernorLimitUtil.getApproachingLimits(-1);

        } catch (IllegalArgumentException exception) {

            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Negative threshold should throw an exception.'
        );
    }


    @IsTest
    static void nullThreshold_shouldThrowException() {

        Boolean exceptionThrown = false;

        try {

            GovernorLimitUtil.getApproachingLimits(null);

        } catch (IllegalArgumentException exception) {

            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Null threshold should throw an exception.'
        );
    }
}