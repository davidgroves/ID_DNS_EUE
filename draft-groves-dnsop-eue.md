---
title: "Extended UPDATE Error (EUE) EDNS Option"
abbrev: "UPDATE Error Option"
category: std

docname: draft-groves-dnsop-eue-latest
submissiontype: IETF
number:
date:
consensus: true
v: 3
area: Operations and Management
workgroup: DNSOP Working Group
keyword:
  - DNS
  - UPDATE
  - EDNS
  - Dynamic DNS
  - DDNS
  - Error
venue:
  group: DNSOP
  type: Working Group
  mail: dnsop@ietf.org
  arch: https://mailarchive.ietf.org/arch/browse/dnsop/
  github: davidgroves/ID_DNS_EUE
  latest: https://davidgroves.github.io/ID_DNS_EUE/draft-groves-dnsop-eue.html

author:
  -
    fullname: David Groves
    organization: Nominet
    email: david.groves@nominet.uk

normative:
  RFC2119:
  RFC8174:
  RFC6891:
  RFC2136:
  RFC1034:
  RFC1035:
  RFC2181:
  RFC9499:

informative:
  RFC8914:
  RFC6672:
  RFC4035:
  RFC3007:

--- abstract

This document defines a new EDNS option, the Extended UPDATE Error
(EUE) option, for use with Dynamic DNS UPDATE operations as specified
in RFC 2136.  When a DNS UPDATE request fails, servers currently
return limited Response Codes (RCODEs) that do not fully convey the
reason for failure.  The EUE option defined here allows servers to
provide detailed information about why an UPDATE was rejected,
including which specific resource record in the UPDATE message caused
the failure.  This enables clients to take appropriate corrective
action or provide meaningful diagnostic information to operators.

--- middle

# Introduction

Dynamic DNS UPDATE {{RFC2136}} allows authorised clients to modify
DNS zone data.  When an UPDATE fails, the server returns one of
several Response Codes (RCODEs) defined in {{RFC2136}}, such as
REFUSED, SERVFAIL, YXDOMAIN, YXRRSET, NXRRSET, NOTAUTH, or NOTZONE.

While these RCODEs indicate that an UPDATE was unsuccessful, they
often do not provide sufficient information for a client to
understand why the failure occurred.  For example, an UPDATE might
be refused because:

* A CNAME RR already exists at the owner name where new RRs are
  being added
* An NS RR points to an in-zone name that lacks the required
  A or AAAA glue records
* The update would create a CNAME at an owner name where other
  data exists
* The update targets a domain name outside the zone

All of these scenarios might result in a REFUSED RCODE, leaving the
client unable to determine the actual cause of failure without
manual investigation.

The Extended DNS Errors (EDE) mechanism {{RFC8914}} was considered
for this purpose.  However, EDE's EXTRA-TEXT field is explicitly
designated for human consumption and not automated parsing.
Additionally, EDE provides no structured way to identify which
specific RR within an UPDATE message caused the failure.  Since
UPDATE messages may contain multiple RRs in both the Prerequisite
and Update sections, this limitation significantly reduces the
utility for automated systems.

This document therefore defines a new EDNS option {{RFC6891}}, the
Extended UPDATE Error (EUE) option, that includes structured fields
to identify both the failing section and the specific RR index
within that section.  This enables clients to programmatically
determine exactly which part of their UPDATE request caused the
failure.

## Use Cases

The EUE option defined in this document benefits several use cases:

* Automated provisioning systems that create DNS RRs as part of
  service deployment can receive actionable error information,
  including which specific RR in a batch UPDATE caused the failure,
  enabling automatic correction or precise problem reporting.

* Dynamic DNS clients (such as those used for home networks or
  dynamic IP addressing) can provide meaningful error messages
  to users when updates fail.

* DNS management APIs and tools can surface detailed error
  information rather than generic failure messages, and can
  programmatically identify the problematic record.

* Debugging and troubleshooting DNS configuration issues becomes
  more straightforward when both the exact cause of failure and
  the specific failing RR are known.

# Conventions and Definitions

{::boilerplate bcp14-tagged}

This document uses DNS terminology defined in {{RFC9499}}.  In
particular:

* "Owner name" refers to the domain name where a resource record
  is found.

* "RR" (Resource Record) refers to a single DNS record.

* "RRset" refers to a set of RRs with the same owner name, class,
  and type.

* "Node" refers to a point in the DNS namespace tree, identified
  by a domain name.

The term "in-zone" as used in this document refers to a domain
name that is a subdomain of, or equal to, the zone's origin (apex).

# Background: DNS UPDATE Error Signaling

## Existing RCODEs

{{RFC2136}} defines the following RCODEs specific to UPDATE operations:

| RCODE | Name | Description |
|-------|------|-------------|
| 6 | YXDOMAIN | Name exists when it should not |
| 7 | YXRRSET | RRset exists when it should not |
| 8 | NXRRSET | RRset does not exist when it should |
| 9 | NOTAUTH | Server not authoritative for zone |
| 10 | NOTZONE | Name not contained in zone |

Additionally, the standard RCODEs from {{RFC1035}} apply:

| RCODE | Name | Description |
|-------|------|-------------|
| 1 | FORMERR | Format error in UPDATE message |
| 2 | SERVFAIL | Server failure processing UPDATE |
| 5 | REFUSED | UPDATE refused for policy reasons |

Note that YXDOMAIN, YXRRSET, and NXRRSET are returned during
prerequisite processing ({{RFC2136}} Section 3.2) when the
client's explicit prerequisites fail.  These RCODEs indicate
that the zone state did not match what the client expected.
They are NOT used when the server rejects an UPDATE due to
internal constraint checks (such as the CNAME singleton rule)
during update processing.  Server-side constraint violations
typically result in REFUSED, which provides no indication of
which constraint was violated.

## Limitations

The existing RCODEs have several limitations:

1. **Ambiguity**: REFUSED is used for many different failure reasons,
   from authentication failures to zone integrity violations.

2. **No specificity**: When an UPDATE violates zone data constraints
   (such as adding data where a CNAME exists), there is no standard
   way to communicate the specific constraint that was violated.

3. **Limited debugging**: Operators must examine server logs to
   determine why an UPDATE failed, which may not be practical for
   automated systems or remote clients.

# Extended UPDATE Error EDNS Option Format

This section defines the Extended UPDATE Error (EUE) EDNS option.

## Option Format

The EUE option is encoded in the RDATA of an OPT pseudo-RR as
specified in {{RFC6891}}.  The wire format is as follows:

~~~
                                 1  1  1  1  1  1
     0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
   +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   |                 OPTION-CODE                  |
   +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   |                OPTION-LENGTH                 |
   +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   |                  INFO-CODE                   |
   +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   |    SECTION    |         RR-INDEX             |
   +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   |                                              |
   /                 EXTRA-TEXT                   /
   |                                              |
   +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
~~~

OPTION-CODE:
: 2 octets.  The EDNS option code assigned by IANA for the Extended
  UPDATE Error option (see {{iana}}).

OPTION-LENGTH:
: 2 octets.  The length of the payload (everything after
  OPTION-LENGTH) in octets.  MUST be at least 4.

INFO-CODE:
: 2 octets.  A 16-bit unsigned integer providing the error reason.
  Values are registered in the "Extended UPDATE Error Codes"
  registry (see {{iana}}).

SECTION:
: 1 octet.  Identifies which section of the UPDATE message
  contains the RR that caused the error.  Values are:

  * 0 = Prerequisite section (Answer section in DNS message)
  * 1 = Update section (Authority section in DNS message)

RR-INDEX:
: 2 octets.  A 16-bit unsigned integer containing the 0-based
  index of the RR within the indicated section that caused the
  error.

EXTRA-TEXT:
: A variable-length, UTF-8-encoded text field that MAY hold
  additional textual information.  This information is intended
  for human consumption.  The length is derived from OPTION-LENGTH
  minus 5 (the fixed header size).  This field MAY be zero-length.

## RR Identification Fields

The SECTION and RR-INDEX fields allow servers to indicate precisely
which RR in an UPDATE message caused the failure.

Per {{RFC2136}}, an UPDATE message repurposes the standard DNS
message sections:

* The Answer section contains Prerequisite RRs
* The Authority section contains Update RRs

The SECTION field maps to these as follows:

| SECTION | RFC 2136 Name | DNS Message Section |
|---------|---------------|---------------------|
| 0 | Prerequisite | Answer |
| 1 | Update | Authority |

The RR-INDEX field contains a 0-based index into the indicated
section.  For example, if an UPDATE message contains three RRs
in the Update section and the second RR causes a failure, the
server would set SECTION=1 and RR-INDEX=1.

# Extended UPDATE Error Codes

This section defines the initial set of INFO-CODE values for
the EUE option.  Each code includes guidance on when it should
be used and what EXTRA-TEXT content may be appropriate.

Unless otherwise noted, these INFO-CODEs are typically returned
with RCODE REFUSED.

## INFO-CODE 0: Other Error

The error does not match any of the other defined codes.
Implementations SHOULD include an EXTRA-TEXT value to provide
additional context.

This code is intended for errors that do not fit other categories
and for future extensibility.

## INFO-CODE 1: CNAME RR Exists at Owner Name

This INFO-CODE indicates that the UPDATE was rejected because a
CNAME RR already exists at the owner name where the client
attempted to add other RR types.

Per {{RFC1034}} Section 3.6.2, if a CNAME RR is present at a node,
no other data should be present (with exceptions for DNSSEC-related
RRs as clarified by later specifications).

The EXTRA-TEXT field MAY contain the text "CNAME exists" or similar
descriptive text.

## INFO-CODE 2: Other Data Exists at CNAME Owner Name

This INFO-CODE indicates that the UPDATE was rejected because the
client attempted to add a CNAME RR at an owner name where other
RR types already exist.

The EXTRA-TEXT field MAY indicate the RR type(s) that conflict
with the CNAME addition.

## INFO-CODE 3: DNAME RR Conflict

This INFO-CODE indicates that the UPDATE was rejected due to a
conflict involving a DNAME RR, as specified in {{RFC6672}}.
This includes attempts to add a DNAME where prohibited RRs
exist, or adding RRs that conflict with an existing DNAME.

## INFO-CODE 4: Missing Glue

This INFO-CODE indicates that the UPDATE was rejected because it
would create an NS RR pointing to an in-zone name for which no
address RRs (A or AAAA) exist or are being added in the same
UPDATE.

Servers MAY perform this check to ensure zone integrity, as
delegations to unresolvable nameservers can cause resolution
failures.

The EXTRA-TEXT field MAY contain the domain name of the target
that lacks glue records.

## INFO-CODE 5: Zone Apex Constraint

This INFO-CODE indicates that the UPDATE was rejected because it
would violate constraints on the zone apex.  Examples include:

* Attempting to delete the SOA RR
* Attempting to delete all NS RRs at the zone apex
* Adding prohibited RR types at the apex

Per {{RFC2136}} Section 3.4.2.3 and 3.4.2.4, certain RRs at
the zone apex cannot be deleted.

The EXTRA-TEXT field MAY describe the specific constraint
violated, such as "cannot delete SOA" or "cannot delete last NS".

## INFO-CODE 6: Singleton Type Conflict

This INFO-CODE indicates that the UPDATE was rejected because it
would result in multiple RRs of a type that permits only a
single RR per owner name.  Per {{RFC2136}} Section 1.1.5, SOA and
CNAME are singleton types that cannot have multiple RRs at the
same owner name.

## INFO-CODE 7: RRset TTL Mismatch

This INFO-CODE indicates that the UPDATE was rejected because it
would add an RR to an existing RRset with a different TTL value.
Per {{RFC2181}} Section 5.2, all RRs in an RRset must have the
same TTL.

The EXTRA-TEXT field MAY indicate the expected TTL value.

Servers MAY choose to automatically adjust TTL values rather than
reject the UPDATE, in which case this code would not be used.

## INFO-CODE 8: Delegation Hierarchy Violation

This INFO-CODE indicates that the UPDATE was rejected because it
would violate the delegation hierarchy.  Examples include:

* Adding inappropriate RR types at a delegation point
* Creating a delegation that conflicts with existing data
* Modifying RRs in a way that breaks the delegation relationship

## INFO-CODE 9: Update Policy Violation

This INFO-CODE indicates that the UPDATE was rejected due to
server-configured update policies, distinct from authentication
failures.  The UPDATE was properly authenticated but the
specific change requested is not permitted by policy.

For example, BIND distinguishes between `allow-update` and
`update-policy` configurations.  A zone configured with only
`allow-update` will refuse modifications to apex NS RRs even
when the client is properly authenticated.  Modifying apex
NS RRs requires an explicit `update-policy` grant.  In this
case, the client's credentials are valid, but the specific
operation is not permitted.

The EXTRA-TEXT field MAY provide additional context about the
policy restriction, such as "apex NS modification requires
update-policy".

## INFO-CODE 10: RRset Size Limit Exceeded

This INFO-CODE indicates that the UPDATE was rejected because
accepting it would cause an RRset to exceed the server's
configured limit on the number of RRs per RRset.

Some DNS server implementations impose limits on RRset sizes
to prevent performance degradation or as a security measure.
For example, BIND 9.18.28 and later versions limit RRsets to
100 records per type by default (configurable via
`max-records-per-type`).

The EXTRA-TEXT field MAY indicate the configured limit, such
as "max 100 records per type".

# Implementation Considerations

## Server Implementation

Servers implementing the EUE option SHOULD:

1. Include the EUE option only in responses to UPDATE requests
   that contained an OPT pseudo-RR.

2. Use the most specific applicable INFO-CODE when multiple
   codes might apply.

3. Set the SECTION and RR-INDEX fields to accurately identify
   the RR that caused the failure.

4. Populate the EXTRA-TEXT field with useful diagnostic
   information when practical, while being mindful of
   information disclosure concerns.

5. Continue to set appropriate RCODEs as specified in
   {{RFC2136}}; the EUE option provides supplementary
   information and does not replace RCODEs.

6. When returning EUE options, include the Prerequisite and Update
   sections in the response (rather than zeroing the PRCOUNT and
   UPCOUNT fields).  This allows clients to correlate RR-INDEX
   values with the actual RRs that caused failures.  Per {{RFC2136}}
   Section 3.8, servers may choose to echo these sections or omit
   them; however, omitting them reduces the utility of the EUE
   option's RR identification fields.

## Client Implementation

Clients receiving the EUE option SHOULD:

1. Use the SECTION and RR-INDEX fields to identify which
   specific RR in the UPDATE request caused the failure.

2. Use the INFO-CODE and EXTRA-TEXT to provide meaningful
   error messages to users or take corrective action where
   possible.

3. Not assume that all servers will implement this option;
   fall back to RCODE-based error handling when the EUE
   option is not present.

4. Log EUE information for debugging purposes.

## Multiple EUE Options

A DNS message MAY contain more than one EUE option.  Receivers
MUST be able to accept multiple EUE options in a DNS message.

A DNS UPDATE may fail for multiple reasons simultaneously.
For example, an UPDATE might attempt to add a CNAME at an
owner name where other data exists (INFO-CODE 2) while also
specifying an inconsistent TTL (INFO-CODE 7).  In such cases,
servers MAY include multiple EUE options in the response, one
for each detected failure reason.  Each option will have its
own SECTION and RR-INDEX fields identifying the specific RR
that caused that particular failure.

{{RFC2136}} Section 3.2 implies early return on prerequisite
failures, using the pattern "test X, else signal [error code]"
throughout, and the accompanying pseudocode shows immediate
return upon detecting the first failure.  However, {{RFC2136}}
does not explicitly prohibit servers from evaluating all
prerequisites and update constraints before returning a response.
Servers that wish to provide comprehensive error information MAY
choose to check all constraints and return multiple EUE options
identifying each failure.  Clients MUST NOT assume that a server
will return all applicable error codes; the absence of a particular
INFO-CODE does not guarantee that the corresponding constraint
was satisfied.

When a server does return multiple EUE options, no ordering
or priority is implied.  Clients needing to address multiple
issues should attempt to resolve all reported problems before
resubmitting the UPDATE.

# Security Considerations

The EUE option provides diagnostic information that is not
authenticated unless the DNS message is protected by a
mechanism such as TSIG {{RFC3007}} or DNS over TLS/HTTPS.
Clients MUST NOT rely on EUE information for security decisions.

The SECTION and RR-INDEX fields reveal which part of an UPDATE
request failed.  While this is useful for legitimate debugging,
it could potentially be used by an attacker to probe zone
configuration by observing which types of updates are rejected.

The EXTRA-TEXT field may reveal information about zone
configuration or server policy.  Server operators should
consider what information is appropriate to disclose.  For
example, revealing specific policy rules might help attackers
craft UPDATE requests that avoid detection.

Automated systems should be cautious about acting on EUE
information without human review, particularly for security-
sensitive zones.

An attacker who can modify DNS responses in transit could
insert or modify EUE options to mislead clients about the
reason for failure.  This is no different from existing
RCODE manipulation risks, but operators should be aware that
EUE data is subject to the same integrity concerns as other
unsigned DNS data.

Generating EUE options adds computational overhead to UPDATE
processing, particularly if a server chooses to evaluate all
constraints rather than returning on the first failure.  This
overhead could be exploited in denial-of-service attacks against
servers that accept UPDATE requests from untrusted or semi-trusted
clients.  For example, BIND's "allow-update" feature permits
IP-based access control for dynamic DNS registration, which may
expose servers to UPDATE requests from clients that are not fully
trusted.  Server implementations SHOULD make EUE generation
configurable, allowing operators to disable the option entirely
or limit its use (such as omitting EXTRA-TEXT or returning only
a single EUE option) for UPDATE requests from sources that are
not fully trusted.

# IANA Considerations {#iana}

## New EDNS Option Code

This document requests IANA to assign a new option code in the
"DNS EDNS0 Option Codes (OPT)" registry:

| Value | Name | Status | Reference |
|-------|------|--------|-----------|
| TBD | Extended UPDATE Error | Standard | This document |

## New Registry: Extended UPDATE Error Codes

This document requests IANA to create a new registry called
"Extended UPDATE Error Codes" within the "Domain Name System (DNS)
Parameters" registry group.

The registration policy for this registry is "First Come First
Served" for values 0-49151, and "Private Use" for values
49152-65535, following the same model as the "Extended DNS Error
Codes" registry {{RFC8914}}.

The initial contents of this registry are:

| INFO-CODE | Purpose | Reference |
|-----------|---------|-----------|
| 0 | Other Error | This document |
| 1 | CNAME RR Exists at Owner Name | This document |
| 2 | Other Data Exists at CNAME Owner Name | This document |
| 3 | DNAME RR Conflict | This document |
| 4 | Missing Glue | This document |
| 5 | Zone Apex Constraint | This document |
| 6 | Singleton Type Conflict | This document |
| 7 | RRset TTL Mismatch | This document |
| 8 | Delegation Hierarchy Violation | This document |
| 9 | Update Policy Violation | This document |
| 10 | RRset Size Limit Exceeded | This document |
| 11-49151 | Unassigned | |
| 49152-65535 | Reserved for Private Use | This document |

--- back

# Acknowledgments
{:numbered="false"}

The author would like to thank the developers of BIND, Knot DNS,
PowerDNS, and other DNS implementations whose error handling
informed the error codes proposed in this document.

# Examples
{:numbered="false"}

## CNAME Conflict Example
{:numbered="false"}

A client sends an UPDATE to add an A RR at "www.example.com"
where a CNAME RR already exists:

~~~
;; UPDATE SECTION (index 0):
www.example.com.  300  IN  A  192.0.2.1
~~~

The server responds with:

~~~
;; HEADER: REFUSED
;; OPT PSEUDO-RR:
;;   Extended UPDATE Error Option:
;;     INFO-CODE: 1 (CNAME RR Exists at Owner Name)
;;     SECTION: 1 (Update section)
;;     RR-INDEX: 0
;;     EXTRA-TEXT: "CNAME exists"
~~~

## Missing Glue Example
{:numbered="false"}

A client sends an UPDATE to add a delegation without glue:

~~~
;; UPDATE SECTION (index 0):
sub.example.com.  86400  IN  NS  ns1.sub.example.com.
~~~

The server responds with:

~~~
;; HEADER: REFUSED
;; OPT PSEUDO-RR:
;;   Extended UPDATE Error Option:
;;     INFO-CODE: 4 (Missing Glue)
;;     SECTION: 1 (Update section)
;;     RR-INDEX: 0
;;     EXTRA-TEXT: "no A/AAAA for ns1.sub.example.com"
~~~

## Zone Apex Constraint Example
{:numbered="false"}

A client attempts to delete the SOA RR:

~~~
;; UPDATE SECTION (index 0):
example.com.  0  ANY  SOA
~~~

The server responds with:

~~~
;; HEADER: REFUSED
;; OPT PSEUDO-RR:
;;   Extended UPDATE Error Option:
;;     INFO-CODE: 5 (Zone Apex Constraint)
;;     SECTION: 1 (Update section)
;;     RR-INDEX: 0
;;     EXTRA-TEXT: "cannot delete SOA"
~~~

## Update Policy Violation Example
{:numbered="false"}

A client with valid TSIG credentials attempts to add an NS RR at
the zone apex on a BIND server configured with `allow-update`
(but not `update-policy`):

~~~
;; UPDATE SECTION (index 0):
example.com.  86400  IN  NS  ns3.example.com.
~~~

The server responds with:

~~~
;; HEADER: REFUSED
;; OPT PSEUDO-RR:
;;   Extended UPDATE Error Option:
;;     INFO-CODE: 9 (Update Policy Violation)
;;     SECTION: 1 (Update section)
;;     RR-INDEX: 0
;;     EXTRA-TEXT: "apex NS modification requires update-policy"
~~~

## Multiple EUE Options Example
{:numbered="false"}

A client sends an UPDATE that violates multiple constraints:

~~~
;; UPDATE SECTION:
;;   index 0: www.example.com.   300  IN  CNAME  target.example.com.
;;   index 1: www.example.com.  3600  IN  A      192.0.2.1
~~~

This UPDATE attempts to add both a CNAME and an A RR at the same
owner name, which violates the CNAME exclusivity rule.  Additionally,
the TTL values differ (300 vs 3600).

A server that checks multiple constraints MAY respond with multiple
EUE options:

~~~
;; HEADER: REFUSED
;; OPT PSEUDO-RR:
;;   Extended UPDATE Error Option:
;;     INFO-CODE: 1 (CNAME RR Exists at Owner Name)
;;     SECTION: 1 (Update section)
;;     RR-INDEX: 0
;;     EXTRA-TEXT: "CNAME conflicts with A"
;;   Extended UPDATE Error Option:
;;     INFO-CODE: 7 (RRset TTL Mismatch)
;;     SECTION: 1 (Update section)
;;     RR-INDEX: 1
;;     EXTRA-TEXT: "TTL 300 != 3600"
~~~
