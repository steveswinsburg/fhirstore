# FHIR Implementation Guide Configuration

This directory contains local FHIR IG package files (.tgz) and configuration examples.

## Local Package Files

Place your local FHIR IG package files (.tgz) in this directory:
- `my-custom-ig-1.0.0.tgz` - Custom implementation guide

The `/app/igs/` path maps to this directory when running in Docker.

## Configuration Examples

Add this section to `conf/hapi.application.yaml` under the `hapi:` section:

```yaml
implementationguides:
  # US Core IG from NPM registry
  us-core:
    name: hl7.fhir.us.core
    version: 6.1.0
    installMode: STORE_AND_INSTALL
  
  # AU Base IG
  au-base:
    name: hl7.fhir.au.base
    version: 6.0.0
    installMode: STORE_AND_INSTALL
  
  # AU Core IG  
  au-core:
    name: hl7.fhir.au.core
    version: 2.0.0-ballot
    installMode: STORE_AND_INSTALL
  
  # HL7 FHIR UV Extensions
  hl7-fhir-uv-extensions:
    name: hl7.fhir.uv.extensions.r4
    version: 5.2.0
    installMode: STORE_AND_INSTALL
  
  # HL7 Terminologies
  hl7-terminologies:
    name: hl7.terminology.r4
    version: 7.0.0
    installMode: STORE_AND_INSTALL
  
  # ADHA Health Connect
  health-connect:
    name: au.digitalhealth.r4.healthconnect
    version: 0.2.0-preview
    packageUrl: file:///app/igs/health-connect-0.2.0-preview.tgz
    installMode: STORE_AND_INSTALL
    reloadExisting: true
  
  # Custom IG from URL (example)
  # my-custom-ig:
  #   name: my.custom.ig
  #   version: 1.0.0
  #   packageUrl: https://example.org/package.tgz
  #   installMode: STORE_AND_INSTALL
  #   reloadExisting: false
```

## Configuration Options

### installMode Options
- `STORE_AND_INSTALL`: Download, store, and install the IG
- `STORE_ONLY`: Download and store but don't install
- `INSTALL_ONLY`: Install previously stored IG

### Other Options
- `reloadExisting`: true/false - Reload if already installed
- `packageUrl`: Direct URL to package file (overrides NPM registry)

## Usage
1. Copy the relevant sections above to `conf/hapi.application.yaml`
2. Uncomment and modify as needed
3. Restart the FHIR server: `docker compose restart fhir`