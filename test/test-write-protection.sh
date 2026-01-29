#!/bin/bash

# Test script to demonstrate write protection functionality

# Requirements:
# - FHIR Store service must be running locally on http://localhost/fhir
# - curl must be installed


BASE_URL="http://localhost:8080/fhir"
ADMIN_USER="admin"
ADMIN_PASS="admin123"

# Arrays to store test results
declare -a TEST_NAMES
declare -a ACTUAL_RESULTS
declare -a EXPECTED_RESULTS

echo "=== FHIR Store Write Protection Test ==="
echo ""

# First, try to create a test patient without auth (should fail)
echo "1. Creating a test patient without auth (CREATE - should fail)..."
PATIENT_JSON='{
  "resourceType": "Patient",
  "name": [{
    "family": "Doe",
    "given": ["John"]
  }],
  "gender": "male",
  "birthDate": "1990-01-01"
}'

RESULT1=$(curl -s -X POST \
  -H "Content-Type: application/fhir+json" \
  -d "$PATIENT_JSON" \
  "$BASE_URL/Patient" \
  -w "%{http_code}" \
  -o /dev/null)

echo "HTTP Status: $RESULT1"
TEST_NAMES+=("CREATE without auth")
ACTUAL_RESULTS+=("$RESULT1")
EXPECTED_RESULTS+=("403")

echo ""

# Now create a test patient with auth (should work)
echo "2. Creating a test patient with auth (CREATE - should work)..."
RESULT2=$(curl -s -X POST \
  -H "Content-Type: application/fhir+json" \
  -H "Authorization: Basic $(echo -n $ADMIN_USER:$ADMIN_PASS | base64)" \
  -d "$PATIENT_JSON" \
  "$BASE_URL/Patient" \
  -w "%{http_code}" \
  -o /tmp/patient_response.json)

echo "HTTP Status: $RESULT2"
TEST_NAMES+=("CREATE with auth")
ACTUAL_RESULTS+=("$RESULT2")
EXPECTED_RESULTS+=("200/201")

if [[ "$RESULT2" == "200" || "$RESULT2" == "201" ]]; then
    LOCATION_HEADER=$(curl -s -X POST \
      -H "Content-Type: application/fhir+json" \
      -H "Authorization: Basic $(echo -n $ADMIN_USER:$ADMIN_PASS | base64)" \
      -d "$PATIENT_JSON" \
      "$BASE_URL/Patient" \
      -D - -o /dev/null | grep -i "location:" | cut -d' ' -f2 | tr -d '\r')
    PATIENT_ID=$(basename "$LOCATION_HEADER")
    echo "   Patient ID: $PATIENT_ID"
else
    echo "Failed to create patient with auth (Status: $RESULT2)"
    exit 1
fi

echo ""

# Try to update without auth (should fail)
echo "3. Trying to update patient without authentication (should fail)..."
UPDATE_JSON='{
  "resourceType": "Patient",
  "id": "'$PATIENT_ID'",
  "name": [{
    "family": "Smith",
    "given": ["John"]
  }],
  "gender": "male",
  "birthDate": "1990-01-01"
}'

RESULT3=$(curl -s -X PUT \
  -H "Content-Type: application/fhir+json" \
  -d "$UPDATE_JSON" \
  "$BASE_URL/Patient/$PATIENT_ID" \
  -w "%{http_code}" \
  -o /dev/null)

echo "HTTP Status: $RESULT3"
TEST_NAMES+=("UPDATE without auth")
ACTUAL_RESULTS+=("$RESULT3")
EXPECTED_RESULTS+=("403")

echo ""

# Try to update with auth (should work)
echo "4. Trying to update patient with authentication (should work)..."
RESULT4=$(curl -s -X PUT \
  -H "Content-Type: application/fhir+json" \
  -H "Authorization: Basic $(echo -n $ADMIN_USER:$ADMIN_PASS | base64)" \
  -d "$UPDATE_JSON" \
  "$BASE_URL/Patient/$PATIENT_ID" \
  -w "%{http_code}" \
  -o /dev/null)

echo "HTTP Status: $RESULT4"
TEST_NAMES+=("UPDATE with auth")
ACTUAL_RESULTS+=("$RESULT4")
EXPECTED_RESULTS+=("200")

echo ""

# Try to delete without auth (should fail)
echo "5. Trying to delete patient without authentication (should fail)..."
RESULT5=$(curl -s -X DELETE \
  "$BASE_URL/Patient/$PATIENT_ID" \
  -w "%{http_code}" \
  -o /dev/null)

echo "HTTP Status: $RESULT5"
TEST_NAMES+=("DELETE without auth")
ACTUAL_RESULTS+=("$RESULT5")
EXPECTED_RESULTS+=("403")

echo ""

# Try to delete with auth (should work)
echo "6. Trying to delete patient with authentication (should work)..."
RESULT6=$(curl -s -X DELETE \
  -H "Authorization: Basic $(echo -n $ADMIN_USER:$ADMIN_PASS | base64)" \
  "$BASE_URL/Patient/$PATIENT_ID" \
  -w "%{http_code}" \
  -o /dev/null)

echo "HTTP Status: $RESULT6"
TEST_NAMES+=("DELETE with auth")
ACTUAL_RESULTS+=("$RESULT6")
EXPECTED_RESULTS+=("200/204")

echo ""
echo "=== Test Complete ==="
echo ""
echo "RESULTS SUMMARY:"
echo "===================="
printf "%-20s %-10s %-10s %-6s\n" "TEST" "EXPECTED" "ACTUAL" "RESULT"
printf "%-20s %-10s %-10s %-6s\n" "----" "--------" "------" "------"

for i in "${!TEST_NAMES[@]}"; do
    expected="${EXPECTED_RESULTS[$i]}"
    actual="${ACTUAL_RESULTS[$i]}"
    
    # Check if result matches expected (handle multiple expected values like 200/201)
    if [[ "$expected" == *"/"* ]]; then
        # Multiple acceptable values
        if [[ "$expected" == *"$actual"* ]]; then
            status="PASS"
        else
            status="FAIL"
        fi
    else
        # Single expected value
        if [[ "$actual" == "$expected" ]]; then
            status="PASS"
        else
            status="FAIL"
        fi
    fi
    
    printf "%-20s %-10s %-10s %-6s\n" "${TEST_NAMES[$i]}" "$expected" "$actual" "$status"
done