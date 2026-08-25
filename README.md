# Salesforce Governor Limit Utility

A reusable, production-ready Apex utility for monitoring Salesforce governor-limit consumption across different Apex execution contexts.

The goal of this project is to provide a centralized utility that any Apex class can use to inspect governor-limit usage, calculate remaining capacity, identify limits approaching their maximum, and generate structured debug logs.

---

## Features

* Reusable across any Apex class
* Monitor commonly used Salesforce governor limits
* Track current governor-limit usage
* Track maximum available capacity
* Calculate remaining capacity
* Calculate usage percentage
* Identify limits approaching their maximum
* Configurable warning thresholds
* Default 80% warning threshold
* Structured debug logging
* No SOQL performed by the utility
* No DML performed by the utility
* No callouts performed by the utility
* Suitable for synchronous Apex
* Suitable for asynchronous Apex
* Unit tested
* Uses Salesforce's `System.Limits` API instead of hard-coded governor-limit values

---

## Monitored Governor Limits

The utility currently monitors:

| Governor Limit  | Salesforce API                     |
| --------------- | ---------------------------------- |
| SOQL Queries    | `System.Limits.getQueries()`       |
| SOQL Query Rows | `System.Limits.getQueryRows()`     |
| DML Statements  | `System.Limits.getDmlStatements()` |
| DML Rows        | `System.Limits.getDmlRows()`       |
| CPU Time        | `System.Limits.getCpuTime()`       |
| Heap Size       | `System.Limits.getHeapSize()`      |
| Callouts        | `System.Limits.getCallouts()`      |
| Future Calls    | `System.Limits.getFutureCalls()`   |
| Queueable Jobs  | `System.Limits.getQueueableJobs()` |
| SOSL Queries    | `System.Limits.getSoslQueries()`   |

The utility retrieves the applicable maximum dynamically using methods such as:

```apex
System.Limits.getLimitQueries();
System.Limits.getLimitDmlStatements();
System.Limits.getLimitCpuTime();
```

This avoids hard-coding Salesforce governor-limit values.

---

## Project Structure

```text
salesforce-governor-limit-util/
│
├── force-app/
│   └── main/
│       └── default/
│           └── classes/
│               ├── GovernorLimitUtil.cls
│               ├── GovernorLimitUtil.cls-meta.xml
│               ├── GovernorLimitUtilTest.cls
│               └── GovernorLimitUtilTest.cls-meta.xml
│
├── .gitignore
├── README.md
└── sfdx-project.json
```

---

## Architecture

```text
                    Apex Application
                           |
                           v
                 +---------------------+
                 | GovernorLimitUtil   |
                 +---------------------+
                           |
             +-------------+-------------+
             |             |             |
             v             v             v
       System.Limits   LimitStatus   Threshold
                                      Evaluation
                           |
                           v
                    Structured Result
```

The consuming Apex class does not need to implement governor-limit calculations itself.

Instead, it calls `GovernorLimitUtil`.

---

# Usage

## 1. Get All Governor Limits

```apex
List<GovernorLimitUtil.LimitStatus> limits =
    GovernorLimitUtil.getAllLimits();
```

Each returned `LimitStatus` contains:

```text
name
used
maximum
remaining
usagePercentage
approachingLimit
```

Example:

```apex
for (GovernorLimitUtil.LimitStatus limit :
     GovernorLimitUtil.getAllLimits()) {

    System.debug(
        limit.name +
        ' | Used: ' + limit.used +
        ' | Maximum: ' + limit.maximum +
        ' | Remaining: ' + limit.remaining +
        ' | Usage: ' + limit.usagePercentage + '%'
    );
}
```

---

# 2. Check Whether a Governor Limit Is Approaching

The default warning threshold is 80%.

```apex
if (GovernorLimitUtil.isApproachingLimit()) {

    System.debug(
        'A governor limit is approaching its maximum.'
    );
}
```

This allows application code to perform a lightweight check without manually calculating percentages.

---

# 3. Use a Custom Warning Threshold

A custom threshold between 0 and 100 can be supplied.

For example, to check at 90%:

```apex
if (GovernorLimitUtil.isApproachingLimit(90)) {

    System.debug(
        'Governor limit usage has reached 90%.'
    );
}
```

Another example:

```apex
if (GovernorLimitUtil.isApproachingLimit(70)) {

    System.debug(
        'Governor limit usage has reached 70%.'
    );
}
```

---

# 4. Get Only the Limits That Are Approaching

To retrieve only the limits that have crossed the warning threshold:

```apex
List<GovernorLimitUtil.LimitStatus> approachingLimits =
    GovernorLimitUtil.getApproachingLimits();
```

Using a custom threshold:

```apex
List<GovernorLimitUtil.LimitStatus> approachingLimits =
    GovernorLimitUtil.getApproachingLimits(90);
```

You can then inspect them:

```apex
for (GovernorLimitUtil.LimitStatus limit :
     approachingLimits) {

    System.debug(
        limit.name +
        ' is using ' +
        limit.usagePercentage +
        '% of its available capacity.'
    );
}
```

---

# 5. Log Governor Limits

The utility provides centralized logging.

```apex
GovernorLimitUtil.logLimits(
    'AccountService - Start'
);
```

Example debug output:

```text
===== AccountService - Start =====

SOQL Queries
Used: 1
Maximum: 100
Remaining: 99
Usage: 1.00%
Approaching: false

DML Statements
Used: 0
Maximum: 150
Remaining: 150
Usage: 0.00%
Approaching: false

CPU Time
Used: 12
Maximum: 10000
Remaining: 9988
Usage: 0.12%
Approaching: false

====================================
```

The context parameter allows developers to identify where the governor-limit snapshot was taken.

For example:

```apex
GovernorLimitUtil.logLimits(
    'OpportunityService - Before Processing'
);
```

and:

```apex
GovernorLimitUtil.logLimits(
    'OpportunityService - After Processing'
);
```

---

# Complete Example

The utility can be used from any Apex service class.

```apex
public class AccountService {

    public static void processAccounts() {

        GovernorLimitUtil.logLimits(
            'AccountService - Start'
        );

        List<Account> accounts = [
            SELECT Id, Name
            FROM Account
            LIMIT 100
        ];

        update accounts;

        if (GovernorLimitUtil.isApproachingLimit()) {

            GovernorLimitUtil.logLimits(
                'AccountService - Limits Approaching'
            );
        }
    }
}
```

The same utility can also be used from:

* Trigger handlers
* Service classes
* Queueable classes
* Batch Apex
* Scheduled Apex
* Controllers
* Domain classes
* Other reusable Apex frameworks

---

# Design Decisions

## 1. Use `System.Limits`

The utility explicitly uses:

```apex
System.Limits
```

instead of relying on hard-coded governor-limit values.

For example:

```apex
System.Limits.getQueries();
System.Limits.getLimitQueries();
```

This allows Salesforce to provide the applicable limit for the current execution context.

---

## 2. No Hard-Coded Governor Limits

The utility does not assume values such as:

```text
100 SOQL queries
150 DML statements
10,000 ms CPU time
```

Instead, it dynamically retrieves both the current usage and the applicable maximum.

This makes the utility more maintainable and resilient to different Apex execution contexts.

---

## 3. No Database Operations

The monitoring utility itself performs:

```text
SOQL:     0
DML:      0
Callouts: 0
```

It only reads governor-limit counters through Salesforce's `System.Limits` API.

This is important because a monitoring utility should avoid unnecessarily consuming the resources it is designed to monitor.

---

## 4. Structured `LimitStatus` Model

Instead of returning raw integers, the utility exposes:

```apex
GovernorLimitUtil.LimitStatus
```

Each object contains:

```text
name
used
maximum
remaining
usagePercentage
approachingLimit
```

This provides a consistent representation of governor-limit information.

---

## 5. Configurable Warning Threshold

Different applications may want different warning levels.

The default is:

```text
80%
```

Developers can override it:

```apex
GovernorLimitUtil.isApproachingLimit(90);
```

or:

```apex
GovernorLimitUtil.getApproachingLimits(70);
```

Valid thresholds are between:

```text
0 - 100
```

Invalid thresholds such as:

```text
-1
101
null
```

result in an `IllegalArgumentException`.

---

## 6. Centralized Logging

Without a utility, developers might duplicate code throughout their application:

```apex
System.debug(System.Limits.getQueries());
System.debug(System.Limits.getDmlStatements());
System.debug(System.Limits.getCpuTime());
```

Instead, the application can simply call:

```apex
GovernorLimitUtil.logLimits(
    'MyService - Before Processing'
);
```

This keeps application code cleaner and makes logging consistent.

---

# Testing Strategy

The `GovernorLimitUtilTest` class validates the behavior of the utility.

The test class covers:

* Governor-limit collection
* Limit metric validity
* Used limit values
* Maximum limit values
* Remaining capacity
* Usage percentage
* Approaching-limit detection
* Default warning threshold
* Custom warning threshold
* Governor-limit logging
* Blank logging context
* Null threshold handling
* Negative threshold handling
* Thresholds greater than 100

The tests intentionally do not attempt to consume thousands of SOQL queries or DML statements.

The purpose of the test class is to validate the utility's behavior rather than artificially exhaust Salesforce governor limits.

---

# Deployment

## Deploy Using Salesforce CLI

Deploy the Apex classes:

```bash
sf project deploy start \
    --source-dir force-app/main/default/classes
```

---

## Run the Utility Test

```bash
sf apex run test \
    --tests GovernorLimitUtilTest \
    --result-format human \
    --wait 10
```

---

## Run All Local Tests

```bash
sf apex run test \
    --test-level RunLocalTests \
    --result-format human \
    --wait 10
```

---

# Git Workflow

Initialize the repository:

```bash
git init
```

Check the repository:

```bash
git status
```

Stage files:

```bash
git add .
```

Create the first commit:

```bash
git commit -m "feat: add reusable Salesforce governor limit utility"
```

Rename the branch:

```bash
git branch -M main
```

Connect the GitHub repository:

```bash
git remote add origin https://github.com/YOUR_USERNAME/salesforce-governor-limit-util.git
```

Push:

```bash
git push -u origin main
```

For future changes:

```bash
git add .
git commit -m "feat: improve governor limit monitoring"
git push
```

---

# Technology

* Salesforce
* Apex
* Salesforce Governor Limits
* Salesforce CLI
* Apex Unit Testing
* Git
* GitHub

---

# Future Enhancements

Potential future versions could include:

* Custom Metadata-driven warning thresholds
* Persistent governor-limit snapshots
* Platform Event-based alerts
* Salesforce monitoring dashboards
* Transaction correlation IDs
* Additional governor-limit metrics
* JSON serialization for external monitoring systems
* Centralized logging framework integration
* Limit monitoring across asynchronous transaction chains
* Automated alerting when limits exceed configured thresholds

---

# Portfolio Value

This project demonstrates practical Apex engineering concepts including:

* Reusable Apex utility design
* Salesforce governor-limit awareness
* Defensive programming
* Dynamic limit detection
* Structured data modeling
* Configurable thresholds
* Apex unit testing
* Salesforce CLI deployment
* Git/GitHub project management
* Production-oriented documentation

The utility is intentionally small and focused, but it can serve as a reusable foundation for larger Salesforce monitoring and observability frameworks.

