IDML2XML_MAKEFILEDIR = $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ifeq ($(shell uname -o),Cygwin)
win_path = $(shell cygpath -ma "$(1)")
uri = $(shell echo file:///$(call win_path,$(1))  | perl -pe 's/ /%20/g')
else
uri = $(shell echo file://$(abspath $(1))  | perl -pe 's/ /%20/g')
endif

SAXON := saxon
DEBUG := 1
DEBUGDIR = "$<.tmp/debug"
SRCPATHS = no
HUBVERSION = 1.0
ALLSTYLES = no
# Whether to discard existing piggyback tagging:  
DISCARD=yes

# For the XProc pipelines to run standalone:
DEPS = https://subversion.le-tex.de/common/xproc-util/xslt-mode \
	https://subversion.le-tex.de/common/xproc-util/xml-model \
	https://subversion.le-tex.de/common/xproc-util/store-debug \
  https://subversion.le-tex.de/common/calabash \
	https://subversion.le-tex.de/common/schema/xhtml1

default: idml2xml_usage

%.hub.xml %.indexterms.xml %.tagged.xml %.images.xml:	%.idml $(IDML2XML_MAKEFILEDIR)/Makefile $(wildcard $(IDML2XML_MAKEFILEDIR)/xslt/*.xsl) $(wildcard $(IDML2XML_MAKEFILEDIR)/xslt/modes/*.xsl)
	umask 002; mkdir -p "$<.tmp" && unzip -u -o -q -d "$<.tmp" "$<"
	umask 002; $(SAXON) \
      $(SAXONOPTS) \
      -xsl:$(call uri,$(IDML2XML_MAKEFILEDIR)/xslt/idml2xml.xsl) \
      -it:$(subst .,,$(suffix $(basename $@))) \
      hub-other-elementnames-whitelist=$(HUB-OTHER-ELNAMES-WHITELIST) \
      archive-dir-uri=$(call uri,$(dir $(abspath $<))) \
      src-dir-uri=$(call uri,$(abspath $<)).tmp \
      split=$(SPLIT) \
      discard-tagging=$(DISCARD) \
      hub-version=$(HUBVERSION) \
      all-styles=$(ALLSTYLES) \
      srcpaths=$(SRCPATHS) \
      debug=$(DEBUG) \
      debugdir=$(call uri,$(DEBUGDIR)) \
      2> "$@".idml2hub.log \
      > "$@"
ifeq ($(DEBUG),0)
	-@rm -rf $(DEBUGDIR) && rm -rf "$<.tmp"
else
	@cat "$@".idml2hub.log
endif

fetchdeps:
	rm -r $(notdir $(DEPS)) || for dep in $(DEPS); do svn co $$dep; done

rmdeps:
	rm -r $(notdir $(DEPS))

updeps:
	for dep in $(notdir $(DEPS)); do svn up $$dep; done

idml2xml_usage:
	@echo ""
	@echo "This is idml2xml, an IDML to XML converter"
	@echo "written by Philipp Glatza and Gerrit Imsieke"
	@echo "(C) 2010--2012 le-tex publishing services GmbH"
	@echo "All rights reserved"
	@echo ""
	@echo "Usage:"
	@echo "  Place a file xyz.idml anywhere, then run 'make -f $(IDML2XML_MAKEFILEDIR)/Makefile path/to/xyz.targetfmt.xml',"
	@echo "    where targetfmt is one of tagged, hub, indexterms or images. Use make's -C option (instead of the -f option)"
	@echo "    only if the file name contains an absolute directory."
	@echo "  Optional parameter SPLIT for the .tagged.xml target: comma-separated list of tags that"
	@echo "    should be split if they cross actual InDesign paragraph boundaries (e.g., SPLIT=span,p)."
	@echo "  Optional parameter DEBUG=1 (which is default) will cause debugging info to be dumped"
	@echo "    into DEBUGDIR (which is path/to/xyz.idml.tmp/debug by default)."
	@echo "    Use DEBUG=0 to switch off debugging."
	@echo "  Optional parameter HUBVERSION=1.0|1.1 (default: $(HUBVERSION)) will create XML"
	@echo "    according to the specified version number."
	@echo "  Example for processing 37 chapters from bash:"
	@echo '  > for c in $$(seq -f '%02g' 37); do make -f $(IDML2XML_MAKEFILEDIR)/Makefile path/to/IDML/$${c}_Chap.hub.xml; done'
	@echo "  Another example:"
	@echo '  > for f in somedir/*idml; do make $$(dirname $$f)/$$(basename $$f idml)indexterms.xml; done'
	@echo ""
	@echo "XProc invocation example:"
	@echo '  calabash/calabash.sh xpl/idml2hub.xpl idmlfile=$(cygpath -ma sample/testdokument.idml) debug=yes'
	@echo "  (do 'make fetchdeps' first, once)"
	@echo ""
	@echo "Prerequisites:"
	@echo "  Saxon 9.3 or newer, expected as a 'saxon' script in the path (override this with SAXON=...)"
	@echo ""
	@echo "Other targets: fetchdeps, updeps, rmdeps"
	@echo "  For fetching, updating, and deleting XProc dependencies, including calabash/calabash.sh"
	@echo ""
	@echo "Option ALLSTYLES=yes|no (default: $(ALLSTYLES)): whether to export all styles (in contrast to: only the styles actually used)"
