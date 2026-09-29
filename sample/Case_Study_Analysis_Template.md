# Case Study Analysis Template

**Case Study:** Urban Maratho Event

> This Markdown version extracts the document structure and substantive content from the original presentation-oriented Excel workbook. Decorative formatting, merged cells, spacing, and repeated blank template rows have been simplified.

---

## 1. Project Backlog

### Estimation Guide

- **Estimation:** Fibonacci sequence
- **Priority:** H / M / L

### User Stories

| User Story # | Actor | I want to... | So that... | Estimation | Priority | Dependency |
|---|---|---|---|---:|---|---|
| 101 | Race Director | _To be completed_ | _To be completed_ |  |  |  |
| 201 | Participant | _To be completed_ | _To be completed_ |  |  |  |
| 301 | Volunteer Coordinator | _To be completed_ | _To be completed_ |  |  |  |
| 401 | Spectator | _To be completed_ | _To be completed_ |  |  |  |
| 501 | Vendor | _To be completed_ | _To be completed_ |  |  |  |

---

## 2. Constraints

| Project Constraints | Product Constraints |
|---|---|
| _To be completed_ | _To be completed_ |

---

## 3. Non-Functional Requirements (NFRs)

| NFR ID | Description | Estimation | Priority | Dependency |
|---|---|---:|---|---|
| NFR-S01 | Sensitive data must be encrypted in transit and at rest. | 5 | High | Registration, payment and tracking user stories |
| NFR-S02 | Access must be restricted according to assigned user roles. | 5 | High | Administrative and volunteer-management user stories |
| NFR-S03 | Security-sensitive actions must be recorded in tamper-resistant audit logs. | 5 | High | Registration, results and volunteer-management user stories |
| NFR-S04 | Participant location data must be shared only with authorised or consented users. | 8 | High | Live participant-tracking user story |
| NFR-S05 | Critical race-day services must remain available during traffic spikes and attacks. | 8 | High | Live tracking and notification user stories |

---

## 4. Risk Management

| Risk ID | Category | Description | Priority | Probability | Severity | Response Plan | Recovery Plan | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|
| R101 | _TBD_ | _TBD_ | _TBD_ | _TBD_ | _TBD_ | _TBD_ | _TBD_ | _TBD_ | _TBD_ |

---

## 5. Data Dictionary

| Reference # | Data Element | Variable Name | Format | Length | Description |
|---|---|---|---|---|---|
| DE1001 | _TBD_ | _TBD_ | _TBD_ | _TBD_ | _TBD_ |

---

# Architecture Analysis

## 6. C4 Analysis

### 6.1 C4 Level 1 — System Context

| Reference # | Element Name | Element Type | Description | Interaction with Marathon Management System | Source / Justification |
|---|---|---|---|---|---|
| L1-001 | Participant | Person | Registers for and participates in a marathon event | Registers, receives race updates, views routes and tracks race progress | Participant usage narrative |

### 6.2 C4 Level 2 — Container Analysis

| Reference # | Container Name | Container Type | Responsibility | Users Served | Communicates With | Data Used or Stored | NFR / Risk Justification |
|---|---|---|---|---|---|---|---|
| L2-001 | Backend API | Application/API | Processes application requests and coordinates marathon business functions | Web Application and Mobile Application users | Web Application, Mobile Application, Marathon Database and external systems | Registrations, schedules, assignments, tracking data and results | Supports scalability, security and centralised business-rule enforcement |

### 6.3 External Systems

| Reference # | External System Name | Responsibility | Connected Container | Data Sent to External System | Data Received from External System | Source / Justification |
|---|---|---|---|---|---|---|
| ES-001 | Payment Service | Processes marathon registration payments | Backend API | Payment amount, transaction reference and payment token | Payment status and transaction confirmation | Accept and manage entries |

---

## 7. Cloud Model Selection

### 7.1 Core Internal Containers

| C4 Element | Deployment Location | Selected Service Model | AWS Service | Azure Service |
|---|---|---|---|---|
| Web Application | Public cloud | PaaS | AWS Amplify Hosting | Azure Static Web Apps |

### 7.2 Internal Cloud Capabilities

| Cloud Capability | Purpose | Selected Service Model | AWS Service | Azure Service |
|---|---|---|---|---|
| IoT Data Ingestion | Receives checkpoint and finish-line data from timing devices | IoT PaaS | AWS IoT Core | Azure IoT Hub |

### 7.3 External Systems

| External System | Responsibility | Connected Cloud Capability | AWS Integration | Azure Integration |
|---|---|---|---|---|
| Payment Service | Processes registration and vendor payments | Backend API | Third-party provider connected through the Backend API | Third-party provider connected through the Backend API |

---

## 8. Dynamic Diagram Analysis

| Interaction # | Source | Destination | Data Flow | Sensitive Data | Trust Boundary |
|---:|---|---|---|---|---|
| 1 | Participant | Mobile/Web Application | Registration details | Personal information | Internet → Cloud |
| 2 | Mobile/Web Application | Backend API | Registration request and token | Personal information, token | Public → Application |

---

# Security Analysis

## 9. STRIDE Threat Model

| Threat ID | Diagram Element / Data Flow | STRIDE Category | Threat Description | Security Impact | Priority |
|---|---|---|---|---|---|
| T-01 | Participant login | Spoofing | An attacker uses stolen participant credentials | Confidentiality | High |
| T-02 | Registration request | Tampering | Registration category or payment amount is modified | Integrity | High |

---

## 10. Security Mitigation Analysis

| Threat ID | Mitigation Technique | Security Control | Responsible Element | Residual Risk |
|---|---|---|---|---|
| T-01 | Strong authentication | MFA, secure sessions and login monitoring | Identity Service | Medium |
| T-02 | Validate trusted values server-side | Input validation, TLS and integrity checks | Backend API | Low |

---

# Architecture Design and Evaluation

## 11. Architecture Smell Analysis

| Reference # | C4 Element | Architecture Smell | Evidence | Proposed Correction |
|---|---|---|---|---|
| AS-001 | Backend API | Feature Concentration | Handles registrations, schedules, volunteer assignments, tracking, results, and external integrations | Separate these responsibilities into focused architectural elements |

---

## 12. Architecture Pattern Analysis

| Architecture Style | Requirements Supported | Advantages | Disadvantages | Decision |
|---|---|---|---|---|
| Layered | Registration, event administration, volunteer management, vendor management, and results publishing | Clear separation between presentation, business logic, and data access; easier to understand, test, and maintain | Limited deployment independence; tightly coupled layers may restrict race-day scaling | Use for the internal organisation of the Web Application and Backend API |
| Service-Oriented | _To be completed_ | _To be completed_ | _To be completed_ | _To be completed_ |
| Event-Driven | _To be completed_ | _To be completed_ | _To be completed_ | _To be completed_ |
| Microservices | _To be completed_ | _To be completed_ | _To be completed_ | _To be completed_ |

---

## 13. Communication Pattern Analysis

| Source | Destination | Data Exchanged | Response | Dependency Holder | Pattern and Protocol | Justification |
|---|---|---|---|---|---|---|
| Web Application | Backend API | Registration and event-management requests | Immediate | Web Application | API — HTTPS/JSON | Users require an immediate confirmation or result |
| Timing and Checkpoint System | Event Queue | Runner identifier, checkpoint and event time | Delayed | Timing and Checkpoint System | Queue/Broker — asynchronous event message | Buffers race-day traffic and supports reliable processing |

---

## 14. Architecture Evaluation

| Requirement | Architectural Support | Rating (0–5) | Evidence | Improvement |
|---|---|---:|---|---|
| Participant registration | Web Application, Mobile Application, Backend API, Operational Database and Payment Service | 5 | Applications send registration requests to the Backend API, which coordinates payment and stores confirmed registrations | Add idempotency controls to prevent duplicate registrations and payments |
| Event administration | Web Application, Backend API and Operational Database | 5 | Race directors can manage routes, categories, schedules, volunteers and vendors through central business components | Add an audit log for administrative changes |

---

## 15. ATAM Evaluation

### Scenario: Large Burst of Timing Events at a Checkpoint

**Alternatives**

- **A:** Send events directly to the Backend API.
- **B:** Send events through IoT Data Ingestion and the Event Stream.

**Benefits**

- **A:** Simple architecture; immediate processing.
- **B:** Buffers traffic; supports independent scaling and reliable processing.

**Trade-offs**

- **A:** Backend API may become overloaded; events may be lost.
- **B:** Adds infrastructure, monitoring and event-ordering complexity.

**Decision:** Select Alternative B.

**Justification:** The Event Stream protects the Backend API and supports scalable race-day event processing.

---

## 16. HAZOP Analysis

| Interaction | Guide Word | Deviation | Cause | Consequence | Risk Priority | Mitigation | Responsible Element |
|---|---|---|---|---|---|---|---|
| Timing Devices → IoT Data Ingestion | No | No timing event is received | Device failure, network outage or depleted battery | Runner location and finish time cannot be recorded | High | Monitor device connectivity, buffer events locally and retransmit after reconnection | Timing Device and IoT Data Ingestion |
| Timing Devices → IoT Data Ingestion | More | Duplicate timing events are received | Device retry or repeated message delivery | Duplicate checkpoint records and incorrect race results | High | Assign a unique event ID and reject previously processed events | IoT Data Ingestion |

---

## 17. Architectural Decisions

### ADR-01 — Checkpoint Event Bursts

**Issue:** Checkpoint event bursts may overload the Backend API.

**Alternatives:** Process events directly through the Backend API; or use IoT Data Ingestion and an Event Stream.

**Decision:** Use IoT Data Ingestion and the Event Stream.

**Rationale:** Buffers race-day traffic, prevents Backend API overload and supports independent scaling.

**Affected C4 Elements:** Timing Devices, IoT Data Ingestion, Event Stream, Event Processing.

**Stakeholders:** Developers, Maintainers, Race Director.

### ADR-02 — Notification Provider Failure

**Issue:** Notification Provider failure may block user requests.

**Alternatives:** Synchronous provider calls; or asynchronous queued delivery.

**Decision:** Use asynchronous queued delivery.

**Rationale:** Isolates the Backend API from provider failures and supports retries.

**Affected C4 Elements:** Backend API, Notification Component, Event Stream, Notification Provider.

**Stakeholders:** Developers, Maintainers, Participants.
