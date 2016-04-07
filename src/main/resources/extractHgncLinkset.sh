#!/bin/sh
# <> pav:createdBy <http://orcid.org/0000-0002-5711-4872> .
# <> pav:contributedBy <https://github.com/andrawaag/> .
# <> pav:contributedBy <http://orcid.org/0000-0001-9842-9718> .

## https://raw.githubusercontent.com/openphacts/ops-platform-setup/master/scripts/hgnc/extractHgncLinkset.sh

# Bail out on first error
set -e

# Make files world-writable - as we're running as root within the
# docker image
umask 000

BASE_URI="<>"

# target is mounted as /target within Docker image
TARGET=/target/classes
DATA=$TARGET/data
mkdir -p $DATA

HGNC_VOID_FILE=void.ttl # relative path
INPUT_VOID_FILE=$TARGET/void.ttl.template
OUTPUT_VOID_FILE=$DATA/void.ttl
OUTPUT_LINKSET_FILE=$DATA/hgnc-to-hgnc.symbol-linkset.ttl
SCRIPT_RUNTIME="\""$(date +"%Y-%m-%dT%T%:z")"\"^^xsd:dateTime"


test -f $INPUT_VOID_FILE || exit 1

write_void() {
    # cat, not cp, so that umask takes effect
    cat $INPUT_VOID_FILE > $OUTPUT_VOID_FILE
    echo "<> pav:lastUpdateOn $SCRIPT_RUNTIME ." >> $OUTPUT_VOID_FILE
    echo ":hgncDataset dct:issued $SCRIPT_RUNTIME ." >> $OUTPUT_VOID_FILE
    echo ":hgncId-SymbolLinkset dct:issued $SCRIPT_RUNTIME ." >> $OUTPUT_VOID_FILE
    echo "" >> $OUTPUT_VOID_FILE

}

extract_links() {
    echo "@prefix skos: <http://www.w3.org/2004/02/skos/core#> ." > $OUTPUT_LINKSET_FILE
    echo "@prefix void: <http://rdfs.org/ns/void#> ." >> $OUTPUT_LINKSET_FILE
    echo "@prefix hgnc: <$HGNC_VOID_FILE#> ." >> $OUTPUT_LINKSET_FILE
    echo "$BASE_URI void:inDataset hgnc:hgncId-SymbolLinkset ." >> $OUTPUT_LINKSET_FILE
    curl -s -L "http://www.genenames.org/cgi-bin/download?col=gd_hgnc_id&amp;col=gd_app_sym&amp;status=Approved&amp;status_opt=2&amp;where=&amp;order_by=gd_hgnc_id&amp;format=text&amp;limit=&amp;hgnc_dbtag=on&amp;submit=submit" | \
	   grep ^HGNC: |sed s/^HGNC:// | \
	   awk '{print "<http://identifiers.org/hgnc/"$1 "> skos:exactMatch <http://identifiers.org/hgnc.symbol/"$2"> ." '} >> $OUTPUT_LINKSET_FILE
    triples=`grep skos:exactMatch $OUTPUT_LINKSET_FILE | wc -l`
    echo ":hgncId-SymbolLinkset void:triples $triples ." >> $OUTPUT_VOID_FILE
    echo "" >> $OUTPUT_VOID_FILE
}


write_void
extract_links
echo
echo "DONE"
echo
