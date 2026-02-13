# Required / Recommended Changes to `certificate_authority` Gem

This document records findings from a thorough audit of the `certificate_authority` gem
source against the PKI implementation plan. **No changes are required for the initial implementation.** Every issue listed below is either
trivially worked around in our own code, or only becomes relevant in a later phase (full CRL
population). Changes are split into **required-when** (blocking a specific future phase) and
**recommended** (nice to have, can be deferred indefinitely).

The gem lives at `/Users/kazwolfe/Developer/FFXIV/XIVAuthProjects/certificate_authority`.
It is a local path dependency — changes can be made directly and tested immediately.

---

## Required When: Full CRL Population Is Implemented

### 1. CRL Reason Codes Not Written to Entries

**File:** `lib/certificate_authority/certificate_revocation_list.rb`

**Problem:** `sign!` creates `OpenSSL::X509::Revoked` objects and sets only `serial` and
`time`. No `reasonCode` extension is added to each entry. The reason code is permanently lost.

**Current behaviour:**
```ruby
revocation = OpenSSL::X509::Revoked.new
revocation.serial = revocable.number
revocation.time   = revocable.revoked_at
# reasonCode extension: never set
```

**Required fix:** After setting `serial` and `time`, add a `reasonCode` extension to the
`OpenSSL::X509::Revoked` object. This requires the caller to be able to communicate the
reason code to the CRL builder. The cleanest approach is to add a `reason` attribute to
`CertificateAuthority::SerialNumber` (via the `Revocable` module or directly) so callers
can set it:

```ruby
# In Revocable or SerialNumber:
attr_accessor :revocation_reason  # integer, one of OpenSSL::OCSP::REVOKED_STATUS_* or 0

# In CertificateRevocationList#sign!, after setting time:
if revocable.respond_to?(:revocation_reason) && revocable.revocation_reason
  reason_ext = OpenSSL::X509::Extension.new(
    "reasonCode",
    OpenSSL::ASN1::Enumerated(revocable.revocation_reason)
  )
  revocation.extensions = [reason_ext]
end
```

**Impact if deferred:** CRLs are stubbed (empty) in the initial implementation. This only
becomes a blocker when full CRL population is implemented. The `reason` data is preserved
in the `pki_issued_certificates` table regardless.

---

## Required When: Accurate Revocation Timestamps Are Needed

### 2. OCSP Revocation Timestamp Hardcoded to "Now"

**File:** `lib/certificate_authority/ocsp_handler.rb`

**Problem:** `build_response` passes `0` as `rev_time` to `OpenSSL::OCSP::BasicResponse#add_status`:

```ruby
@ocsp_response.add_status(cert_id, result, reason, 0, 0, @next_update, nil)
#                                                    ^
#                                           rev_time hardcoded to 0 (= now)
```

When `status == REVOKED`, the OCSP response tells clients "this cert was revoked just now",
regardless of when revocation actually occurred. This violates RFC 6960 §4.2.1 ("The
`revocationTime` field indicates when the certificate was revoked or placed on hold") and
can confuse clients that use the revocation time to determine whether a transaction
predates revocation.

**Required fix:** Allow the `verification_mechanism` lambda to return a 3-element tuple
`[status, reason, rev_time]` where `rev_time` is a `Time` object (or `nil` for non-revoked
certs), and use it in `add_status`. Maintain backward compatibility by accepting a 2-element
return and defaulting `rev_time` to `nil`:

```ruby
result_tuple = verification_mechanism.call(cert_id.serial)
result, reason, rev_time = result_tuple
rev_time_val = (result == REVOKED && rev_time) ? rev_time : 0

@ocsp_response.add_status(cert_id, result, reason, rev_time_val, 0, @next_update, nil)
```

Our `verification_mechanism` lambda would then return:
```ruby
elsif cert.revoked?
  [CertificateAuthority::OCSPResponseBuilder::REVOKED,
   CertificateAuthority::OCSPResponseBuilder::UNSPECIFIED,
   cert.revoked_at]
```

**Impact if deferred:** OCSP responses for revoked certs always report revocation time as
"now". Practically, most clients don't act on revocation time from OCSP — they only care
about the status. Defer until after initial implementation.

---

## Recommended Changes

### 3. Add `UNKNOWN` Status Constant

**File:** `lib/certificate_authority/ocsp_handler.rb`

**Problem:** The gem defines `GOOD` and `REVOKED` but not `UNKNOWN`:

```ruby
GOOD    = OpenSSL::OCSP::V_CERTSTATUS_GOOD
REVOKED = OpenSSL::OCSP::V_CERTSTATUS_REVOKED
# UNKNOWN is missing
```

RFC 6960 defines three certificate statuses: good, revoked, and unknown. Our responder uses
`OpenSSL::OCSP::V_CERTSTATUS_UNKNOWN` (value `2`) directly, which works but is inconsistent.

**Fix:**
```ruby
UNKNOWN = OpenSSL::OCSP::V_CERTSTATUS_UNKNOWN
```

---

### 4. `MemoryKeyMaterial#generate_key` Is RSA-Only

**File:** `lib/certificate_authority/key_material.rb`

**Problem:** `generate_key(modulus_bits)` always calls `OpenSSL::PKey::RSA.new(modulus_bits)`.
EC key generation is not supported.

**Note:** Manually assigning an EC `OpenSSL::PKey` to `key_material.private_key` works
correctly for signing — the limitation is only in `generate_key`. Since XIVAuth generates
CA keys externally (rake task / offline tooling), this is not a practical blocker.

**Fix (optional):** Accept a `type:` keyword argument:
```ruby
def generate_key(size = 2048, type: :rsa)
  case type
  when :rsa then @private_key = OpenSSL::PKey::RSA.new(size)
  when :ec  then @private_key = OpenSSL::PKey::EC.generate(size.is_a?(Integer) ? "prime256v1" : size)
  else raise ArgumentError, "Unsupported key type: #{type}"
  end
end
```

---

### 5. CRL Entries Lack `crlNumber` and `authorityKeyIdentifier` Extensions

**File:** `lib/certificate_authority/certificate_revocation_list.rb`

**Problem:** The generated CRL has no extensions at all — no `crlNumber`, no
`authorityKeyIdentifier`, no `issuingDistributionPoint`. RFC 5280 §5.2 says `crlNumber`
SHOULD be present, and many CRL-consuming clients expect it. `authorityKeyIdentifier`
is RECOMMENDED.

**Fix:** Add these in `sign!` after creating the CRL:
```ruby
# crlNumber — increment per-CA, or use the current epoch second as a simple monotonic value
crl.add_extension(OpenSSL::X509::Extension.new("crlNumber", OpenSSL::ASN1::Integer(sequence_number)))

# authorityKeyIdentifier — derive from the issuing CA's subject key
aki = OpenSSL::X509::Extension.new("authorityKeyIdentifier", "keyid:always")
# (requires setting the issuer cert on the OpenSSL::X509::CRL object first)
```

This is deferred for the initial stubbed CRL implementation.

---

## Summary Table

| # | Change                              | Workaround                                     | Needed for initial impl?  |
|---|-------------------------------------|------------------------------------------------|---------------------------|
| 1 | CRL reason codes in entries         | Use `OpenSSL::X509::CRL` directly              | No — CRL is stubbed empty |
| 2 | OCSP revocation timestamp           | Clients generally ignore it                    | No                        |
| 3 | Add `UNKNOWN` constant              | `OpenSSL::OCSP::V_CERTSTATUS_UNKNOWN` directly | No                        |
| 4 | EC key generation in `generate_key` | Assign `private_key =` manually                | No                        |
| 5 | CRL `crlNumber` / AKI extensions    | N/A until full CRL                             | No — CRL is stubbed empty |
