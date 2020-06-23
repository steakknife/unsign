#!/bin/sh
# Run tests: ./run-test.sh <unsign> <test-file> <test-dir>
#    unsign: Unsign binary
#    test-file: A signed binary to use as the test input
#    test-dir: Directory to use for test artefacts
set -e
set -u

program_name="$(basename "$0")"

usage()
{
  exit_code=0
  if [ $# -ge 1 ]; then
    echo "${program_name}: $@" >&2
    exit_code=1
  else
    echo "${program_name}: Test unsign"
  fi
  cat <<EOF
Usage: ${program_name} [-xh] <unsign> <testbin> <testdir>

-x: Trace output
-h: Display usage
<unsign>: Unsign binary to test
<testbin>: A signed binary to use in test
<testdir>: Directory to store test artefacts in
EOF

  exit "${exit_code}"
}

while [ $# -ge 1 ]; do
  case "$1" in
    -x)
      set -x
      ;;
    -h | --help)
      usage
      ;;
    --)
      shift
      break
      ;;
    -*)
      usage "Unrecognised command line option - $1"
      ;;
    *)
      break
      ;;
  esac

  shift

done

if [ $# -ne 3 ]; then
  usage "Incorrect number of operands provided"
fi

unsign="$1"
source_signed_binary="$2"
test_dir="$3"

signed_binary="${test_dir}/$(basename "$2")"

unsigned_binary="${signed_binary}.unsigned"
temp1_binary="${signed_binary}.temp1"
temp2_binary="${signed_binary}.temp2"
signed_hd="${signed_binary}.hd"
unsigned_hd="${unsigned_binary}.hd"

# Setup
mkdir -p "${test_dir}"
rm -f "${signed_binary}" "${unsigned_binary}" "${temp1_binary}" \
  "${temp2_binary}" "${signed_hd}" "${unsigned_hd}"
cp "${source_signed_binary}" "${signed_binary}"

# We do three unsigns:
# 1 - Using default output name
"${unsign}" "${signed_binary}"
# 2 - Using a specified output
"${unsign}" "${signed_binary}" "${temp1_binary}"
# 3 - Unsign an already unsigned binary.
"${unsign}" "${temp1_binary}" "${temp2_binary}"

# All unsigned binaries should be identical in contents
cmp "${unsigned_binary}" "${temp1_binary}"
cmp "${temp1_binary}" "${temp2_binary}"

# The signed binary and unsigned binary should be the same size
signed_size="$(cat "${signed_binary}" | wc -c)"
unsigned_size="$(cat "${unsigned_binary}" | wc -c)"
if [ "${signed_size}" -ne "${unsigned_size}" ] ; then
  echo "Signed binary is not same size (${signed_size}) as unsigned binary" \
    "(${unsigned_size})" 2>&1
  exit 1
fi

# Any changed bytes (past the header) should have only been changed to NULs
# Use hexdump to dump the files into a form we can test with grep
hexdump -v -s 24 -e '1/1 "%02x " "\n"' "${signed_binary}" > "${signed_hd}"
hexdump -v -s 24 -e '1/1 "%02x " "\n"' "${unsigned_binary}" > "${unsigned_hd}"
# The grep matches any line that does not start with a >, or a line that is
# exactly "> 00".  -v inverts the exit code, so it fails if it finds a line
# that doesn't match.
diff "${signed_hd}" "${unsigned_hd}" | grep -q -v -e "^[^>]" -e "^>\\s00$"

# Check the signed binary is signed, and the unsigned is unsigned
LC_ALL="C" LANG="C" codesign -vvvvvv "${signed_binary}" 2>&1 | \
  grep -q "valid on disk"
LC_ALL="C" LANG="C" codesign -vvvvvv "${signed_binary}" 2>&1 | \
  grep -q "satisfies its Designated Requirement"

LC_ALL="C" LANG="C" codesign -vvvvvv "${unsigned_binary}" 2>&1 | \
  grep -q "code object is not signed at all"

echo "All tests completed successfully."
