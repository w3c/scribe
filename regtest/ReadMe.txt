This directory contains regression test cases (test-cases/*) for
scribe.perl. Each test case is an executable with the extension
".test". It must return exit code 0 for success, 2 for a test that is
not applicable, and any other code for a test that failed.

The other files are auxiliary files (mostly test input and reference
output).

Use the ../Makefile to run the tests.

The old test harness is not maintained. It consisted of:

        regtest.perl

	okdiffs.perl: Used to ignore output differences that do not indicate
		a problem.

	acceptemptydiffs: This was for accepting the new versions
		if there were no differences.  I don't remember if this 
		is useful any more.  Maybe the -a option to regtest.perl 
		makes this obsolete?  Or the -n option?  Not sure.

