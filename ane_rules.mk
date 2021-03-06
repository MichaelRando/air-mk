################## ANE Rules
ane: $(ANE)

clean::
	rm -fr $(EXT_XML) *.ane *.sw? *.nib META-INF
	rm -fr $(ANE_ANDROID_LIB) gen cls jar
	rm -fr $(WIKI_DIR)

$(EXT_XML): $(EXT_XML_IN)
	$(call expandMacros)

$(ANE): $(EXT_XML) $(ANE_SWC) $(ANE_SWF) $(IOS_XML) $(ANE_IOS_LIB) $(ANE_ANDROID_JAR) $(ANE_BUNDLED_LIBS) $(ANE_ANDROID_JAR_DEVICE_LIBS) $(ANE_IOS_RESOURCE_DIRS)
	$(call silent,ADT $@, \
	adt -package -target ane $(ANE) $(EXT_XML) -swc $(ANE_SWC) \
      -platform iPhone-ARM -platformoptions $(IOS_XML) \
          $(ANE_IOS_LIB) $(ANE_SWF) \
          $(foreach d,$(ANE_IOS_RESOURCE_DIRS),-C $(dir $d) $(notdir $d)) \
      $(if $(ANE_ANDROID_JAR), \
      -platform Android-ARM $(ANE_ANDROID_JAR) $(ANE_SWF) \
          $(foreach d,$(ANE_ANDROID_JAR_SOURCES), \
              $(if $(wildcard $d/res),-C $d res))) \
      -platform default $(ANE_SWF))
	$(if $(ANE_BUNDLED_LIBS), \
	  $(call silent,MERGE $@, \
	  rm -fr $(ANE_BUNDLED_LIBS_DIR) && \
	  mkdir -p $(ANE_BUNDLED_LIBS_DIR) && \
	  cp $(ANE_BUNDLED_LIBS) $(ANE_BUNDLED_LIBS_DIR) && \
	  zip -9qr $@ $(ANE_BUNDLED_LIBS_DIR)))

$(ANE_SWC): $(ANE_AS3_SRCS)
	$(call silent,COMPC $(ANE_CLASS), \
	$(COMPC) $(ASCFLAGS) $(foreach d,$(ANE_AS3DIR),-sp+=$d) -output $@ $(ANE_CLASS))

$(ANE_SWF): $(ANE_SWC)
	$(call silent,EXTRACT $@, unzip -qo $< $@)
	@touch $@

dist-upload: $(WIKI_MANIFEST)
	cd $(WIKI_DIR) &&\
  git add -A &&\
  git commit -m 'Update binaries from rev $(COMMIT)' &&\
  git push

$(WIKI_MANIFEST): $(WIKI_DIST)
	echo "Commit $(COMMIT)" >$@
	echo >>$@
	printf "$(foreach d,$(WIKI_DIST),[$(notdir $d)]($(notdir $d)))" >>$@

$(WIKI_DIST): | $(WIKI_DIR)

$(WIKI_DIR)/%: %
	cp $< $@

$(WIKI_DIR):
	git clone $(call chkvar,WIKI_GIT_URL) $(WIKI_DIR)

.PHONY: ane clean

$(call suffixrules,JAR,jar)
