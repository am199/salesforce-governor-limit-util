/**
 * @description
 * Reusable utility for monitoring Salesforce governor-limit consumption.
 *
 * This class provides:
 * - Current governor-limit usage
 * - Maximum available limit
 * - Remaining capacity
 * - Usage percentage
 * - Configurable warning thresholds
 * - Structured debug logging
 *
 * The utility performs no SOQL, DML, or record access and can safely
 * be called from triggers, service classes, queueables, batch classes,
 * schedulables, controllers, and other Apex execution contexts.
 */
public class GovernorLimitUtil {

    /**
     * @description Default warning threshold.
     * A governor limit is considered approaching when usage reaches 80%.
     */
    public static final Decimal DEFAULT_WARNING_THRESHOLD = 80;

    /**
     * @description Represents the current state of a governor limit.
     */
    public class LimitStatus {

        public String name { get; private set; }
        public Integer used { get; private set; }
        public Integer maximum { get; private set; }
        public Integer remaining { get; private set; }
        public Decimal usagePercentage { get; private set; }
        public Boolean approachingLimit { get; private set; }

        public LimitStatus(
            String name,
            Integer used,
            Integer maximum,
            Decimal warningThreshold
        ) {
            this.name = name;
            this.used = used;
            this.maximum = maximum;
            this.remaining = Math.max(0, maximum - used);

            this.usagePercentage = maximum > 0
                ? (Decimal.valueOf(used) / Decimal.valueOf(maximum)) * 100
                : 0;

            this.approachingLimit =
                this.usagePercentage >= warningThreshold;
        }
    }

    /**
     * @description Returns the status of all commonly monitored
     * Salesforce governor limits.
     *
     * @return List of LimitStatus objects.
     */
    public static List<LimitStatus> getAllLimits() {

        List<LimitStatus> limitStatuses = new List<LimitStatus>();

        limitStatuses.add(
            createStatus(
                'SOQL Queries',
                System.Limits.getQueries(),
                System.Limits.getLimitQueries()
            )
        );

        limitStatuses.add(
            createStatus(
                'SOQL Query Rows',
                System.Limits.getQueryRows(),
                System.Limits.getLimitQueryRows()
            )
        );

        limitStatuses.add(
            createStatus(
                'DML Statements',
                System.Limits.getDmlStatements(),
                System.Limits.getLimitDmlStatements()
            )
        );

        limitStatuses.add(
            createStatus(
                'DML Rows',
                System.Limits.getDmlRows(),
                System.Limits.getLimitDmlRows()
            )
        );

        limitStatuses.add(
            createStatus(
                'CPU Time',
                System.Limits.getCpuTime(),
                System.Limits.getLimitCpuTime()
            )
        );

        limitStatuses.add(
            createStatus(
                'Heap Size',
                System.Limits.getHeapSize(),
                System.Limits.getLimitHeapSize()
            )
        );

        limitStatuses.add(
            createStatus(
                'Callouts',
                System.Limits.getCallouts(),
                System.Limits.getLimitCallouts()
            )
        );

        limitStatuses.add(
            createStatus(
                'Future Calls',
                System.Limits.getFutureCalls(),
                System.Limits.getLimitFutureCalls()
            )
        );

        limitStatuses.add(
            createStatus(
                'Queueable Jobs',
                System.Limits.getQueueableJobs(),
                System.Limits.getLimitQueueableJobs()
            )
        );

        limitStatuses.add(
            createStatus(
                'SOSL Queries',
                System.Limits.getSoslQueries(),
                System.Limits.getLimitSoslQueries()
            )
        );

        return limitStatuses;
    }

    /**
     * @description Returns governor limits that have reached the
     * supplied warning threshold.
     *
     * @param warningThreshold Percentage between 0 and 100.
     *
     * @return List of limits approaching their maximum.
     */
    public static List<LimitStatus> getApproachingLimits(
        Decimal warningThreshold
    ) {

        validateThreshold(warningThreshold);

        List<LimitStatus> approachingLimits =
            new List<LimitStatus>();

        for (LimitStatus status : getAllLimits()) {

            if (status.approachingLimit) {
                approachingLimits.add(status);
            }
        }

        return approachingLimits;
    }

    /**
     * @description Returns governor limits approaching the default
     * 80% warning threshold.
     *
     * @return List of limits approaching their maximum.
     */
    public static List<LimitStatus> getApproachingLimits() {

        return getApproachingLimits(
            DEFAULT_WARNING_THRESHOLD
        );
    }

    /**
     * @description Determines whether any monitored governor limit
     * has reached the supplied threshold.
     *
     * @param warningThreshold Percentage between 0 and 100.
     *
     * @return True if at least one limit has reached the threshold.
     */
    public static Boolean isApproachingLimit(
        Decimal warningThreshold
    ) {

        return !getApproachingLimits(
            warningThreshold
        ).isEmpty();
    }

    /**
     * @description Determines whether any monitored governor limit
     * has reached the default 80% threshold.
     *
     * @return True if a limit is approaching its maximum.
     */
    public static Boolean isApproachingLimit() {

        return isApproachingLimit(
            DEFAULT_WARNING_THRESHOLD
        );
    }

    /**
     * @description Logs all monitored governor limits to the debug log.
     *
     * @param context Description of where the check was performed.
     */
    public static void logLimits(String context) {

        String logContext = String.isBlank(context)
            ? 'Governor Limit Check'
            : context;

        System.debug(
            LoggingLevel.INFO,
            '===== ' + logContext + ' ====='
        );

        for (LimitStatus status : getAllLimits()) {

            System.debug(
                LoggingLevel.INFO,
                status.name +
                ' | Used: ' + status.used +
                ' | Maximum: ' + status.maximum +
                ' | Remaining: ' + status.remaining +
                ' | Usage: ' +
                status.usagePercentage.setScale(2) +
                '%' +
                ' | Approaching: ' +
                status.approachingLimit
            );
        }

        System.debug(
            LoggingLevel.INFO,
            '===================================='
        );
    }

    /**
     * @description Creates a LimitStatus object.
     */
    private static LimitStatus createStatus(
        String name,
        Integer used,
        Integer maximum
    ) {

        return new LimitStatus(
            name,
            used,
            maximum,
            DEFAULT_WARNING_THRESHOLD
        );
    }

    /**
     * @description Validates a governor-limit warning threshold.
     */
    private static void validateThreshold(
        Decimal warningThreshold
    ) {

        if (
            warningThreshold == null ||
            warningThreshold < 0 ||
            warningThreshold > 100
        ) {
            throw new IllegalArgumentException(
                'Warning threshold must be between 0 and 100.'
            );
        }
    }
}