# Technical Debt – CampusConnect 2.0

Last updated: 2026-11-22

## Purpose

This document tracks known technical debt, pending migrations
and maintenance tasks.

Dependency upgrades and architectural refactoring should be
handled separately to reduce regression risks.

## 1. Android Build Configuration

### Current baseline

| Component | Version |
|---|---|
| Flutter | 3.47.9 |
| Dart | 3.13.7 |
| Gradle | 8.14.3 |
| Android Gradle Plugin | 8.11.1 |
| Kotlin | 2.4.0 |
| Java | 21 |
| Android NDK | 28.2.13676358 |

### Completed

- [x] Accept missing Android SDK licenses
- [x] Update Gradle to 8.14.3
- [x] Update AGP to 8.11.1
- [x] Resolve Android NDK version mismatch
- [x] Successfully build Android debug APK
- [x] Resolve Dart analyzer issues

### Pending

- [ ] Migrate Gradle to 9.1.0 or later
- [ ] Migrate AGP to 9.0.1 or later
- [ ] Evaluate AGP 9 DSL migration
- [ ] Verify Kotlin compatibility
- [ ] Investigate remaining VS Code Gradle diagnostic

Priority: Medium

## 2. Firebase Dependencies

Major version upgrades are available.

| Package | Current | Available |
|---|---|---|
| firebase_core | 4.15.2 | 5.2.0 |
| firebase_auth | 6.7.1 | 7.1.0 |
| cloud_firestore | 6.10.2 | 7.2.0 |
| cloud_functions | 6.5.1 | 7.1.0 |
| firebase_messaging | 16.7.1 | 17.1.0 |
| firebase_storage | 13.6.1 | 14.1.0 |

### Pending

- [ ] Review breaking changes and migration guides
- [ ] Review security advisories
- [ ] Verify platform requirements
- [ ] Perform coordinated Firebase upgrade
- [ ] Test authentication and account deletion
- [ ] Test Firestore, Storage and notifications

Priority: Medium, reassess if security issues are identified

## 3. Third-Party Dependencies

- [ ] Evaluate Giphy Flutter SDK 2.0
- [ ] Evaluate cupertino_icons 2.0
- [ ] Investigate AndroidX and Jetifier warnings
- [ ] Review deprecated Java API warnings
- [ ] Review outdated transitive dependencies

Priority: Medium

## 4. Development Environment

- [ ] Review Flutter SDK updates
- [ ] Review Android Studio updates
- [ ] Configure Chrome for Flutter Web development

Priority: Low

## Definition of Done

A maintenance task is considered complete when:

- The relevant migration guides have been reviewed.
- Flutter analyze reports no issues.
- Builds succeed on affected platforms.
- Relevant regression tests pass.
- No credentials or sensitive data are committed.
- Changes are documented and committed to Git.
