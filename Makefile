# $Id$

ECHO=/bin/echo

# Add terminal escape codes for red, green and blue
FAIL := $(shell tput setaf 1)FAIL$(shell tput op)
OK := $(shell tput setaf 2)OK$(shell tput op)
NA := $(shell tput setaf 4)N/A$(shell tput op)

tests: scribe.perl xssVulnerabilityTests regressionTests

xssVulnerabilityTests: testTemplate.html xssVulnerabilityTest1 xssVulnerabilityTest2 xssVulnerabilityTest3 xssVulnerabilityTest4 xssVulnerabilityTest5

xssVulnerabilityTest1: xssVulnerabilityTest1.txt
	@if (perl scribe.perl xssVulnerabilityTest1.txt -embedDiagnostics -template testTemplate.html 2> /dev/null | grep -q -c '<img'); then $(ECHO) 'xss vulnerability test 1 $(FAIL)'; else $(ECHO) 'xss vulnerability test 1 $(OK)'; fi

xssVulnerabilityTest2: xssVulnerabilityTest2.txt
	@if (perl scribe.perl xssVulnerabilityTest2.txt -embedDiagnostics -template testTemplate.html 2> /dev/null | grep -q -c '<img'); then $(ECHO) 'xss vulnerability test 2 $(FAIL)'; else $(ECHO) 'xss vulnerability test 2 $(OK)'; fi

xssVulnerabilityTest3: xssVulnerabilityTest3.txt
	@if (perl scribe.perl xssVulnerabilityTest3.txt -embedDiagnostics -template testTemplate.html 2> /dev/null | grep -q -c '<img'); then $(ECHO) 'xss vulnerability test 3 $(FAIL)'; else $(ECHO) 'xss vulnerability test 3 $(OK)'; fi

xssVulnerabilityTest4: xssVulnerabilityTest4.txt
	@if (perl scribe.perl xssVulnerabilityTest4.txt -embedDiagnostics -template testTemplate.html 2> /dev/null | grep -q -c '<img'); then $(ECHO) 'xss vulnerability test 4 $(FAIL)'; else $(ECHO) 'xss vulnerability test 4 $(OK)'; fi

xssVulnerabilityTest5: xssVulnerabilityTest5.txt
	@if (perl scribe.perl xssVulnerabilityTest5.txt -embedDiagnostics -template testTemplate.html 2> /dev/null | grep -q -c '<img'); then $(ECHO) 'xss vulnerability test 5 $(FAIL)'; else $(ECHO) 'xss vulnerability test 5 $(OK)'; fi


# REGRESSION TESTS
#
# Each test is an executable with a name ending in .test. It must exit
# with status code 0 (test succeeded), 2 (test not applicable) or any
# other code (test failed). Any output is captured in a log file.

TESTS := $(wildcard regtest/test-cases/*.test)
RESULTS := $(TESTS:.test=.result)

%: %.test scribe.perl
	@$(ECHO) -n $< ""
	@$< >$*.log 2>&1; \
	 case $$? in \
	 0) $(ECHO) "$(OK)"; $(ECHO) OK >$*.result;; \
	 2) $(ECHO) "$(NA)"; $(ECHO) N/A >$*.result;; \
	 *) $(ECHO) "$(FAIL)"; $(ECHO) FAIL >$*.result;; \
	 esac

regressionTests: $(TESTS:.test=)
	@$(ECHO) "===================="
	@$(ECHO) "$(OK)  " `grep OK $(RESULTS) | wc -l`
	@$(ECHO) "$(FAIL)" `grep FAIL $(RESULTS) | wc -l`
	@$(ECHO) "$(NA) " `grep N/A $(RESULTS) | wc -l`
