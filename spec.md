**Assignment Overview and Conduct**

- This is a group assignment to be completed by groups. The groups need to be Self Assigned on Canvas.
- The assignment requires development and delivery of a written software architecture as described below.
- The assignment is worth **45 marks**(45%).
- The assignment is not expected to exceed **5000 words**(appendix excluded). It should also contain a number of architecture diagrams.
- You must develop an architecture for one of the case studies available on Canvas. The diagrams in the assignment can be completed using C4 model.

**Related Assessment**

Related to this assignment is a peer assessment of each of its sections. This is to be performed each week during the normal tutorial time. Professional work is normally reviewed or critiqued by your colleagues or peers since they are best qualified. Not only does this provide an opportunity for you to clarify your thoughts and decisions but it also provides a chance to overcome our very human tendency to seek evidence that our decisions and views of the world are correct. Too often they are less than correct.

**Participation in a review is required in order to receive marks for your presented work for that section of the assignment**.

You demonstrate your knowledge of the topic by being able to understand and critique someone else’s work. If you do not submit a useful review, there is no evidence that you understand the topic. The aggregate marks for all reviews will be scaled to **20%**of the subject marks.

**Subject Objectives**

This assignment reflects industry practice in which software architectures are developed in teams.

1. Describe the factors that affect the architectural context and requirements, including stakeholders and their interests, architectural qualities, business requirements and usage scenarios.
2. Develop and refine multiple views of a software system architecture.
3. Understand the key issues in choosing and implementing architectural patterns.
4. Reason about architectural designs to satisfy a system's quality attributes.
5. Develop a complete software architecture for a proposed solution to a realistic industry problem.

**How/When to submit**

The assignment is to be delivered, as a printable digital document, to a Turnitin assignment box on Canvas by midnight 30**Oct 2026.**An assignment submitted after the due date will be considered late and will lose marks as per FEIT policy.

**Brief overview of the Software Architecture Document**

The Software Architecture Document describes the design of the architecture and provides the basis on which further design and implementation work takes place. It should:

- Clearly state the system's purpose.
- Describe the system context, including major stakeholders, their characteristics and their interests in this architecture.
- Elaborate on customer needs through quality and usage scenarios, focusing on (1) system qualities affected by architectural patterns; (2) data management requirements; (3) interests in cloud adoption, (4) security and privacy requirements and (5, optional) AI/ML and IoT consideration.
- Provide a set of views that describe and progressively develop the architecture, including context diagram, container diagram, component diagrams and code diagrams (only major classes and interfaces are needed).
- Offer rationales for all major architectural decisions, justifying why/how your design meets the customer needs and adheres to design principles from various aspects including system qualities, data management, cloud adoption, security and privacy, and (optionally) AI/ML and IoT integration.
- Provide an evaluation of how well the proposed architecture achieves its business objectives.
- Provide alternative architectures that could also meet the business objectives (but only if you want high marks).
- Ensure the document is succinct, actionable, and facilitates further development, avoiding overly complex or impractical designs.

The Software Architecture Document's primary purpose is both to capture the reasoning behind the architecture, and to enable further development in the construction phase. To that end:

- Make sure that the document is no longer or more verbose than needed. Remember that the document will be read (amongst others) by impatient software developers.
- Make sure that the document and your design are realistic. Do not design some fancy unfeasible architecture that the software development teams can’t or won't build. Everything in the architecture must be feasible, and that feasibility must be supported by reasoning or prototypes.
- **Glossary requirement:** Ensure that all legends, symbols, acronyms, and key terms used in the report are identified and defined in the appendix glossary. **The appendix must not exceed three pages**.

All reports **MUST**include a **signed** [**Contribution Table**](https://canvas.uts.edu.au/courses/39717/files/11508508?wrap=1)[Download Contribution Table](https://canvas.uts.edu.au/courses/39717/files/11508508/download?download_frd=1) to validate each student's contribution and teamwork. **All team members should sign on the contribution table**. Any individual who fails to sign on the contribution table will receive zero mark for the project.

## 48433 Software Architecture — Final Project Marking Criteria

**Core assessment:** 45 marks
**Optional AI/ML and IoT bonus:** Up to 7 additional marks

**Progressive marking rule:** Where a criterion is labelled “additional,” the mark may only be awarded when the preceding criteria in that subsection have been satisfied.

### 1. Project Context — 3 marks

| Row | Criterion | Purpose and required evidence | Marks |
| --- | --- | --- | --- |
| 1.1 | Project context | Describes the problem, the objectives of the proposed solution, the relevant stakeholders and their interests, and the major project risks and constraints. | 1 |
| 1.2 | Relevance justification | Explains why each identified stakeholder, interest, risk, and constraint is relevant to the project and its architecture. | +1 |
| 1.3 | Exclusion justification | Identifies other plausible stakeholders, risks, and constraints that were considered and explains why they were excluded from the project scope. | +1 |
| Category total | 3 |

### 2. Requirements Analysis — 8 marks, plus 2 bonus marks

| Row | Criterion | Purpose and required evidence | Marks |
| --- | --- | --- | --- |
| System Qualities — 2 marks |
| 2.1 | System quality requirements | Defines the system requirements, system qualities, relevant non-functional requirements, linked to stakeholder needs. | 1 |
| 2.2 | Quality scenarios and justification | Evaluates risks associated with the required system qualities and justifies the architectural decisions used to address them. Identifies alternatives and explains why they were rejected. | +1 |
| Data Management — 2 marks |
| 2.3 | Data management requirements | Develops a data dictionary that defines each data element, including its format, length, description, and source, and connects the data elements to relevant customer and stakeholder needs. | 1 |
| 2.4 | Data scenarios and choices | Uses data scenarios to define validation rules, storage, access controls, retention, and data-ingestion requirements. Justifies the choice of relational database or NoSQL, data management system requirements. Identifies alternative solutions and explains why they were rejected. | +1 |
| Cloud Adoption — 2 marks |
| 2.5 | Cloud-adoption requirements | Describes the customer’s needs and interests in adopting cloud services. | 1 |
| 2.6 | Cloud scenarios and XaaS choices | Uses scenarios to justify relevant XaaS choices, identifies alternatives, and explains why the alternatives were rejected. | +1 |
| Security and Privacy — 2 marks |
| 2.7 | Security and privacy requirements | Describes the system’s security and privacy requirements. | 1 |
| 2.8 | CIA Triad and critical scenarios | Uses critical usage scenarios to elaborate confidentiality, integrity, and availability requirements and incorporates relevant regulatory requirements. | +1 |
| Core category total | 8 |
| 2.B | AI/ML and IoT requirements — Bonus | Describes AI/ML and/or IoT integration requirements through usage scenarios, justifies the requirement analysis, identifies alternatives, and explains why alternatives were rejected. | +2 |

### 3. Architecture Views — 10 marks

| Row | Criterion | Purpose and required evidence | Marks |
| --- | --- | --- | --- |
| 3.1 | C4 System Context diagram | Shows the overall system, system boundary, relevant users, external systems, external data sources, and correctly labelled relationships using consistent C4 notation. | 1 |
| C4 Container Diagram — 3 marks |
| 3.2 | Container identification | Identifies the system’s main applications, databases, services, and other major containers. | 1 |
| 3.3 | Container responsibilities | Clearly explains the responsibility of each container. | 1 |
| 3.4 | Container interactions | Correctly shows and labels interactions between containers using consistent C4 notation. | 1 |
| C4 Component Diagrams — 3 marks |
| 3.5 | Component identification | Identifies the critical components within the relevant containers. | 1 |
| 3.6 | Component responsibilities | Clearly defines the responsibility of each major component. | 1 |
| 3.7 | Component relationships | Accurately shows interactions and relationships between components using consistent C4 notation. | 1 |
| C4 Code Diagrams — 3 marks |
| 3.8 | Major code elements | Identifies the major classes, interfaces, and key methods without unnecessary implementation detail. | 1 |
| 3.9 | Code relationships | Clearly and correctly represents relationships between the major code elements. | 1 |
| 3.10 | Cross-view consistency | Ensures the code structure accurately reflects the Context, Container, and Component diagrams. | 1 |
| Category total | 10 |

### 4. Architectural Rationale and Decision-Making — 20 marks, plus 5 bonus marks

| Row | Criterion | Purpose and required evidence | Marks |
| --- | --- | --- | --- |
| Application Architecture — 5 marks |
| 4.1 | Quality requirements alignment | Connects the application design in Section 3 to the system quality requirements identified in Section 2. | 1 |
| 4.2 | Quality tactics | Explains how specific quality tactics help achieve the required system qualities. | 1 |
| 4.3 | Architectural patterns | Explains how the architectural patterns adopted in Section 3 support the required system qualities. | 1 |
| 4.4 | SOLID principles | Justifies how the application design adheres to relevant SOLID principles. | +1 |
| 4.5 | Avoidance of poor design | Demonstrates that the architecture avoids feature concentration, scattered functionality, dense structure, cyclic dependency, and unstable dependency. | +1 |
| Data Architecture — 5 marks |
| 4.6 | Context-level data architecture | Includes the relevant data analytics system in the C4 System Context diagram. | 1 |
| 4.7 | Container-level data architecture | Represents databases, ETL/ELT, Data Lakes, Data Warehouses, Data Marts, and backup facilities where relevant. | 1 |
| 4.8 | Component-level data modelling | Includes appropriate conceptual and logical data modelling in the Component diagrams. | 1 |
| 4.9 | Code-level data modelling | Includes the relevant physical data model in the Code diagram. | 1 |
| 4.10 | Data architecture justification | Justifies how the data architecture satisfies the data management requirements identified in Section 2. | +1 |
| Cloud Architecture — 5 marks |
| 4.11 | Cloud requirements alignment | Justifies how the architecture in Section 3 meets the cloud-adoption requirements identified in Section 2. | 1 |
| 4.12 | Cloud-native principles | Identifies the cloud-native architecture principles applied in the proposed design. | +1 |
| 4.13 | Cloud-native justification | Explains how the selected design decisions adhere to those cloud-native principles. | +1 |
| 4.14 | Deployment infrastructure | Provides a deployment diagram showing relevant physical and virtualised infrastructure, including IaaS, PaaS, physical servers, devices, or virtual machines. | +1 |
| 4.15 | Container and execution environments | Shows relevant containerised infrastructure and execution environments, such as Docker containers, database servers, Java EE servers, or Microsoft IIS. | +1 |
| Security and Privacy Architecture — 5 marks |
| 4.16 | Dynamic diagram | Provides a dynamic diagram showing the participants and ordered interactions in a critical system scenario. | 1 |
| 4.17 | Data flow | Uses the dynamic diagram to show how data flows through the system during the selected scenario. | 1 |
| 4.18 | Threat-model boundaries | Identifies system entry points and trust boundaries in the threat model. | +1 |
| 4.19 | STRIDE threats and mitigations | Uses a STRIDE table to identify threats across the STRIDE categories and lists suitable mitigation techniques. | +1 |
| 4.20 | Security and privacy justification | Justifies how the architecture satisfies the security and privacy requirements from Section 2 and mitigates the identified threats. | +1 |
| Core category total | 20 |
| 4.B | AI/ML and IoT architecture — Bonus | Justifies how the architecture in Section 3 meets the AI/ML and/or IoT integration requirements identified in Section 2. | +5 |

### 5. Architecture Evaluation and Alternatives — 4 marks

| Row | Criterion | Purpose and required evidence | Marks |
| --- | --- | --- | --- |
| 5.1 | Business-objective traceability | Identifies the original business objectives against which the proposed architecture will be evaluated. | 1 |
| 5.2 | Architecture evaluation | Evaluates how effectively the proposed architecture achieves the identified business objectives. | 1 |
| 5.3 | ATAM or HAZOP analysis | Extends the evaluation using ATAM or HAZOP analysis while avoiding overly complex or impractical designs. | +1 |
| 5.4 | Realistic alternatives | Proposes realistic alternative architectures and demonstrates their applicability and feasibility. | +1 |
| Category total | 4 |

### Mark Summary

| Category | Maximum |
| --- | --- |
| 1. Project Context | 3 |
| 2. Requirements Analysis | 8 |
| 3. Architecture Views | 10 |
| 4. Architectural Rationale and Decision-Making | 20 |
| 5. Architecture Evaluation and Alternatives | 4 |
| Core assessment total | 45 |
| Optional AI/ML and IoT bonus | Up to +7 |
