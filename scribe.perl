#! perl -w

my ($CVS_VERSION) = q$Revision$ =~ /(\d+[\d\.]*\.\d+)/;

warn 'This is $Revision$ of $Date$ 
Check for newer version at http://dev.w3.org/cvsweb/~checkout~/2002/scribe/

';


# Generate minutes in HTML from a text IRC/chat Log.
#
# Author: David Booth <dbooth@w3.org> 
# License: GPL
#
# Take a raw W3C IRC log, clean it up a bit, and put it into HTML
# to create meeting minutes.  Reads stdin, writes stdout.
# Several input formats are accepted (see below).
# Input must follow certain conventions (see below).
#
# CONTRIBUTIONS
# 	Please make improvements to this program!  Check them into CVS (or
# 	email them to me) and notify me know by email.  Thanks!
#
# USAGE: 
#	perl scribe.perl [options] ircLogFile.txt > minutesFile.htm
#	perl scribe.perl -sampleInput
#	perl scribe.perl -sampleOutput
#	perl scribe.perl -sampleTemplate
#
# Options:
#	-sampleInput		Show me some sample input, so I can
#				learn how to use this program.
#
#	-sampleOutput		Show me some sample output.
#
#	-scribeOnly		Only keep scribe statements.  (Otherwise
#				everyone's statements are kept.)
#
#	-normalize		Just output the normalized input, without
#				formatting into HTML.  The purpose of this
#				is to allow you to edit the normalized log
#				(which is often easier than editing the raw
#				low) and then use it as input to generate
#				the HTML formatted minutes.
#
#	-template tfile		Use tfile as the template file for
#				generating the HTML.  Without this option,
#				the program will default to an embedded
#				template, which you can see by using
#				the "-sampleTemplate" option.
#
#	-sampleTemplate		Show me a sample template file.
#				(The default template.)
#
#	-public			Use a template that is formatted
#				for public access.  DEFAULT.
#				(Search for "sub PublicTemplate" below.)
#
#	-member			Use a template that is formatted 
#				for W3C member-only access.
#				(Search for "sub MemberTemplate" below.)
#
#	-team			Use a template that is formatted
#				for W3C team-only access.
#				(Search for "sub TeamTemplate" below.)
#
#	-mit			Use a template that is formatted for
#				W3C MIT style.
#				(Search for "sub MITTemplate" below.)
#
#	-trustRRSAgent		Take the action items from what RRSAgent says,
#				("<RRSAgent> I see 9 open action items...")
#				rather than directly from what an individual
#				wrote ("<dbooth> ACTION: ...").
#
#	-breakActions		Break long action lines into multiple lines.
#				The purpose of this is to indent the
#				continuation lines, such that when they are
#				later copied and pasted, the continuation
#				lines can be recognized and rejoined.
#
#	-implicitContinuations	Speaker statements are continued on following
#				lines without a leading space or "...":
#				# <dbooth> Amy: Now is the time
#				# <dbooth> for all good men and women
#				# <dbooth> to come to the aid of their party.
#
#
# The best way to use this program is:
#	1. Make a backup of your IRC log.
#	2. Modify the IRC log to conform to the scribe conventions that this
#	   program expects (described below).
#	3. Run this program as described above.
#	4. View the output in a browser.
#	5. Go back to step 2 to make modifications, and repeat.
#	   Once the output looks good enough, then . . .
#	6. Manually edit the resulting HTML for any remaining fixes.
#
# It's a good idea to run the output through "tidy -c".
# (See http://www.w3.org/People/Raggett/tidy/ .)
#
# SCRIBE CONVENTIONS:
# This program expects certain conventions in the IRC log as follows.
# Identify the IRC name of the scribe (Note that names must not contain spaces):
#	<dbooth> Scribe: dbooth
# Identify the meeting chair:
#	<dbooth> Chair: Jonathan
# Identify the meeting itself:
#	<dbooth> Meeting: Weekly Baking Club Meeting
# Identify the agenda:
#	<hugo> Agenda: http://www.example.com/myagenda
# Fix the meeting date (default is auto set from IRC log name or today if 
# there is no "Date:" line):
#	<dbooth> Date: 05 Dec 2002
# Identify the current topic.  You should insert one of
# these lines before the start of EACH topic:
#	<dbooth> Topic: Review of Action Items
# Record an action item:
#	<dbooth> ACTION: dbooth to send a message to himself about action items
# Record action item status (preferred format):
#	<Philippe> ACTION: Barbara to bake 3 pies [DONE]
#	<Philippe> ACTION: Barbara to bake 3 pies [PENDING]
#	<Philippe> ACTION: Barbara to bake 3 pies [DROPPED]
#	<Philippe> ACTION: Barbara to bake 3 pies [UNKNOWN]
#	<Philippe> ACTION: Barbara to bake 3 pies [IN_PROGRESS]
# Other formats also recognized:
#	<Philippe> ACTION: Barbara to bake 3 pies [IN PROGRESS]
#	<Philippe> ACTION: Barbara to bake 3 pies [IN-PROGRESS]
#	<Philippe> ACTION: Barbara to bake 3 pies  -- DONE
#	<Philippe> ACTION: Barbara to bake 3 pies  *DONE*
#	<Philippe> ACTION: Barbara to bake 3 pies  (DONE)
#	<Philippe> DONE: ACTION: Barbara to bake 3 pies
#	<Philippe> DONE ACTION: Barbara to bake 3 pies
# Scribe someone's statements:
#	<dbooth> Joseph: I think that we should all eat cake
#	<dbooth> ... with ice creme.
# Correct a mistake (changes most recent instance):
#	<dbooth> s/creme/cream/
# Correct a mistake globally from this point back in the input:
#	<dbooth> s/Baking/Cooking/g
# Identify the IRC log produced by RRSAGENT (this also sets the date):
#	<dbooth> rrsagent, where am i?
#	<RRSAgent> See http://www.w3.org/2002/11/07-ws-arch-irc#T13-59-36
# or:
#	<dbooth> Log: http://www.w3.org/2002/11/07-ws-arch-irc
# Separator (at least 4 dashes):
#	<dbooth> ----
#
# INPUT FORMATS ACCEPTED
# These formats are auto detected.  The best match wins.
#   MIRC buffer style:
#	<ericn> Where is our next F2F?
#	<dbooth> Rennes France.
#   RRSAgent Text style:
#	20:41:27 <ericn> Where is our next F2F?
#	20:41:37 <dbooth> Rennes France.
#   RRSAgent HTML style:
#	<dt id="T20-41-27">20:41:27 [ericn]</dt><dd>Where is our next F2F? </dd>
#	<dt id="T20-41-37">20:41:37 [dbooth]</dt><dd>Rennes France. </dd>
#   RRSAgent HTML Text style (text copied and pasted from the browser):
#	20:41:27 [ericn]
#	     Where is our next F2F?
#	20:41:37 [dbooth]
#	     Rennes France.
#   Yahoo IM style:
#	ericn: Where is our next F2F?
#	dbooth: Rennes France.


######################################################################
# FEATURE WISH LIST:
#
# 1. Adopt Karl's improved HTML style for MIT minutes.
# See http://lists.w3.org/Archives/Team/w3t/2003Dec/0158.html
#
# 2. Allow the scribe to change.  Process multiple "Scribe: dbooth" commands.
#
# 3. Improve the guess of who attended, when zakim did not report
# "attendees were ....".  Pick them up from zakim's lines like:
#	<dbooth> zakim, who is here?
#	<Zakim> On the phone I see Mike_Champion, Hugo, Dbooth, Suresh
#	<Zakim> + +1.978.235.aaaa
#	<hugo> Zakim, aaaa is Yin-Leng
#	<Zakim> +Yin-Leng; got it
#	<Zakim> +??P3
#	<Zakim> +S_Kumar
#	<Zakim> +Katia_Sycara
#	<Zakim> +Abbie
#	<Zakim> +Sinisa
#	<Zakim> +MIT308
#	<Zakim> +Sandro
#	<RalphS> zakim, mit308 has DBooth, Ralph
#	<Zakim> +DBooth, Ralph; got it
#	<RalphS> zakim, Steve just arrived in mit308
#	<Zakim> +Steve; got it
# (Examples are from http://www.w3.org/2003/12/11-ws-arch-irc.txt 
# and http://www.w3.org/2003/12/09-mit-irc.txt )
# (Also remember to watch out for zakim's continuation lines.)
#
# 4. Recognize [[ ...lines... ]] and treat them as a block by
# allowing them to be continuation lines for the same speaker,
# because they are probably pasted in.
#
# 5. Get $actionTemplate and $preSpeakerHTML, etc. from the HTML template,
# so that all formatting info is in the template.
#
# 6. Restructure the code to go through a big loop, processing one line
# at a time, with look-ahead to join continuation lines.
#
# 7. (From Hugo) Have RRSAgent run scribe.perl automatically when it 
# excuses itself
#
#

######################################################################
#
# WARNING: The code is a horrible mess.  (Sorry!)  Please hold your nose if 
# you look at it.  If you have something better, or make improvements
# to this (and please do!), please let me know.  Perhaps it's a good 
# example of Fred Brooke's advice in Mythical Man Month: "Plan to throw 
# one away". 
#
######################################################################


# Formatting:
# my $preSpeakerHTML = "<strong>";
# my $postSpeakerHTML = "</strong> <br />";
my $preSpeakerHTML = "<b>";
my $postSpeakerHTML = "</b>";
my $preParagraphHTML = "<p>";
my $postParagraphHTML = "</p>";
my $preTopicHTML = "<h3";
my $postTopicHTML = "</h3>";

# Other globals
my $namePattern = '([\\w]([\\w\\d\\-]*))';
# warn "namePattern: $namePattern\n";
my $debug = 0;
# Some important data/constants:
my @rooms = qw(MIT308 SophiaSofa DISA Fujitsu);
# stopList are non-people.
my @stopList = qw(a q on Re items Zakim Topic muted and agenda Regrets http the
	RRSAgent Loggy Zakim2 ACTION Chair Meeting DONE PENDING WITHDRAWN
	Scribe 00AM 00PM P IRC Topics Keio DROPPED ger-logger
	yes no abstain Consensus Participants Question RESOLVED strategy
	AGREED Date queue no one in XachBot got it WARNING);
@stopList = (@stopList, @rooms);
@stopList = map {&LC($_)} @stopList;	# Make stopList lower case
my %stopList = map {($_,$_)} @stopList;

# Get options/args
my $all = "";			# Input
my $normalizeOnly = 0;		# Output only the normlized input
my $canonicalizeNames = 0;	# Convert all names to their canonical form?
my $useTeamSynonyms = 0; 	# Accept any short synonyms for team members?
my $scribeOnly = 0;		# Only select scribe lines
my $trustRRSAgent = 0;		# Trust RRSAgent?
my $breakActions = 1;		# Break long action lines?
my $implicitContinuations = 0;	# Option: -implicitContinuations
my $scribeName = "UNKNOWN"; 	# Example: -scribe dbooth
my $useZakimTopics = 0; 	# Treat zakim agenda take-up as Topic change?
my $inputFormat = "";		# Input format, e.g., Plain_Text_Format

my @args = ();
my $template = &DefaultTemplate();
while (@ARGV)
	{
	my $a = shift @ARGV;
	if (0) {}
	elsif ($a eq "-normalize") 
		{ $normalizeOnly = 1; }
	elsif ($a eq "-sampleInput") 
		{ print STDOUT &SampleInput(); exit 0; }
	elsif ($a eq "-sampleOutput") 
		{ $all = &SampleInput(); }
	elsif ($a eq "-sampleTemplate") 
		{ print STDOUT &DefaultTemplate(); exit 0; }
	elsif ($a eq "-scribeOnly") 
		{ $scribeOnly = 1; }
	elsif ($a eq "-canon") 
		{ $canonicalizeNames = 1; }
	elsif ($a eq "-noBreakActions") 
	        { $breakActions = 0; }
	elsif ($a eq "-breakActions") 
	        { $breakActions = 1; }
	elsif ($a eq "-trustRRSAgent") 
	        { $trustRRSAgent = 1; }
	elsif ($a eq "-teamSynonyms") 
		{ $useTeamSynonyms = 1; }
	elsif ($a eq "-mit") 
		{ $template = &MITTemplate(); }
	elsif ($a eq "-team") 
		{ $template = &TeamTemplate(); }
	elsif ($a eq "-member") 
		{ $template = &MemberTemplate(); }
	elsif ($a eq "-world") 
		{ $template = &PublicTemplate(); }
	elsif ($a eq "-public") 
		{ $template = &PublicTemplate(); }
	elsif ($a eq "-template") 
		{ 
		my $templateFile = shift @ARGV; 
		die "ERROR: Template file not found: $templateFile\n"
			if !-e $templateFile;
		my $t = &GetTemplate($templateFile);
		if (!$t)
			{
			die "ERROR: Empty template: $templateFile\n";
			}
		$template = $t;
		}
	elsif ($a eq "-debug") 
		{ $debug = 1; }
	elsif ($a eq "-noUseZakimTopics") 
		{ $useZakimTopics = 0; }
	elsif ($a eq "-useZakimTopics") 
		{ $useZakimTopics = 1; }
	elsif ($a eq "-implicitContinuations") 
		{ $implicitContinuations = 1; }
	elsif ($a eq "-inputFormat") 
		{ $inputFormat = shift @ARGV; }
	elsif ($a eq "-scribe" || $a eq "-scribeName") 
		{ $scribeName = shift @ARGV; }
	elsif ($a =~ m/\A\-/)
		{ die "ERROR: Unknown option: $a\n"; }
	else	
		{ push(@args, $a); }
	}
@ARGV = @args;
@ARGV = map {glob} @ARGV;	# Expand wildcards in arguments

# Get input:
$all =  join("",<>) if !$all;
if (!$all)
	{
	warn "\nWARNING: Empty input.\n\n";
	}
# Delete control-M's if any.
$all =~ s/\r//g;

# Normalize input format.  This accepts several formats of input
# and puts it into a common format.
# The @inputFormats is the list of known normalizer functions.
# Each one is defined below.
# Just add another to the list if you want to recognize another format.
# Each function takes $all (the input text) as input and returns
# a pair: ($score, $newAll). 
#	$score is a value [0,1] indicating how well it matched (fraction
#		of lines conforming to this format).
#	$newAll is the normalized input.
my @inputFormats = qw(
		RRSAgent_Text_Format 
		RRSAgent_HTML_Format 
		RRSAgent_Visible_HTML_Text_Paste_Format
		Mirc_Text_Format
		Hugo_Log_Text_Format
		Yahoo_IM_Format
		Plain_Text_Format
		);
my %inputFormats = map {($_,$_)} @inputFormats;
if ($inputFormat && !exists($inputFormats{$inputFormat}))
	{
	warn "\nWARNING: Unknown input format specified: $inputFormat\n";
	warn "Reverting to guessing the format.\n\n";
	$inputFormat = "";
	}
# Try each known format, and see which one matches best.
my $bestScore = 0;
my $bestAll = "";
my $bestName = "";
foreach my $f (@inputFormats)
	{
	my ($score, $newAll) = &$f($all);
	# warn "$f: $score\n";
	if ($score > $bestScore)
		{
		$bestScore = $score;
		$bestAll = $newAll;
		$bestName = $f;
		}
	}
my $bestScoreString = sprintf("%4.2f", $bestScore);
if ($inputFormat)
	{
	# Format was specified using -inputFormat option
	my ($score, $newAll) = &$inputFormat($all);
	my $scoreString = sprintf("%4.2f", $score);
	$all = $newAll;
	warn "\nWARNING: Input looks more like $bestName format (score $bestScoreString),
but \"-inputFormat $inputFormat\" (score $scoreString) was specified.\n\n"
		if $score < $bestScore;
	}
else	{
	warn "Guessing input format: $bestName (score $bestScoreString)\n\n";
	die "ERROR: Could not guess input format.\n" if $bestScore == 0;
	warn "\nWARNING: Low confidence ($bestScoreString) on guessing input format: $bestName\n\n"
		if $bestScore < 0.7;
	$all = $bestAll;
	}

# Perform s/old/new/ substitutions.
while($all =~ m/\n\<[^\>]+\>\s*s\/([^\/]+)\/([^\/]*?)((\/(g))|\/?)(\s*)\n/i)
	{
	my $old = $1;
	my $new = $2;
	my $global = $5;
	$global = "" if !defined($global);
	my $pre = $`;
	my $match = $&;
	my $post = $';
	my $oldp = quotemeta($old);
	# warn "Found match: $match\n";
	my $told = $old;
	$told = $& . "...(truncated)...." if ($old =~ m/\A.*\n/);
	my $tnew = $new;
	$tnew = $& . "...(truncated)...." if ($old =~ m/\A.*\n/);
	my $succeeded = 0;
	my $tall = $pre . "\n" . $post;
	# s/old/new/g  replaces globally from this point backward
	if (($global eq "g")  && $pre =~ s/$oldp/$new/g)
		{
		warn "Succeeded: s/$told/$tnew/$global\n";
		$all = $pre . "\n" . $post;
		}
	# s/old/new/G  replaces globally, both forward and backward
	elsif (($global eq "G")  && $tall =~ s/$oldp/$new/g)
		{ 
		warn "Succeeded: s/$told/$tnew/$global\n";
		$all = $tall;
		}
	# s/old/new/  replaces most recent occurrance of old with new
	elsif ((!$global) && $pre =~ s/\A((.|\n)*)($oldp)((.|\n)*?)\Z/$1$new$4/)
		{
		warn "Succeeded: s/$told/$tnew/$global\n";
		$all = $pre . "\n" . $post;
		}
	else	{
		warn "\nWARNING: FAILED: s/$told/$tnew/$global\n\n";
		$match = &Trim($match);
		$all = $pre . "\n[scribe.perl auto substitution failed:] " . $match . "\n" . $post;
		}
	warn "\nWARNING: Multiline substitution!!! (Is this correct?)\n\n" if $tnew ne $new || $told ne $old;
	}

if ($canonicalizeNames) 
	{
	# Strip -home from names.  (Convert alan-home to alan, for example.)
	$all =~ s/(\w+)\-home\b/$1/ig;
	# Strip -lap from names.  (Convert alan-lap to alan, for example.)
	$all =~ s/(\w+)\-lap\b/$1/ig;
	# Strip -iMac from names.  (Convert alan-iMac to alan, for example.)
	$all =~ s/(\w+)\-iMac\b/$1/ig;
	}

if ($useZakimTopics)
	{
	# Treat zakim statements like:
	#	<Zakim> agendum 2. "UTF16 PR issue" taken up [from MSMscribe]
	# as equivalent to:
	#	<scribe> Topic: UTF16 PR issue
	$all = "\n$all\n";
	while ($all =~ s/\n\<Zakim\>\s*agendum\s*\d+\.\s*\"(.+)\"\s*taken up\s*((\[from (.*?)\])?)\s*\n/\n\<scribe\> Topic\: $1\n/i)
		{
		# warn "Zakim Topic: $1\n";
		}
	}

if ($normalizeOnly)
	{
	# This isn't really very good.  I thought this would be a
	# useful option, but now I'm not so sure, because several
	# of the scribe.perl commands (such as "Scribe: ...") are
	# removed when they're processed.
	my $t = join("\n", grep {m/\A\</;} split(/\n/, $all)) . "\n";
	print "$t\n";
	exit 0;
	}

# Determine scribe name if possible:
$scribeName = $1 if $all =~ s/\n\<[^\>\ ]+\>\s*Scribe\s*\:\s*(.+?)s*\n/\n/i;
if ($scribeName eq "UNKNOWN")
	{
	if ($bestName eq "Plain_Text_Format")
		{
		# Cannot guess the scribe when Plain_Text_Format format is used.
		warn "\nWARNING: Scribe name not specified!!!\n";
		}
	else	{
		$scribeName = &GuessScribeName($all);
		warn "\nWARNING: Scribe name not specified.  Guessing Scribe: $scribeName\n";
		}
	warn "Use the \"-scribe Hugo\" option or add a line like the following\n";
	warn "to explicitly indicate that Hugo is scribe (for example):\n";
	warn "Scribe: Hugo\n\n";
	}
$scribeName = &Trim($scribeName);
warn "Scribe: $scribeName\n";

# Get attendee list, and canonicalize names within the document:
my @uniqNames = ();
my $allNameRefsRef;
($all, $scribeName, $allNameRefsRef, @uniqNames) = &GetNames($all, $scribeName);
my @allNames = map { ${$_} } @{$allNameRefsRef};
my $scribePattern = quotemeta($scribeName);
# warn "scribePattern: $scribePattern\n";
# Replace scribe name with "scribe".  I.e., change
#	<dbooth> Minutes approved
# to
#	<scribe> Minutes approved
$all = "\n$all\n";
{
my $t = $all;
# Warning: Pattern match (annoyingly) returns "" if no match -- not 0.
my $nScribeLines = ($t =~ s/\n\<scribe\>/\n\<Scribe\>/ig);
$nScribeLines = 0 if $nScribeLines eq ""; # Make 0 if no match
# warn "nScribeLines: $nScribeLines\n";
my $nScribePatterns = ($all =~ s/\n\<$scribePattern\>/\n\<Scribe\>/ig);
$nScribePatterns = 0 if $nScribePatterns eq ""; # Make 0 if no match
# warn "nScribePatterns: $nScribePatterns\n";
if ($nScribeLines < 6 && $nScribePatterns <= 0)
	{
	warn "\nWARNING: No lines matching scribe name <$scribeName> found.\n";
	warn "Scribe name should match the scribe's IRC handle.\n\n";
	}
}
$scribePattern = "Scribe";
push(@allNames,"Scribe");
my @allSpeakerPatterns = map {quotemeta($_)} @allNames;
my $speakerPattern = "((" . join(")|(", @allSpeakerPatterns) . "))";
# warn "speakerPattern: $speakerPattern\n";

# Get the list of people present.
# First look for zakim output, as the default:
my @present = &GetPresentFromZakim($all); 
# Now look for explicit "Present: ... " commands:
die if !defined($all);
($all, @present) = &GetPresentOrRegrets("Present", 3, $all, @present); 
die if !defined($all);

# Get the list of regrets:
my @regrets = ();	# People who sent regrets
($all, @regrets) = &GetPresentOrRegrets("Regrets", 0, $all, ()); 

# Grab meeting name:
my $title = "SV_MEETING_TITLE";
if ($all =~ s/\n\<$namePattern\>\s*(Meeting|Title)\s*\:\s*(.*)\n/\n/i)
	{ $title = $4; }
else 	{ 
	warn "\nWARNING: No meeting title found!
You should specify the meeting title like this:
<dbooth> Meeting: Weekly Baking Club Meeting\n\n";
	}

# Grab agenda URL:
my $agendaLocation;
if ($all =~ s/\n\<$namePattern\>\s*(Agenda)\s*\:\s*(http:\/\/\S+)\n/\n/i)
	{ $agendaLocation = $4;
	  warn "Agenda: $agendaLocation\n";
      }
else 	{ 
	warn "\nWARNING: No agenda location found (optional).
If you wish, you may specify the agenda like this:
<dbooth> Agenda: http://www.example.com/agenda.html\n\n";
	}

# Grab Previous meeting URL:
my $previousURL = "SV_PREVIOUS_MEETING_URL";
if ($all =~ s/\n\<$namePattern\>\s*(Previous|PreviousMeeting|Previous Meeting)\s*\:\s*(.*)\n/\n/i)
	{ $previousURL = $4; }

# Grab Chair:
my $chair = "SV_MEETING_CHAIR";
if ($all =~ s/\n\<$namePattern\>\s*(Chair(s?))\s*\:\s*(.*)\n/\n/i)
	{ $chair = $5; }
else 	{ 
	warn "\nWARNING: No meeting chair found!
You should specify the meeting chair like this:
<dbooth> Chair: dbooth\n\n";
	}

# Grab IRC Log URL.  Do this before looking for the date, because
# we can figure out the date from the IRC log name.
my $logURL = "SV_MEETING_IRC_URL";
# <RRSAgent>   recorded in http://www.w3.org/2002/04/05-arch-irc#T15-46-50
$logURL = $3 if $all =~ m/\n\<(RRSAgent|Zakim)\>\s*(recorded|logged)\s+in\s+(http\:([^\s\#]+))/i;
$logURL = $3 if $all =~ m/\n\<(RRSAgent|Zakim)\>\s*(see|recorded\s+in)\s+(http\:([^\s\#]+))/i;
$logURL = $6 if $all =~ s/\n\<$namePattern\>\s*(IRC|Log|(IRC(\s*)Log))\s*\:\s*(.*)\n/\n/i;

# Grab and remove date from $all
my ($day0, $mon0, $year, $monthAlpha) = &GetDate($all, $namePattern, $logURL);

######### ACTION Item Processing
# These are the recognized action statuses.  Each status should be a
# single word, so use underscores if you have a multi-word status.
my @actionStatuses = qw(NEW PENDING IN_PROGRESS DONE DROPPED RETIRED UNKNOWN);
my %statusPatterns = ();	# Maps from a status to its regex.
foreach my $s (@actionStatuses)
	{
	die if $s !~ m/[a-zA-Z\_]/; # Canonical status, only letters/underscore
	my $p = quotemeta($s);
	# For multi-word status,
	# allow the user to write space or dash instead of underscore.
	# Accept as equivalent: IN_PROGRESS, IN PROGRESS, IN-PROGRESS 
	$p =~ s/\_/\[\\-\\_\\s\]\+/g; # Make _ into a pattern: [\_\-\s]+
	# warn "s: $s p: $p\n";
	$statusPatterns{$s} = $p;
	}

# Put all action items into a common format, to make them easier to process.
foreach my $s (@actionStatuses)
	{
	# First move the status out from in front of ACTION,
	# so that ACTION is always at the beginning.
	# Convert lines like: 
	#	[PENDING] ACTION: whatever
	# into lines like:
	#	ACTION: PENDING: whatever
	my $p = $statusPatterns{$s};
	while ($all =~ s/\n(\<[^\>]+\>)\s*\W*($p)\W+ACTION\s*\:\s*/\n$1 ACTION\: \[$s\] /i)
		{
		# warn "CONVERTED: $&\n";
		}
	# Now join ACTION continuation lines.  Convert lines like:
	#	<dbooth> ACTION: Mary to buy
	#	<dbooth>   the ingredients.
	# to this:
	#	<dbooth> ACTION: Mary to buy the ingredients.
	# It would be better if the continuation line processing was
	# done only once, globally, instead of doing it separately here
	# for actions.
	while ($all =~ s/\n(\<([^\>]+)\>\s*ACTION\s*\:\s*(.*?))\s*\n\<\2\>\s(\s+|(\s*\.\.+\s*))(.*?)\s*\n/\n\<$2\> ACTION\: $3 $6\n/i)
		{
		# warn "ACTION JOINED: $&\n";
		# die "all:\n$all\n";
		}
	# Now look for status on lines following ACTION lines.
	# This only works if we are NOT using RRSAgent's recorded actions.
	# Join line pairs like this:
	#	<dbooth> ACTION: whatever
	#	<dbooth> *DONE*
	# to lines like this:
	#	<dbooth> ACTION: whatever [DONE]
	while ($all =~ s/\n((\<[^\>]+\>)\s*ACTION\s*\:\s*(.*?))\n\<[^\>]+\>\W*($p)\W*\n/\n$1 \[$s\]\n/i)
		{
		# warn "STATUS JOINED: $&\n";
		}
	# Now grab the URL where the action was recorded.
	# Join line pairs like this:
	# 	<RRSAgent> ACTION: Simon develop ssh2 migration plan [1]
	# 	<RRSAgent>   recorded in http://www.w3.org/2003/09/02-mit-irc#T14-10-24
	# to lines like this:
	# 	<RRSAgent> ACTION: Simon develop ssh2 migration plan [1] [recorded in http://www.w3.org/2003/09/02-mit-irc#T14-10-24]
	while ($all =~ s/\n((\<RRSAgent\>)\s*ACTION\s*\:\s*(.*?))\n\<RRSAgent\>\s*(recorded in http\:\S+)\s*\n/\n$1 \[$4\]\n/i)
		{
		# warn "URL JOINED: $&\n";
		}
	}

# Now it's time to collect the action items.
# Grab the action items both ways (from RRSAgent, and not from RRSAgent),
# so that we can generate a warning if we find them one way but not the other.
# We are initially sloppy about the action text we collect, because we
# will later clean it up and parse out the status and URL.
#
# First grab RRSAgent actions.
my %rrsagentActions = ();	# Actions according to RRSAgent
my @rrsagentLines = grep {m/^\<RRSAgent\>/} split(/\s*\n/, $all);
for (my $i = 0; $i <= $#rrsagentLines; $i++) {
	$_ = $rrsagentLines[$i];
	# <RRSAgent> I see 3 open action items:
	if (m/^\<RRSAgent\> I see \d+ open action items\:$/) {
	    # Start again
	    %rrsagentActions = ();
	    next;
	}
	# <RRSAgent> ACTION: Simon develop ssh2 migration plan [1]
	next unless (m/\<RRSAgent\> ACTION\: (.*)$/);
	my $action = "$1";
	$rrsagentActions{$action} = "";	# Unknown status (will default to NEW)
	# warn "RRSAgent ACTION: $action\n";
}

# Now grab actions the old way (not the RRSAgent lines).
my %otherActions = ();		# Actions found in text (not according to RRSAgent)
foreach my $line (split(/\n/,  $all))
	{
	next if $line =~ m/^\<RRSAgent\>/;
	next if $line !~ m/\A\<[^\>]+\>\s*ACTION\s*\:\s*(.*?)\s*\Z/i;
	my $action = $1;
	# warn "OTHER ACTION: $action\n";
	$otherActions{$action} = "";
	}

# Which set of actions should we keep?
my %rawActions = ();	# Maps action to status (NEW|DONE|PENDING...)
if ($trustRRSAgent) {
	if (((keys %rrsagentActions) == 0) && ((keys %otherActions) > 0)) 
		{ warn "\nWARNING: No RRSAgent-recorded actions found, but 'ACTION:'s appear in the text.\nSUGGESTED REMEDY: Try running WITHOUT the -trustRRSAgent option\n\n"; }
	%rawActions = %rrsagentActions;
} else {
	%rawActions = %otherActions;
}

# Now clean up each action item and parse out its status and URL.
my %actions = ();
foreach my $action ((keys %rawActions))
	{
	my $a = $action;
	next if !$a;
	my $status = "";
	my $url = "";
	my $olda = "";
	# Grab stuff off the ends as long as there is stuff to grab.
	# We do this in a loop to allow them to appear in any order.
	# However, we process them in a particular order within this
	# loop to give precedence to the status that the scribe wrote last,
	# but precedence to the URL that was recorded first.
	CHANGE: while ($a ne $olda)
		{
		# warn "OLD a: $olda\n";
		# warn "NEW a: $a\n\n";
		$olda = $a;
		$a = &Trim($a);
		next CHANGE if $a =~ s/\s*\[\d+\]?\s*\Z//;	# Delete action numbers: [4] [4
		next CHANGE if $a =~ s/\AACTION\s*\:\s*//;	# Delete extra ACTION:
		# Grab URL from end of action.   
		# Innermost URL takes precedence if specified more than once.
		# This is not precisely the official URI pattern.
		my $urlp = "http\:[\#\%\&\*\+\,\-\.\/0-9\:\;\=\?\@-Z_a-z]+";
		if ($a =~ s/\s*\[\s*recorded in ($urlp)\s*(\]?\s*)\Z//i)
			{
			$url = $1;
			next CHANGE;
			}
		foreach my $s (@actionStatuses)
			{
			my $p = $statusPatterns{$s};
			# Grab status from end of action.
			# Outermost status takes precedence if 
			# status appears more than once.
			# Note that this may whack off the right bracket
			# From the action number:
			# 	OLD a: Hugo inprog3 action [4] -- IN PROGRESS
			# 	NEW a: Hugo inprog3 action [4
			if ($a =~ s/[\*\(\[\-\=\s\:\;]+($p)[\*\)\]\-\=\s]*\Z//i)
				{
				$status = $s if !$status;
				# warn "status: $status\n";
				next CHANGE;
				}
			}
		foreach my $s (@actionStatuses)
			{
			my $p = $statusPatterns{$s};
			# Grab status from beginning of action.
			if ($a =~ s/\A[\*\(\[\-\=\s]*($p)[\*\)\]\-\=\s\:\;]+//i)
				{
				$status = $s if !$status;
				# warn "status: $status\n";
				next CHANGE;
				}
			}
		}
	# Put the URL back on the end
	$a .= " [recorded in $url]" if $url;
	$status = "NEW" if !$status;
	# warn "FINAL: [$status] $a\n\n";
	$actions{$a} = $status;
	}

# Get a list of people who have current action items:
my %actionPeople = ();
foreach my $key ((keys %actions))
	{
	my $a = &LC($key);
	# warn "action:$a:\n";
	# Skip completed action items.  Check the status.
	my $lcs = &LC($actions{$key});
	my %completedStatuses = map {($_,$_)} 
		qw(done finished dropped completed retired deleted);
	next if exists($completedStatuses{$lcs});
	# Remove leading date:
	#	ACTION: 2003-10-09: Bijan to look into message extensibility Issues
	#	ACTION: 10/09/03: Bijan to look into message extensibility Issues
	#	ACTION: 10/9: Bijan to look into message extensibility Issues
	$a =~ s/\A\d+[\-\/]\d+(([\-\/]\d+)?)\s*\:\s*//;
	# Look for action recipients
	my @names = ();
	my @good = ();
	if ($a =~ m/\s+(to)\s+/i)
		{
		my $list = $`;
		@names = grep {$_ ne "and"} split(/[^a-zA-Z0-9\-\_\.]+/, $list);
		# warn "names: @names\n";
		foreach my $n (@names)
			{
			next if $n eq "";
			$n = &LC($n);
			push(@good, $n) if !exists($stopList{$n});
			}
		@good = () if @good != @names; # Fail
		}
	if ((!@good) && $a =~ m/\A([a-zA-Z0-9\-\_\.]+)/)
		{
		my $n = $1;
		@names = ($n);
		push(@good, $n) if !exists($stopList{$n});
		}
	# All good?
	if (@good && @good == @names)
		{
		foreach my $n (@good)
			{
			$actionPeople{$n} = $n;
			}
		}
	else	{
		warn "NO PERSON FOUND FOR ACTION: $a\n";
		}
	}
warn "People with action items: ",join(" ", sort keys %actionPeople), "\n";

# Format the resulting action items.
# Iterate through the @actionStatuses in order to group them by status.
# warn "ACTIONS:\n";
# my $actionTemplate = "<strong>[\$status]</strong> <strong>ACTION:</strong> \$action <br />\n";
my $actionTemplate = "[\$status] ACTION: \$action\n";
my @formattedActionLines = ();
foreach my $status (@actionStatuses)
	{
	my $n = 0;
	foreach my $action (sort keys %actions)
		{
		next if $actions{$action} ne $status;
		my $s = $actionTemplate;
		$s =~ s/\$action/$action/;
		$s =~ s/\$status/$status/;
		push(@formattedActionLines, $s);
		$n++;
		delete($actions{$action});
		}
	push(@formattedActionLines, "\n") if $n>0;
	}
# There shouldn't be any more kinds of actions, but if there are, format them.
# $actions{'FAKE ACTION TEXT'} = 'OTHER_STATUS';	# Test
foreach my $status (sort values %actions)
	{
	my $n = 0;
	foreach my $action (sort keys %actions)
		{
		next if $actions{$action} ne $status;
		my $s = $actionTemplate;
		$s =~ s/\$action/$action/;
		$s =~ s/\$status/$status/;
		push(@formattedActionLines, $s);
		$n++;
		delete($actions{$action});
		}
	push(@formattedActionLines, "\n") if $n>0;
	}

# Try to break lines over 76 chars:
@formattedActionLines = map { &BreakLine($_) } @formattedActionLines
	if $breakActions;
# Convert the @formattedActionLines to HTML.
# Add HTML line break to the end of each line:
@formattedActionLines = map { s/\n/ <br \/>\n/; $_ } @formattedActionLines;
# Change initial space (for continuation lines) to &nbsp;
@formattedActionLines = map { s/\A /\&nbsp\;/; $_ } @formattedActionLines;

my $formattedActions = join("", @formattedActionLines);
# Make links from URLs in actions:
$formattedActions =~ s/(http\:([^\)\]\}\<\>\s\"\']+))/<a href=\"$1\">$1<\/a>/g;

# Highlight ACTION items:
$formattedActions =~ s/\bACTION\s*\:(.*)/\<strong\>ACTION\:\<\/strong\>$1/g;
# Highlight in-line ACTION status:
foreach my $status (@actionStatuses)
	{
	$formattedActions =~ s/\[$status\]/<strong>[$status]<\/strong>/g;
	}

$all = &IgnoreGarbage($all);

if ($implicitContinuations)
	{
	# warn "Scribing style: -implicitContinuations\n";
	$all = &ExpandImplicitContinuations($all);
	}
else	{
	# warn "Scribing style: -explicitContinuations\n";
	if (&ProbablyUsesImplicitContinuations($all))
		{
		warn "\nWARNING: Input appears to use implicit continuation lines.\n";
		warn "You may need the \"-implicitContinuations\" option.\n\n";
		}
	}

$all = &PutSpeakerOnEveryLine($all);

# Convert from:
#	<dbooth> DanC: something
#	<dbooth> DanC: something
#	<DanC> something
#	<DanC> something
#	<dbooth> DanC: something
#	<dbooth> ----
#	<dbooth> Whatever
# to:
#	DanC: something
#	 ... something
#	<DanC> something
#	 ... something
#	DanC: something
#	----------------------------------------
#	<dbooth> Whatever
my $prevSpeaker = "UNKNOWN_SPEAKER:";	# "DanC:" or "<DanC>"
my $prevPattern; # Initialized below
my @linesIn = split(/\n/, $all);
my @linesOut = ();
while (@linesIn)
	{
	my $line = shift @linesIn;
	warn "LINE (BEFORE): $line\n" if $debug;
	# Ignore empty lines
	if ($line =~ m/\A\s*\Z/)
		{
		warn "  BLANK: $line\n" if $debug;
		next;
		}
	# Determine rough line format
	my $writer = "";
	my $speaker = "";
	my $text = "";
	# <writer> speaker: text
	if ($line =~ m/\A\<([a-zA-Z0-9\-_\.]+)\>\s*([a-zA-Z0-9\-_\.]+)\s*\:\s*(.*?)\s*\Z/i )
		{
		$writer = $1;
		$speaker = $2;
		$text = $3;
		warn "FIRST match 1:$1 2:$2 3:$3 LINE: $line\n" if $debug;
		}
	# <writer> text
	elsif ($line =~ m/\A\<([a-zA-Z0-9\-_\.]+)\>\s*(.*?)\s*\Z/i )
		{
		$writer = $1;
		$speaker = "";
		$text = $2;
		warn "SECOND match 1:$1 2:$2 LINE: $line\n" if $debug;
		}
	else	{
		die "DIED FROM UNKNOWN LINE FORMAT: $line\n\n";
		}
	# Make lower case versions, for easier comparison
	my $writerLC = &LC($writer);
	my $speakerLC = &LC($speaker);
	my $prevSpeakerLC = &LC($prevSpeaker);
	$prevPattern = quotemeta($prevSpeaker);
	warn "writerLC: $writerLC speakerLC: $speakerLC text: $text\n" if $debug;
	# warn "PHILIPPE: writerLC: $writerLC speakerLC: $speakerLC text: $text\n" if &Trim($speaker) eq "philippe";
	# warn "EMPTY TEXT: writerLC: $writerLC speakerLC: $speakerLC text: $text\n" if &Trim($text) eq "";
	# Process the various commands
	if (0) {}
	# Topic: ... 
	elsif ($speakerLC eq "topic")
		{
		warn "  TOPIC: $line\n" if $debug;
		# New topic.
		# Force the speaker name to be repeated next time
		$prevSpeaker = "UNKNOWN_SPEAKER:";	# "DanC:" or "<DanC>"
		}
	# Separator:
	#	<dbooth> ----
	elsif ($text =~ m/\A\-\-\-+\Z/ && !$speaker)
		{
		warn "  SEPARATOR1: $line\n" if $debug;
		my $dashes = '-' x 30;
		$line = $dashes;
		}
	# Separator:
	#	<dbooth> ====
	elsif ($text =~ m/\A\=\=\=+\Z/ && !$speaker)
		{
		warn "  SEPARATOR2: $line\n" if $debug;
		my $dashes = '=' x 30;
		$line = $dashes;
		}
	# Dots continuation line.
	# This commented out version is intended for when the "..." is
	# already on the line when we get here:
	# elsif ($line =~ s/\A\<Scribe\>\s*($prevPattern)//i) 
	elsif ($line =~ s/\A\<Scribe\>\s*($prevPattern)\s*/ ... /i) 
		{
		# $line = " ... $text";
		warn "  SAME SPEAKER: $line\n" if $debug;
		}
	# BUG: The \s* before the ":" in the pattern below doesn't work right,
	# because the ":" is stored as part of $prevSpeaker, so it
	# won't match right the next time "<dbooth> joe : whatever" is
	# encountered.
	elsif ($line =~ s/\A\<Scribe\>\s*(($speakerPattern)\:)\s*/$1 /i )
		{
		warn "  NEW SPEAKER: $line\n" if $debug;
		# New speaker
		$prevSpeaker = "$1";
		$prevPattern = quotemeta($prevSpeaker);
		}
	elsif ($line =~ m/\A$prevPattern\s*.*\bACTION\s*\:/i)
		{
		warn "  ACTION: $line\n" if $debug;
		}
	elsif ($line =~ s/\A$prevPattern\s*/ ... /i)
		{
		warn "  SCRIBE CONTINUES: $line\n" if $debug;
		}
	elsif ($line =~ s/\A(\<Scribe\>)\s*/Scribe\: /i )
		{
		warn "  SCRIBE SPEAKS: $line\n" if $debug;
		# Scribe speaks
		$prevSpeaker = $1;
		$prevPattern = quotemeta($prevSpeaker);
		# die "line: $line\n" if $line =~ m/Closing/;
		}
	elsif ($line =~ m/\A(\<$namePattern\>)/i)
		{
		warn "  IRC COMMENT: $line\n" if $debug;
		$prevSpeaker = $1;
		$prevPattern = quotemeta($prevSpeaker);
		}
	warn "LINE (AFTER): $line\n" if $debug;
	push(@linesOut, $line) if $line ne "";	# Default
	# die if $line =~ "Topic";
	}

$all = join("\n", @linesOut);
$all = "\n" . $all . "\n";	# Easier pattern matching


######################### HTML ##########################
# From now on, $all is in HTML!!!!!
##############  Escape < > as &lt; &gt; ################
# Escape < and >:
$all =~ s/\&/\&amp\;/g;
$all =~ s/\</\&lt\;/g;
$all =~ s/\>/\&gt\;/g;
# $all =~ s/\"/\&quot\;/g;

# Highlight in-line ACTION items:
my @allLines = split(/\n/, $all);
for (my $i=0; $i<@allLines; $i++)
	{
	next if $allLines[$i] =~ m/\&gt\;\s*Topic\s*\:/i;
	$allLines[$i] =~ s/\bACTION\s*\:(.*)/\<strong\>ACTION\:\<\/strong\>$1/;
	}
$all = "\n" . join("\n", @allLines) . "\n";

# Highlight in-line ACTION status:
foreach my $status (@actionStatuses)
	{
	$all =~ s/\[\s*$status\s*\]/<strong>[$status]<\/strong>/g;
	}

# Format topic titles (i.e., collect agenda):
my %agenda = ();
my $itemNum = "item01";
while ($all =~ s/\n(\&lt\;$namePattern\&gt\;\s+)?Topic\:\s*(.*)\n/\n$preTopicHTML id\=\"$itemNum\"\>$4$postTopicHTML\n/i)
	{
	$agenda{$itemNum} = $4;
	$itemNum++;
	}
if (!scalar(keys %agenda)) 	# No "Topic:"s found?
	{
	warn "\nWARNING: No \"Topic: ...\" lines found!  \nResulting HTML may have an empty (invalid) <ol>...</ol>.\n\nExplanation: \"Topic: ...\" lines are used to indicate the start of \nnew discussion topics or agenda items, such as:\n<dbooth> Topic: Review of Amy's report\n\n";
	}
my $agenda = "";
foreach my $item (sort keys %agenda)
	{
	$agenda .= '<li><a href="#' . $item . '">' . $agenda{$item} . "</a></li>\n";
	}

# Break into paragraphs:
$all =~ s/\n(([^\ \.\<].*)(\n\ *\.\.+.*)*)/\n$preParagraphHTML\n$1\n$postParagraphHTML\n/g;

# Bold or <strong> speaker name:
# Change "<speaker> ..." to "<b><speaker><b> ..."
my $preUniq = "PreSpEaKerHTmL";
my $postUniq = "PostSpEaKerHTmL";
$all =~ s/\n(\&lt\;($namePattern)\&gt\;)\s*/\n\&lt\;$preUniq$2$postUniq\&gt\; /ig;
# Change "speaker: ..." to "<b>speaker:<b> ..."
$all =~ s/\n($speakerPattern)\:\s*/\n$preUniq$1\:$postUniq /ig;
$all =~ s/$preUniq/$preSpeakerHTML/g;
$all =~ s/$postUniq/$postSpeakerHTML/g;

# Add <br /> before continuation lines:
$all =~ s/\n(\ *\.)/ <br \/>\n$1/g;
# Collapse multiple <br />s:
$all =~ s/<br \/>((\s*<br \/>)+)/<br \/>/g;
# Standardize continuation lines:
# $all =~ s/\n\s*\.+/\n\.\.\./g;
# Make links:
$all =~ s/(http\:([^\)\]\}\<\>\s\"\']+))/<a href=\"$1\">$1<\/a>/g;

# Put into template:
# $all =~ s/\A\s*<\/p>//;
# $all .= "\n<\/p>\n";
my $presentAttendees = join(", ", @present);
my $regrets = join(", ", @regrets);

my $result = $template;
$result =~ s/SV_MEETING_DAY/$day0/g;
$result =~ s/SV_MEETING_MONTH_ALPHA/$monthAlpha/g;
$result =~ s/SV_MEETING_YEAR/$year/g;
$result =~ s/SV_MEETING_MONTH_NUMERIC/$mon0/g;
$result =~ s/SV_PREVIOUS_MEETING_URL/$previousURL/g;
$result =~ s/SV_MEETING_CHAIR/$chair/g;
$result =~ s/SV_MEETING_SCRIBE/$scribeName/g;
$result =~ s/SV_MEETING_AGENDA/$agenda/g;
$result =~ s/SV_TEAM_PAGE_LOCATION/SV_TEAM_PAGE_LOCATION/g;

$result =~ s/SV_REGRETS/$regrets/g;
$result =~ s/SV_PRESENT_ATTENDEES/$presentAttendees/g;
if ($result !~ s/SV_ACTION_ITEMS/$formattedActions/)
	{
	if ($result =~ s/SV_NEW_ACTION_ITEMS/$formattedActions/)
		{ warn "\nWARNING: Template format has changed.  SV_NEW_ACTION_ITEMS should now be SV_ACTION_ITEMS\n\n"; }
	else { warn "\nWARNING: SV_ACTION_ITEMS marker not found in template!\n\n"; } 
	}
$result =~ s/SV_AGENDA_BODIES/$all/;
$result =~ s/SV_MEETING_TITLE/$title/g;

# Version
$result =~ s/SCRIBEPERL_VERSION/$CVS_VERSION/;

my $formattedLogURL = '<p>See also: <a href="SV_MEETING_IRC_URL">IRC log</a></p>';
if ($logURL eq "SV_MEETING_IRC_URL")
	{
	warn "\nWARNING: Missing IRC LOG!\n\n";
	$formattedLogURL = "";
	}
$formattedLogURL = "" if $logURL =~ m/\ANone\Z/i;
$result =~ s/SV_FORMATTED_IRC_URL/$formattedLogURL/g;
$result =~ s/SV_MEETING_IRC_URL/$logURL/g;

my $formattedAgendaLocation = '';
if ($agendaLocation) {
    $formattedAgendaLocation = "<p><a href='$agendaLocation'>Agenda</a></p>\n";
}
$result =~ s/SV_FORMATTED_AGENDA_LINK/$formattedAgendaLocation/g;

print $result;
exit 0;
################### END OF MAIN ######################


###################################################################
####################### GetPresentFromZakim ##########################
###################################################################
# Get the list of people present, as reported by zakim bot:
#	<Zakim> Attendees were Dbooth, Dietmar_Gaertner, Plh, GlenD,
#	<Zakim> ... IgorS, J.Mischkinsky, Lily, Umit, sanjiva, bijan,
sub GetPresentFromZakim
{
@_ == 1 || die;
my ($all) = @_;
die if !defined($all);
my @present = ();			# People present at the meeting
my @zakimLines = grep {s/\A\<Zakim\>\s*//i;} split(/\n/, $all);
my $t = join("\n", grep {s/\A\<Zakim\>\s*//i;} split(/\n/, $all)); 
# Join zakim continuation lines
$t =~ s/\n\.\.\.\.*\s*/ /g;
# die "t:\n$t\n" . ('=' x 70) . "\n\n";
@zakimLines = split(/\n/, $t);
foreach my $line (@zakimLines)
	{
	if ($line =~ m/Attendees\s+were\s+/i)
		{
		my $raw = $';
		my @people = map {$_ = &Trim($_); s/\s+/_/g; $_} split(/\,/, $raw);
		next if !@people;
		if (@present)
			{
			warn "\nWARNING: Replacing list of attendees.\nOld list: @present\nNew list: @people\n\n";
			}
		@present = @people;
		}
	}
return(@present);
}

###################################################################
####################### GetPresentOrRegrets ##########################
###################################################################
# Look for explicit "Present: ..." or "Regrets: ..." commands.
# Arguments: $keyword, $minPeople, $all, @present (default)
# Returns: ($all, @present)
# $all is modified by removing any "Present: ..." commands.
sub GetPresentOrRegrets
{
@_ >= 3 || die;
my (	$keyword, 	# What we're looking for: "Present" or "Regrets"
	$minPeople, 	# Min number of people to avoid a warning
	$all, 		# The input
	@present	# Default people present at the meeting
	) = @_;
die if !defined($all);
my @allLines = split(/\n/, $all);
# <dbooth> Present: Amy Frank Joe Carol
# <dbooth> Present: David Booth, Frank G, Joe Camel, Carole King
# <dbooth> Present+: Justin
# <dbooth> Present+ Silas
# <dbooth> Present-: Amy
my @possiblyPresent = @uniqNames;	# People present at the meeting
my @newAllLines = ();	# Collect remaining lines
# push(@allLines, "<dbooth> Present: David Booth, Frank G, Joe Camel, Carole King"); # test
# push(@allLines, "<dbooth> Present: Amy Frank Joe Carole"); # test
# push(@allLines, "<dbooth> Present+: Justin"); # test
# push(@allLines, "<dbooth> Present+ Silas"); # test
# push(@allLines, "<dbooth> Present-: Amy"); # test
foreach my $line (@allLines)
	{
	$line =~ s/\s+\Z//; # Remove trailing spaces.
	if ($line !~ m/\A\<[^\>]+\>\s*$keyword\s*(\:|((\+|\-)\s*\:?))\s*(.*)\Z/i)
		{
		push(@newAllLines, $line);
		next;
		}
	my $plus = $1;
	my $present = $4;
	my @p = ();
	if ($present =~ m/\,/)
		{
		# Comma-separated list
		@p = grep {$_ && $_ ne "and"} 
				map {$_ = &Trim($_); s/\s+/_/g; $_} 
				split(/\,/,$present);
		}
	else	{
		# Space-separated list
		@p = grep {$_} split(/\s+/,$present);
		}
	if ($plus =~ m/\+/)
		{
		my %seen = map {($_,$_)} @present;
		my @newp = grep {!exists($seen{$_})} @p;
		push(@present, @newp);
		}
	elsif ($plus =~ m/\-/)
		{
		my %seen = map {($_,$_)} @present;
		foreach my $p (@p)
			{
			delete $seen{$p} if exists($seen{$p});
			}
		@present = sort keys %seen;
		}
	else	{
		warn "\nWARNING: Replacing previous list of people present.\nUse '$keyword\+ ... ' if you meant to add people without replacing the list,\nsuch as: <dbooth> $keyword\+ " . join(', ', @p) . "\n\n" if @present;
		@present = @p;
		}
	}
@allLines = @newAllLines;
$all = "\n" . join("\n", @allLines) . "\n";
if (@present == 0)	
	{
	warn "\nWARNING: No \"$keyword\: ... \" found!\n";
	warn "Possibly Present: @possiblyPresent\n" if $keyword eq "Present"; 
	warn "You can indicate people for the $keyword list like this:
<dbooth> $keyword\: dbooth jonathan mary
<dbooth> $keyword\+ amy\n\n";
	}
else	{
	warn "$keyword\: @present\n"; 
	warn "\nWARNING: Fewer than $minPeople people found for $keyword list!\n\n" if @present < $minPeople;
	}
return ($all, @present);
}

#######################################################################
################## PutSpeakerOnEveryLine ######################
#######################################################################
# Canonicalize Scribe continuation lines so that the speaker's name is 
# on every line.  Convert:
#	<dbooth> Scribe: dbooth
#	<dbooth> SusanW: We had a mtg on July 16.
#	<DanC_> pointer to minutes?
#	<dbooth> SusanW: I'm looking.
#	<dbooth> ... The minutes are on
#	<dbooth>  the admin timeline page.
# to:
#	<dbooth> Scribe: dbooth
#	<dbooth> SusanW: We had a mtg on July 16.
#	<DanC_> pointer to minutes?
#	<dbooth> SusanW: I'm looking.
#	<dbooth> SusanW: The minutes are on
#	<dbooth> SusanW: the admin timeline page.
# Unfortunately, I don't remember why I did this.  I assume it was to
# make subsequent processing easier, but now I don't know why it is needed.
sub PutSpeakerOnEveryLine
{
@_ == 1 || die;
my ($all) = @_;
my @allLines = split(/\n/, $all);
my $currentSpeaker = "UNKNOWN_SPEAKER";
for (my $i=0; $i<@allLines; $i++)
	{
	# warn "$allLines[$i]\n" if $allLines[$i] =~ m/Liam/;
	if ($allLines[$i] =~ m/\A\<Scribe\>(\s?\s?)($speakerPattern)\s*\:/i)
		{
		# The $speakerPattern in the pattern match above is
		# constructed from all of the known speaker names, so 
		# it will NOT match "Topic" or other keywords.
		# But to be safe, let's check it against the %stopList anyway.
		my $cs = $2;
		my $lccs = &LC($cs);
		$currentSpeaker = $cs if !exists($stopList{$lccs});
		}
	# Dot continuation line: "<dbooth> ... The minutes are on".
	# I'm not sure the following is right.  If there is a continuation
	# line after a non-speaker line, such as "Topic: whatever", then
	# I think this will act as a continuation of the previous speaker
	# line, which may not be the right thing to do.
	# (Rather, it probably should be a continuation line of the topic.)
	# I think the code for this program should be restructured, to
	# act globally on one line at a time, with look-ahead used to
	# join continuation lines on to the current line.
	# The following commented out version is for when the code is changed
	# to not remove (and later replace) the "...":
	# elsif ($allLines[$i] =~ s/\A\<Scribe\>(\s?)\.\./\<Scribe\> $currentSpeaker: ../i)
	elsif ($allLines[$i] =~ s/\A\<Scribe\>(\s?)\.\.+(\s?)/\<Scribe\> $currentSpeaker: /i)
		{
		# warn "Scribe NORMALIZED: $& --> $allLines[$i]\n";
		warn "\nWARNING: UNKNOWN SPEAKER: $allLines[$i]\nPossibly need to add line: <Zakim> +someone\n\n" if $currentSpeaker eq "UNKNOWN_SPEAKER";
		}
	# Leading-blank continuation line: "<dbooth>  the admin timeline page.".
	elsif ($allLines[$i] =~ s/\A\<Scribe\>\s\s/\<Scribe\> $currentSpeaker:  /i)
		{
		# warn "Scribe NORMALIZED: $& --> $allLines[$i]\n";
		warn "\nWARNING: UNKNOWN SPEAKER: $allLines[$i]\nPossibly need to add line: <Zakim> +someone\n\n" if $currentSpeaker eq "UNKNOWN_SPEAKER";
		}
	else	{
		}
	}
$all = "\n" . join("\n", @allLines) . "\n";
# die "all:\n$all\n" . ('=' x 70) . "\n\n";
return $all;
}

#################################################################
################# GuessScribeName #################
#################################################################
# Guess the scribe name based on who wrote the most in the log.
sub GuessScribeName
{
@_ == 1 || die;
my ($all) = @_;
$all = &IgnoreGarbage($all);
my @lines = split(/\n/, $all);
my $nLines = 0;	# Total number of "<someone> something " lines.
my %nameCounts = (); # Count of the number of lines written per person.
my %mixedCaseNames = (); # Map from lower case name to mixed case name
foreach my $line (@lines)
	{
	if ($line =~ m/\A\<([^\>]+)\>/)
		{
		$nLines++;
		my $mix = $1;	# Liam
		my $who = &LC($mix);	# liam
		$nameCounts{$who}++;
		$mixedCaseNames{$who} = $mix; # liam -> Liam
		}
	}
my @descending = sort { $nameCounts{$b} <=> $nameCounts{$a} } keys %nameCounts;
# warn "Names in descending order:\n";
foreach my $n (@descending)
	{
	# warn "	$nameCounts{$n} $n\n";
	}
# warn "\n";
return "UNKNOWN" if !@descending;
return $mixedCaseNames{$descending[0]};
}


#################################################################
################# IgnoreGarbage #################
#################################################################
# Ignore off-record lines and other lines that should not be minuted.
sub IgnoreGarbage
{
@_ == 1 || die;
my ($all) = @_;
my @lines = split(/\n/, $all);
my $nLines = scalar(@lines);
# warn "Lines found: $nLines\n";
my @scribeLines = ();
foreach my $line (@lines)
	{
	# Ignore /me lines
	next if $line =~ m/\A\s*\*/;
	# Select only <speaker> lines
	next if $line !~ m/\A\<$namePattern\>/i;
	# Ignore empty lines
	next if $line =~ m/\A\<$namePattern\>\s*\Z/i;
	# Ignore join/leave lines:
	next if $line =~ m/\A\s*\<($namePattern)\>\s*\1\s+has\s+(joined|left|departed|quit)\s*((\S+)?)\s*\Z/i;
	next if $line =~ m/\A\s*\<(Scribe)\>\s*$namePattern\s+has\s+(joined|left|departed|quit)\s*((\S+)?)\s*\Z/i;
	# Ignore topic change lines:
	# <geoff_a> geoff_a has changed the topic to: Trout Mask Replica
	next if $line =~ m/\A\s*\<($namePattern)\>\s*\1\s+(has\s+changed\s+the\s+topic\s+to\s*\:.*)\Z/i;
	# Ignore zakim lines
	next if $line =~ m/\A\<Zakim\>/i;
	next if $line =~ m/\A\<$namePattern\>\s*zakim\s*\,/i;
	next if $line =~ m/\A\<$namePattern\>\s*agenda\s*\d*\s*[\+\-\=\?]/i;
	next if $line =~ m/\A\<$namePattern\>\s*close\s+agend(a|(um))\s+\d+\Z/i;
	next if $line =~ m/\A\<$namePattern\>\s*open\s+agend(a|(um))\s+\d+\Z/i;
	next if $line =~ m/\A\<$namePattern\>\s*take\s+up\s+agend(a|(um))\s+\d+\Z/i;
	next if $line =~ m/\A\<$namePattern\>\s*q\s*[\+\-\=\?]/i;
	next if $line =~ m/\A\<$namePattern\>\s*queue\s*[\+\-\=\?]/i;
	next if $line =~ m/\A\<$namePattern\>\s*ack\s+$namePattern\s*\Z/i;
	# Ignore RRSAgent lines
	next if $line =~ m/\A\<RRSAgent\>/i;
	next if $line =~ m/\A\<$namePattern\>\s*RRSAgent\s*\,/i;
	# Remove off the record comments:
	next if $line =~ m/\A\<$namePattern\>\s*\[\s*off\s*\]/i;
	# Select only <Scribe> lines?
	next if $scribeOnly && $line !~ m/\A\<Scribe\>/i;
	# warn "KEPT: $line\n";
	push(@scribeLines, $line);
	}
my $nScribeLines = scalar(@scribeLines);
# warn "Minuted lines found: $nScribeLines\n";
$all = "\n" . join("\n", @scribeLines) . "\n";

# Verify that we axed all join/leave lines:
my @matches = ($all =~ m/.*has joined.*\n/g);
warn "\nWARNING: Possible join/leave lines remaining: \n\t" . join("\t", @matches) . "\n\n"
 	if @matches;
return $all;
}

#################################################################
########################## BreakLine ###########################
#################################################################
# Try to break lines longer than $maxLineLength chars.
# Continuation lines are indented by a space.
# Input line should end with a newline;
# resulting lines will end with newlines.
# Lines are only broken at spaces.  Long words are never broken.
# Hence, the resulting line length may exceed the given $maxLineLength
# if there is a word that is longer than $maxLineLength (such as
# a URL).
sub BreakLine
{
@_ == 1 || @_ == 2 || die;
my ($line, $maxLineLength) = @_;
$maxLineLength = 76 if !defined($maxLineLength);
die if $line !~ m/\n\Z/;
my @result = ();
my $newLine = "";
my $nextWord = "";
while (1)
	{
	$newLine .= $nextWord;		# Append to $newLine
	last if ($line !~ s/\A\s*\S+//);	# Grab next word
	$nextWord = $&;
	if (length($newLine) > 0
	  && length($newLine) + length($nextWord) > $maxLineLength)
		{
		$newLine .= "\n";
		push(@result, $newLine);
		$newLine = " ";
		}
	}
$newLine .= "\n";
push(@result, $newLine);
return(@result);
}


##################################################################
########################## Mirc_Text_Format #########################
##################################################################
# Format from saving MIRC buffer.
sub Mirc_Text_Format
{
die if @_ != 1;
my ($all) = @_;
# Join continued lines:
$all =~ s/\n\ \ //g;
# Fix split URLs:
# 	<RalphS> -> http://lists.w3.org/Archives/Team/w3t-mit/2002Mar/00
# 	  46.html Simon's two minutes
# while ($all =~ s/(http\:[^\ ]+)\n\ \ /$1/ig) {}
# while ($all =~ s/(http\:[^\ ]+)\n\ /$1/ig) {}
# Count the number of recognized lines
my @lines = split(/\n/, $all);
my $n = 0;
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
foreach my $line (@lines)
	{
	# * unlogged comment
	if ($line =~ m/\A\s*\*\s/) { $n++; }
	# <ericn> Discussion on how to progress
	elsif ($line =~ m/\A\<$namePattern\>\s/) { $n++; }
	# warn "LINE: $line\n";
	}
# warn "Mirc_Text_Format n matches: $n\n";
my $score = $n / @lines;
return($score, $all);
}

##################################################################
########################## Hugo_Log_Text_Format #########################
##################################################################
# Example: http://lists.w3.org/Archives/Public/www-archive/2004Jan/att-0003/ExampleFormat-NormalizerHugoLogText.txt
sub Hugo_Log_Text_Format
{
die if @_ != 1;
my ($all) = @_;
# Join continued lines:
$all =~ s/\n\ \ //g;
# Count the number of recognized lines
my @lines = split(/\n/, $all);
my $nLines = scalar(@lines);
my $n = 0; # Number of lines of recognized format.
my $namePattern = '([\\w\\-]([\\w\\d\\-\\.]*))';
# 2003-12-18T15:26:57-0500 
my $datePattern = '(\d\d\d\d\-(\ |\d)\d\-(\ |\d)\d)';	# 3 parens
my $timePattern = '((\s|\d)\d\:(\s|\d)\d\:(\s|\d)\d)';	# 4 parens
my $hourOffsetPattern = '((( |\-|\+)\d\d\d\d)?)';	# 3 parens
my $timestampPattern = $datePattern . "T" . $timePattern . $hourOffsetPattern;
# warn "timestampPattern: $timestampPattern namePattern: $namePattern\n";
my @linesOut = ();
while (@lines)
	{
	my $line = shift @lines;
	# 20:41:27 <ericn> Review of minutes 
	if (0) {}
	# Keep normal lines:
	# 2003-12-18T15:27:36-0500 <hugo> Hello.
	elsif ($line =~ s/\A$timestampPattern\s+(\<$namePattern\>)/$11/)
		{ $n++; push(@linesOut, $line); }
	# Also keep comment lines.  They'll be removed later.
	# 2003-12-18T16:56:06-0500  * RRSAgent records action 4
	elsif ($line =~ s/\A$timestampPattern\s+(\*)/$11/)
		{ $n++; push(@linesOut, $line); }
	# Recognize, but discard:
	# 2003-12-18T15:26:57-0500 !mcclure.w3.org hugo invited Zakim into channel #ws-arch.
	elsif ($line =~ m/\A$timestampPattern\s+\!/)
		{ $n++; } 
	# Recognize, but discard:
	# 2003-12-18T15:27:30-0500 -!- dbooth [dbooth@18.29.0.30] has joined #ws-arch
	elsif ($line =~ m/\A$timestampPattern\s+\-\!\-/)
		{ $n++; } 
	else	{
		# warn "UNRECOGNIZED LINE: $line\n";
		push(@linesOut, $line); # Keep unrecognized line
		}
	# warn "LINE: $line\n";
	}
$all = "\n" . join("\n", @linesOut) . "\n";
# warn "Hugo_Log_Text_Format n matches: $n\n";
my $score = $n / $nLines;
return($score, $all);
}

##################################################################
########################## RRSAgent_Text_Format #########################
##################################################################
# Example: http://www.w3.org/2003/03/03-ws-desc-irc.txt
sub RRSAgent_Text_Format
{
die if @_ != 1;
my ($all) = @_;
# Join continued lines:
$all =~ s/\n\ \ //g;
# Count the number of recognized lines
my @lines = split(/\n/, $all);
my $n = 0;
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
my $timePattern = '((\s|\d)\d\:(\s|\d)\d\:(\s|\d)\d)';
foreach my $line (@lines)
	{
	# 20:41:27 <ericn> Review of minutes 
	$n++ if $line =~ s/\A$timePattern\s+(\<$namePattern\>\s)/$5/;
	# warn "LINE: $line\n";
	}
$all = "\n" . join("\n", @lines) . "\n";
# warn "RRSAgent_Text_Format n matches: $n\n";
my $score = $n / @lines;
return($score, $all);
}

##################################################################
########################## RRSAgent_HTML_Format #########################
##################################################################
# Example: http://www.w3.org/2003/03/03-ws-desc-irc.html
sub RRSAgent_HTML_Format
{
die if @_ != 1;
my ($all) = @_;
my @lines = split(/\n/, $all);
my $n = 0;
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
my $timePattern = '((\s|\d)\d\:(\s|\d)\d\:(\s|\d)\d)';
foreach my $line (@lines)
	{
	# <dt id="T14-35-34">14:35:34 [dbooth]</dt><dd>Gudge: why not sufficient?</dd>
	$n++ if $line =~ s/\A\<dt\s+id\=\"($namePattern)\"\>$timePattern\s+\[($namePattern)\]\<\/dt\>\s*\<dd\>(.*)\<\/dd\>\s*\Z/\<$8\> $11/;
	# warn "LINE: $line\n";
	}
$all = "\n" . join("\n", @lines) . "\n";
# warn "RRSAgent_HTML_Format n matches: $n\n";
my $score = $n / @lines;
# Unescape &entity;
$all =~ s/\&amp\;/\&/g;
$all =~ s/\&lt\;/\</g;
$all =~ s/\&gt\;/\>/g;
$all =~ s/\&quot\;/\"/g;
return($score, $all);
}

##################################################################
########################## RRSAgent_Visible_HTML_Text_Paste_Format #########################
##################################################################
# This is for the format that is visible in the browser when RRSAgent's HTML
# is displayed.  I.e., when you view the (HTML) document in a browser, and 
# then copy and paste the text from the browser window, it discards
# the HTML code and copies only the displayed text.
# Example: http://lists.w3.org/Archives/Public/www-archive/2004Jan/att-0002/ExampleFormat-RRSAgent_Visible_HTML_Text_Paste_Format.txt
sub RRSAgent_Visible_HTML_Text_Paste_Format
{
die if @_ != 1;
my ($all) = @_;
my $n = 0;
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
my $timePattern = '((\s|\d)\d\:(\s|\d)\d\:(\s|\d)\d)';
my $done = "";
while($all =~ s/\A((.*\n)(.*\n))//)	# Grab next two lines
	{
	my $linePair = $1;
	my $line1 = $2;
	my $line2 = $3;
	# This format uses line pairs:
	# 	14:43:30 [Arthur]
	# 	If it's abstract, it goes into portType 
	if ($linePair =~ s/\A($timePattern)\s+\[($namePattern)\][\ \t]*\n/\<$6\> /)
		{
		$n++;
		# warn "LINE: $line\n";
		$done .= $linePair;
		}
	else	{
		$done .= $line1;
		$all = $line2 . $all;
		}
	}
$done .= $all;
$all = $done;
# warn "RRSAgent_Visible_HTML_Text_Paste_Format n matches: $n\n";
my @lines = split(/\n/, $all);
my $score = $n / @lines;
return($score, $all);
}

##################################################################
########################## Yahoo_IM_Format #########################
##################################################################
sub Yahoo_IM_Format
{
die if @_ != 1;
my ($all) = @_;
my @lines = split(/\n/, $all);
my $n = 0;
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
foreach my $line (@lines)
	{
	$n++ if $line =~ s/\A($namePattern)\:\s/\<$1\> /;
	# warn "LINE: $line\n";
	}
$all = "\n" . join("\n", @lines) . "\n";
# warn "Yahoo_IM_Format n matches: $n\n";
my $score = $n / @lines;
return($score, $all);
}

##################################################################
########################## Plain_Text_Format #########################
##################################################################
# This is just a plain text file of notes made by the scribe.
# This format does NOT use timestamps, nor does it use <speakerName>
# at the beginning of each line.  It does still use the "dbooth: ..."
# convention to indicate what someone said.
sub Plain_Text_Format
{
die if @_ != 1;
my ($all) = @_;
# Join continued lines:
# Count the number of recognized lines
my @lines = split(/\n/, $all);
my $n = 0;
my $timePattern = '((\s|\d)\d\:(\s|\d)\d\:(\s|\d)\d)';
my $namePattern = '([\\w\\-]([\\w\\d\\-\\.]*))';
for (my $i=0; $i<@lines; $i++)
	{
	# Lines should NOT have timestamps:
	# 	20:41:27 <ericn> Review of minutes 
	next if $lines[$i] =~ m/$timePattern\s+/;
	# Lines should NOT contain <speakerName>:
	# 	<ericn> Review of minutes 
	next if $lines[$i] =~ m/(\<$namePattern\>\s)/;
	# Line should NOT have [name] unless it pertains to an action item.
	# Check the current line and previous line for the word ACTION,
	# because the action status [PENDING] could follow the ACTION line.
	next if $lines[$i] =~ m/(\[$namePattern\]\s)/
		&&  $lines[$i] !~ m/\bACTION\b/i
		&&  ($i == 0 || ($lines[$i] !~ m/\bACTION\b/i));
	# warn "LINE: $lines[$i]\n";
	$n++;
	}
# Now add "<Scribe> " to the beginning of each line, to make it like
# the standard format.
for (my $i=0; $i<@lines; $i++)
	{
	$lines[$i] = "<Scribe> " . $lines[$i];
	}
$all = "\n" . join("\n", @lines) . "\n";
# warn "Plain_Text_Format n matches: $n\n";
my $score = $n / @lines;
# Artificially downgrade the score, so that more specific formats
# like Yahoo_IM_Format will win if possible:
$score = $score * 0.95;
return($score, $all);
}

##################################################################
########################## ProbablyUsesImplicitContinuations #########################
##################################################################
# Guess whether the input probably uses implicit continuation lines.
# The implicit continuation style is like:
# 	<dbooth> Amy: Now is the time
# 	<dbooth> for all good men and women
# 	<dbooth> to come to the aid
# 	<dbooth> of their party.
# Note that there is no extra space setting of the continuation lines.
# This style is ambiguous, because we can't distinguish between the
# continuation of the previous speaker's statement and a new statement made
# by the scribe.
#
# The <dbooth>'s should have already been changed to <scribe> prior 
# to calling this function.
sub ProbablyUsesImplicitContinuations
{
die if @_ != 1;
my ($all) = @_;
$all = &IgnoreGarbage($all);
my @lines = split(/\n/, $all);
my @t = @lines;
# Blank lines:
@t = grep {!m/\A\s*\Z/} @t;
# Only consider scribe statements
# 	<scribe> whatever
@t = grep {m/\A\<scribe\>/i} @t;
# Don't count action lines
# 	<dbooth> [DONE] ACTION: ...
@t = grep {!m/\bACTION\b/i} @t;
# Don't count empty statements
# 	<dbooth> 
# @t = grep {!m/\A\<[a-zA-Z0-9\-_\.]+\>\s*\Z/} @t;
@t = grep {!m/\A\<scribe\>\s*\Z/i} @t;
my $nTotal = scalar(@t);
 # 	<dbooth> Amy: Now is the time (EXPLICIT SPEAKER)
 # @t = grep {!m/\A\<[a-zA-Z0-9\-_\.]+\>(\s?\s?)[a-zA-Z0-9\-_\.]+\s*\:/i} @t;
 @t = grep {!m/\A\<scribe\>(\s?\s?)[a-zA-Z0-9\-_\.]+\s*\:/i} @t;
my $nSpeaker = $nTotal - scalar(@t);
 # 	<dbooth>  for all good men and women  (EXPLICIT CONTINUATION)
 # @t = grep {!m/\A\<[a-zA-Z0-9\-_\.]+\>(\s\s\s*)/} @t;
 @t = grep {!m/\A\<scribe\>(\s\s\s*)/i} @t;
 # 	<dbooth> ... for all good men and women  (EXPLICIT CONTINUATION)
 # @t = grep {!m/\A\<[a-zA-Z0-9\-_\.]+\>(\s*)\.\./} @t;
 @t = grep {!m/\A\<scribe\>(\s*)\.\./i} @t;
my $nExpCont = $nTotal - ($nSpeaker + scalar(@t));
 # Remaining lines are potentially implicit continuation lines.
my $nPossCont = scalar(@t);
die if $nPossCont + $nExpCont + $nSpeaker != $nTotal;
# warn "nTotal: $nTotal nSpeaker: $nSpeaker nExpCont: $nExpCont nPossCont: $nPossCont\n";
# Guess the format
my $result = 0;
if ($nPossCont == 0)
	{
	$result = 0;
	}
# Mostly explicit speaker lines?
elsif ($nSpeaker/$nTotal >= 0.8)
	{
	if ($nExpCont/$nPossCont < 0.2) { $result = 1; }
	else { $result = 0; }
	}
elsif ($nExpCont/$nPossCont < 0.05) { $result = 1; }
# warn "ProbablyUsesImplicitContinuations returning: $result\n";
return $result;
}

##################################################################
########################## ExpandImplicitContinuations #########################
##################################################################
# NOTE: This should be called AFTER action item processing, so that "ACTION"
# is already at the beginning of the line: 
#	<scribe> ACTION DONE: ...
# instead of:
#	<scribe> DONE ACTION: ...
# Some of the possibilities handled:
# 	<scribe> ACTION: ... 
# 	<scribe>Amy: Now is the time (typo: missing space)
# 	<scribe>  for all good men and women (explicit continuation)
# 	<scribe> Joe: Now is the time (new speaker)
# 	<scribe>  for all good men and women
# 	<scribe>  Mary: Now is the time (typo: extra space)
# 	<scribe>  for all good men and women (explicit continuation)
# 	<scribe> Frank: Now is the time (typo: extra space)
# 	<scribe> for all good men and women (IMPLICIT continuation)
#	<scribe> Scores were: (normal statement)
# 	<scribe>   Red: 4  (tabular data; continuation)
sub ExpandImplicitContinuations
{
die if @_ != 1;
my ($all) = @_;
my @lines = split(/\n/, $all);
my $inContinuation = 0;
for (my $i=0; $i<@lines; $i++)
	{
	# warn "LINE: $lines[$i]\n";
	# Skip blank lines:
	next if ($lines[$i] =~ m/\A\s*\Z/);
	# Skip lines not starting with <scribe>:
	next if ($lines[$i] !~ m/\A\<scribe\>(\s*)/i);
	# Line starts with <scribe>
	my $spaces = $1;
	my $rest = $';
	$spaces =~ s/\A ?\t/  \t/; # Initial tab forces continuation
	# Explicit continuation already:
	# 	<scribe> Amy: ... for all good men and women
	next if ($rest =~ m/\A\s*\.\./);
	# <scribe> ACTION: ...
	if ($rest =~ m/\AACTION\b/)
		{
		$inContinuation = 0;
		next;
		}
	# <scribe>   Red: 4
	# More than one extra blank?  
	if ($inContinuation && length($spaces) > 2)
		{
		# Must be continuation of formatted text (such as a table).
		# Do nothing, because leading blank already means continuation.
		# (Though $spaces may have changed slightly if there was a tab.)
		$lines[$i] = "<scribe>$spaces$rest";
		next;
		}
	# 	<scribe> Amy: Now is the time
	# 	<scribe> ACTION: ...
	if ($rest =~ m/\A([a-zA-Z0-9\-_\.]+)( ?):/)
		{
		# Not a continuation line.  Either new speaker or stop word.
		my $speaker = $1;
		my $newRest = $';
		$lines[$i] = "<scribe> $speaker\:$newRest";
		# New speaker starts a statement.
		# Stop word is a non-speaker, and thus terminates 
		# a continuing statement.
		my $lcSpeaker = &LC($speaker);
		$inStatement = $lcSpeaker eq "chair" 
				|| $lcSpeaker eq "scribe"
				|| !exists($stopList{$lcSpeaker});
		next;
		}
	# Exactly one extra blank?  
	# <scribe>  for all good men and women
	next if (length($spaces) == 2); # Already a continuation line
	# Otherwise it's a continuation if we're $inStatement
	if ($inStatement)
		{
		# <scribe> for all good men and women
		# Implicit continuation line!  Add leading blank:
		# warn "Reformatting implicit continuation line: <scribe>  $rest\n";
		$lines[$i] = "<scribe>  $rest";
		}
	}
$all = "\n" . join("\n", @lines) . "\n";
return($all);
}

##################################################################
##################### GetTemplate ####################
##################################################################
sub GetTemplate
{
@_ == 1 || die;
my ($templateFile) = @_;
open($templateFile,"<$templateFile") || return "";
my $template = join("",<$templateFile>);
$template =~ s/\r//g;
close($templateFile);
return $template;
}

##################################################################
######################## GetDate ####################
##################################################################
# Grab date from $all or IRC log name or default to today's date.
sub GetDate
{
@_ == 3 || die;
my ($all, $namePattern, $logURL) = @_;
my @days = qw(Sun Mon Tue Wed Thu Fri Sat); 
@days == 7 || die;
my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@months == 12 || die;
my %monthNumbers = map {($months[$_], $_+1)} (0 .. 11);
# warn "GetDate monthNumbers: ",join(" ",%monthNumbers),"\n";
my @date = ();
# Look for Date: 12 Sep 2002
if ($all =~ s/\n\<$namePattern\>\s*(Date)\s*\:\s*(.*)\n/\n/i)
	{
	# Parse date from input.
	# I should have used a library function for this, but I wrote
	# this without net access, so I couldn't get one.
	my $d = &Trim($4);
	warn "Found Date: $d\n";
	my @words = split(/\s+/, $d);
	die "ERROR: Date not understood: $d\n" if @words != 3;
	my ($mday, $tmon, $year) = @words;
	exists($monthNumbers{$tmon}) || die;
	my $mon = $monthNumbers{$tmon};
	($mon > 0 && $mon < 13) || die;
	($mday > 0 && $mday < 32) || die;
	($year > 2000 && $year < 2100) || die;
	my $day0 = sprintf("%0d", $mday);
	my $mon0 = sprintf("%0d", $mon);
	@date = ($day0, $mon0, $year, $tmon);
	}
# Figure out date from IRC log name:
elsif ($logURL =~ m/\Ahttp\:\/\/(www\.)?w3\.org\/(\d+)\/(\d+)\/(\d+).+\-irc/)
	{
	my $year = $2;
	my $mon = $3;
	my $mday = $4;
	($mon > 0 && $mon < 13) || die;
	($year > 2000 && $year < 2100) || die;
	($mday > 0 && $mday < 32) || die;
	my $day0 = sprintf("%0d", $mday);
	my $mon0 = sprintf("%0d", $mon);
	@date = ($day0, $mon0, $year, $months[$mon-1]);
	warn "Got date from IRC log name: $day0 " . $months[$mon-1] . " $year\n";
	}
else
	{
	warn "\nWARNING: No date found!  Assuming today.  (Hint: Specify\n";
	warn "the IRC log, and the date will be determined from that.)\n";
	warn "Or specify the date like this:\n";
	warn "<dbooth> Date: 12 Sep 2002\n\n";
	# Assume today's date by default.
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$mon++;	# put in range [1..12] instead of [0..11].
	($mon > 0 && $mon < 13) || die;
	$year += 1900;
	($year > 2000 && $year < 2100) || die;
	($mday > 0 && $mday < 32) || die;
	my $day0 = sprintf("%0d", $mday);
	my $mon0 = sprintf("%0d", $mon);
	@date = ($day0, $mon0, $year, $months[$mon-1]);
	}
# warn "GetDate Returning date info: @date\n";
return @date;
}



##################################################################
###################### GetPresentOnPhone ######################
##################################################################
# Look for people in IRC log.
sub GetPresentOnPhone
{
@_ == 1 || die;
my($all) = @_;

my %synonyms = ();
%synonyms = qw(
	alan-home	Alan
	amymtg		Amy
	caribou		Carine
        Chaals		Charles
        chaalsGVA	Charles
        chaalsNCE	Charles
	Dave		DaveRaggett
	DaveR		DaveRaggett
	DaveRagget	DaveRaggett
	dbooth		dbooth
	David		dbooth
	DB		dbooth
	DavidB		dbooth
        danbri		DanBri
	danc_		DanC
	danc		DanC
	dand		DanielD
	EM		EricM
	Eric		EricM
	ericP-WA	EricP
	ericP-air	EricP
	ger		Gerald
	HT		Henry
	HH		Hugo
	hugo		Hugo
	ivan		Ivan
	janSeaTac	Janet
	karl		Karl
	reagle-tu	JosephR
	reagleMIT	JosephR
	Joseph		JosephR
	judy		Judy
	MaxF		MaxF
	MCF		Marie-Claire
	MC		Marie-Claire
	marie		Marie-Claire
	mari		Marisol
	MSM		MichaelSM
	MSMbot		MichaelSM
	Michael		MichaelSM
	MJDuesrst	Martin
	olivier		Olivier
	plh		Philippe
	plh-sjc		Philippe
	Ralph		RalphS
	rigo		Rigo
	sandro		Sandro
	sim		Simon
	simHOME		Simon
	Hernandez	Simon
	SB		Steve
	SusanL		SusanLesch
	Ted		Ted
	Tim		TimBL
	VQ		VincentQ
	) if $useTeamSynonyms;
foreach my $n (values %synonyms)
	{
	$synonyms{$n} = $n;	# Make TimBL --> TimBL
	}

# Easier pattern matching:
$all = "\n" . $all . "\n";

# Now start collecting names.
my %names =  ();
my $t; # Temp

# 	  ...something.html Simon's two minutes
$t = $all;
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
# warn "namePattern: $namePattern\n";
while($t =~ s/\b($namePattern)\'s\s+(2|two)\s+ minutes/ /)
	{
	my $n = $1;
	$names{$n} = $n;
	}

#	<dbooth> MC: I have integrated most of the coments i received 
$t = $all;
while($t =~ s/\n\<((\w|\-)+)\>(\ +)((\w|\-)+)\:/\n/i)
	{
	my $n = $4;
	next if exists($names{$n});
	# warn "Matched #	<dbooth> $n" . ": ...\n";
	$names{$n} = $n;
	}
# warn "names: ",join(" ",keys %names),"\n";

#	<Steven> Hello 
$t = $all;
while($t =~ s/\n\<((\w|\-)+)\>/\n/)
	{
	my $n = $1;
	next if exists($names{$n});
	# warn "Matched #	<$n>\n";
	$names{$n} = $n;
	# warn "Found name: $n\n";
	}

#	Zakim sees 4 items remaining on the agenda
$t = $all;
while ($t =~ s/\n\s*((\<Zakim\>)|(\*\s*Zakim\s)).*\b(agenda|agendum)\b.*\n/\n/)
	{
	my $match = &Trim($&);
	# warn "DELETED: $match\n";
	}

#	<Zakim> I see no one on the speaker queue
#	<Zakim> I see Hugo, Yves, Philippe on the speaker queue
#	<Zakim> I see MIT308, Ivan, Marie-Claire, Steven, Janet, EricM
#	<Zakim> On the phone I see Joseph, m3mSEA, MIT308, Marja
#	<Zakim> On IRC I see Nobu, SusanL, RRSAgent, ht, Ian, ericP
#	<Zakim> ... simonMIT, XachBot
#	<Zakim> I see MIT308, Ivan, Marie-Claire, Steven, Janet, EricM
#	<Zakim> MIT308 has Martin, Ted, Ralph, Alan, EricP, Vivien
#	<Zakim> +Carine, Yves, Hugo; got it
#
# Delete "on the speaker queue" from the ends of the lines,
# to prevent those words being mistaken for names.
while($t =~ s/(\n\<Zakim\>\s+.*)on\s+the\s+speaker\s+queue\s*\n/$1\n/)
        {
        warn "Deleted 'on the speaker queue'\n";
        }
# Collect names
while($t =~ s/\n\<Zakim\>\s+((([\w\d\_][\w\d\_\-]+) has\s+)|(I see\s+)|(On the phone I see\s+)|(On IRC I see\s+)|(\.\.\.\s+)|(\+))(.*)\n/\n/)
	{
	my $list = &Trim($9);
	my @names = split(/[^\w\-]+/, $list);
	@names = map {&Trim($_)} @names;
	@names = grep {$_} @names;
	# warn "Matched #       <Zakim> I see: @names\n";
	foreach my $n (@names)
		{
		next if exists($names{$n});
		$names{$n} = $n;
		}
	}

# Make the keys all lower case, so that they'll match:
%synonyms = map {my $oldn = $_; tr/A-Z/a-z/; ($_, $synonyms{$oldn})} keys %synonyms;
%names = map {my $oldn = $_; tr/A-Z/a-z/; ($_, $names{$oldn})} keys %names;
# warn "Lower case name keys:\n";
foreach my $n (sort keys %names)
	{
	# warn "	$n	$names{$n}\n";
	}

# Map synonyms to standardize spellings and expand abbreviations.
%names = map 	{
		exists($synonyms{$_}) 
			? ($_, $synonyms{$_}) 
			: ($_, $names{$_})
		} keys %names;
# At this point different keys may map to the same value.
# warn "After applying synonyms:\n";
foreach my $n (keys %names)
	{
	# warn "	$n	$names{$n}\n";
	}

# Eliminate non-names
foreach my $n (keys %names)
	{
	# Filter out names in stopList
	if (exists($stopList{$n})) { delete $names{$n}; }
	# Filter out names less than two chars in length:
	elsif (length($n) < 2) { delete $names{$n}; }
	# Filter out names not starting with a letter
	elsif ($names{$n} !~ m/\A[a-zA-Z]/) { delete $names{$n}; }
	# Filter out "scribe" and "chair"
	elsif ($n =~ m/\Ascribe\Z/) { delete $names{$n}; }
	elsif ($n =~ m/\Achair\Z/) { delete $names{$n}; }
	}

# Make a list of unique names for the attendee list:
my %uniqNames = ();
foreach my $n (values %names)
	{
	$uniqNames{$n} = $n;
	}

# Make a list of all names seen (all variations) in lower case:
my %allNames = ();
foreach my $n (%names, %synonyms)
	{
	my $name = $n;
	$name =~ tr/A-Z/a-z/;
	$allNames{$name} = $name;
	}
@allNames = sort keys %allNames;
# warn "allNames: @allNames\n";
my @allNameRefs = map { \$_ } @allNames;

# Canonicalize the names in the IRC:
my $expandedIRC = $all;
my $nExpanded = 0;
foreach my $n (keys %synonyms)
	{
	next if !$canonicalizeNames;
	my $v = $synonyms{$n};
	next if $v eq $n;
	my $qn = quotemeta($n);
	if ($expandedIRC =~ s/([^\w\-])($qn)([^\w\-])/$1$v$3/ig)
		{
		$nExpanded++;
		# warn "============ START ============\n";
		# warn "	$expandedIRC\n";
		# warn "============ STOP ============\n";
		}
	}
# warn "nExpanded: $nExpanded\n";

my $lcScribe = $scribe;
$lcScribe =~ tr/A-Z/a-z/;
$scribe = $synonyms{$lcScribe} if exists($synonyms{$lcScribe});
my @sortedUniqNames = sort values %uniqNames;
return($expandedIRC, $scribe, \@allNameRefs, @sortedUniqNames);
}

##################################################################
###################### GetNames ######################
##################################################################
# Look for people in IRC log.
sub GetNames
{
@_ == 2 || die;
my($all, $scribe) = @_;

# Some important data/constants:
my @rooms = qw(MIT308 SophiaSofa DISA);

my @stopList = qw(a q on Re items Zakim Topic muted and agenda Regrets http the
	RRSAgent Loggy Zakim2 ACTION Chair Meeting DONE PENDING WITHDRAWN
	Scribe 00AM 00PM P IRC Topics Keio DROPPED ger-logger
	yes no abstain Consensus Participants Question RESOLVED strategy
	AGREED Date queue no one in XachBot got it WARNING Present Agenda);
@stopList = (@stopList, @rooms);
@stopList = map {tr/A-Z/a-z/; $_} @stopList;	# Make stopList lower case
my %stopList = map {($_,$_)} @stopList;

my %synonyms = ();
%synonyms = qw(
	alan-home	Alan
	amymtg		Amy
	caribou		Carine
        Chaals		Charles
        chaalsGVA	Charles
        chaalsNCE	Charles
	Dave		DaveRaggett
	DaveR		DaveRaggett
	DaveRagget	DaveRaggett
	dbooth		dbooth
	David		dbooth
	DB		dbooth
	DavidB		dbooth
        danbri		DanBri
	danc_		DanC
	danc		DanC
	dand		DanielD
	EM		EricM
	Eric		EricM
	ericP-WA	EricP
	ericP-air	EricP
	ger		Gerald
	HT		Henry
	HH		Hugo
	hugo		Hugo
	ivan		Ivan
	janSeaTac	Janet
	karl		Karl
	reagle-tu	JosephR
	reagleMIT	JosephR
	Joseph		JosephR
	judy		Judy
	MaxF		MaxF
	MCF		Marie-Claire
	MC		Marie-Claire
	marie		Marie-Claire
	mari		Marisol
	MSM		MichaelSM
	MSMbot		MichaelSM
	Michael		MichaelSM
	MJDuesrst	Martin
	olivier		Olivier
	plh		Philippe
	plh-sjc		Philippe
	Ralph		RalphS
	rigo		Rigo
	sandro		Sandro
	sim		Simon
	simHOME		Simon
	Hernandez	Simon
	SB		Steve
	SusanL		SusanLesch
	Ted		Ted
	Tim		TimBL
	VQ		VincentQ
	) if $useTeamSynonyms;
foreach my $n (values %synonyms)
	{
	$synonyms{$n} = $n;	# Make TimBL --> TimBL
	}

# Easier pattern matching:
$all = "\n" . $all . "\n";

# Now start collecting names.
my %names =  ();
my $t; # Temp

# 	  ...something.html Simon's two minutes
$t = $all;
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
# warn "namePattern: $namePattern\n";
while($t =~ s/\b($namePattern)\'s\s+(2|two)\s+ minutes/ /)
	{
	my $n = $1;
	$names{$n} = $n;
	}

#	<dbooth> MC: I have integrated most of the coments i received 
$t = $all;
while($t =~ s/\n\<((\w|\-)+)\>(\ +)((\w|\-)+)\:/\n/i)
	{
	my $n = $4;
	next if exists($names{$n});
	# warn "Matched #	<dbooth> $n" . ": ...\n";
	$names{$n} = $n;
	}
# warn "names: ",join(" ",keys %names),"\n";

#	<Steven> Hello 
$t = $all;
while($t =~ s/\n\<((\w|\-)+)\>/\n/)
	{
	my $n = $1;
	next if exists($names{$n});
	# warn "Matched #	<$n>\n";
	$names{$n} = $n;
	# warn "Found name: $n\n";
	}

#	Zakim sees 4 items remaining on the agenda
$t = $all;
while ($t =~ s/\n\s*((\<Zakim\>)|(\*\s*Zakim\s)).*\b(agenda|agendum)\b.*\n/\n/)
	{
	my $match = &Trim($&);
	$match =~ &Trim($match);
	# warn "DELETED: $match\n";
	}

#	<Zakim> I see no one on the speaker queue
#	<Zakim> I see Hugo, Yves, Philippe on the speaker queue
#	<Zakim> I see MIT308, Ivan, Marie-Claire, Steven, Janet, EricM
#	<Zakim> On the phone I see Joseph, m3mSEA, MIT308, Marja
#	<Zakim> On IRC I see Nobu, SusanL, RRSAgent, ht, Ian, ericP
#	<Zakim> ... simonMIT, XachBot
#	<Zakim> I see MIT308, Ivan, Marie-Claire, Steven, Janet, EricM
#	<Zakim> MIT308 has Martin, Ted, Ralph, Alan, EricP, Vivien
#	<Zakim> +Carine, Yves, Hugo; got it
#
# Delete "on the speaker queue" from the ends of the lines,
# to prevent those words being mistaken for names.
while($t =~ s/(\n\<Zakim\>\s+.*)on\s+the\s+speaker\s+queue\s*\n/$1\n/)
        {
        warn "Deleted 'on the speaker queue'\n";
        }
# Collect names
while($t =~ s/\n\<Zakim\>\s+((([\w\d\_][\w\d\_\-]+) has\s+)|(I see\s+)|(On the phone I see\s+)|(On IRC I see\s+)|(\.\.\.\s+)|(\+))(.*)\n/\n/)
	{
	my $list = &Trim($9);
	my @names = split(/[^\w\-]+/, $list);
	@names = map {&Trim($_)} @names;
	@names = grep {$_} @names;
	# warn "Matched #       <Zakim> I see: @names\n";
	foreach my $n (@names)
		{
		next if exists($names{$n});
		$names{$n} = $n;
		}
	}

# Make the keys all lower case, so that they'll match:
%synonyms = map {my $oldn = $_; tr/A-Z/a-z/; ($_, $synonyms{$oldn})} keys %synonyms;
%names = map {my $oldn = $_; tr/A-Z/a-z/; ($_, $names{$oldn})} keys %names;
# warn "Lower case name keys:\n";
foreach my $n (sort keys %names)
	{
	# warn "	$n	$names{$n}\n";
	}

# Map synonyms to standardize spellings and expand abbreviations.
%names = map 	{
		exists($synonyms{$_}) 
			? ($_, $synonyms{$_}) 
			: ($_, $names{$_})
		} keys %names;
# At this point different keys may map to the same value.
# warn "After applying synonyms:\n";
foreach my $n (keys %names)
	{
	# warn "	$n	$names{$n}\n";
	}

# Eliminate non-names
foreach my $n (keys %names)
	{
	# Filter out names in stopList
	if (exists($stopList{$n})) { delete $names{$n}; }
	# Filter out names less than two chars in length:
	elsif (length($n) < 2) { delete $names{$n}; }
	# Filter out names not starting with a letter
	elsif ($names{$n} !~ m/\A[a-zA-Z]/) { delete $names{$n}; }
	}

# Make a list of unique names for the attendee list:
my %uniqNames = ();
foreach my $n (values %names)
	{
	$uniqNames{$n} = $n;
	}

# Make a list of all names seen (all variations) in lower case:
my %allNames = ();
foreach my $n (%names, %synonyms)
	{
	my $name = $n;
	$name =~ tr/A-Z/a-z/;
	$allNames{$name} = $name;
	}
@allNames = sort keys %allNames;
# warn "allNames: @allNames\n";
my @allNameRefs = map { \$_ } @allNames;

# Canonicalize the names in the IRC:
my $expandedIRC = $all;
my $nExpanded = 0;
foreach my $n (keys %synonyms)
	{
	next if !$canonicalizeNames;
	my $v = $synonyms{$n};
	next if $v eq $n;
	my $qn = quotemeta($n);
	if ($expandedIRC =~ s/([^\w\-])($qn)([^\w\-])/$1$v$3/ig)
		{
		$nExpanded++;
		# warn "============ START ============\n";
		# warn "	$expandedIRC\n";
		# warn "============ STOP ============\n";
		}
	}
# warn "nExpanded: $nExpanded\n";

my $lcScribe = &LC($scribe);
$scribe = $synonyms{$lcScribe} if exists($synonyms{$lcScribe});
my @sortedUniqNames = sort values %uniqNames;
return($expandedIRC, $scribe, \@allNameRefs, @sortedUniqNames);
}

##################################################################
################ LC ####################
##################################################################
# Lower Case.  Return a lower case version of the given string.
sub LC
{
@_ == 1 || die;
my ($s) = @_;
$s =~ tr/A-Z/a-z/;
return $s;
}

##################################################################
################ Trim ####################
##################################################################
# Trim leading and trailing blanks from the given string.
sub Trim
{
@_ == 1 || die;
my ($s) = @_;
$s =~ s/\A\s+//;
$s =~ s/\s+\Z//;
return $s;
}

##################################################################
################ DefaultTemplate ####################
##################################################################
sub DefaultTemplate
{
return &PublicTemplate();
}

##################################################################
####################### SampleInput ##############################
##################################################################
sub SampleInput
{
my $sampleInput = <<'SampleInput-EOF'
<dbooth> Scribe: dbooth
<dbooth> Chair: Jonathan
<dbooth> Meeting: Weekly Baking Club Meeting
<hugo> Agenda: http//www.example.com/agendas/2002-12-05-agenda.html
<dbooth> Date: 05 Dec 2002
<dbooth> Topic: Review of Action Items
<Philippe> PENDING ACTION: Barbara to bake 3 pies 
<Philippe> ----
<Philippe> DONE ACTION: David to make ice cream 
<Philippe> ACTION: David to make frosting -- DONE
<Philippe> ACTION: David to make candles  *DONE*
<Philippe> ACTION: David to make world peace  *PENDING*
<dbooth> Topic: What to Eat for Dessert
<dbooth> Joseph: I think that we should all eat cake
<dbooth> ... with ice creme.
<dbooth> s/creme/cream/
<Philippe> That's a good idea
<dbooth> ACTION: dbooth to send a message to himself about action items
<dbooth> Topic: Next Week's Meeting
<Philippe> I think we should do this again next week.
<Jonathan> Sounds good to me.
<dbooth> rrsagent, where am i?
<RRSAgent> I am logging.
<RRSAgent> See http://www.w3.org/2002/11/07-ws-arch-irc#T13-59-36
SampleInput-EOF
;
return $sampleInput;
}

##################################################################
###################### PublicTemplate ############################
##################################################################
sub PublicTemplate
{
my $template = <<'PublicTemplate-EOF'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
  <title>SV_MEETING_TITLE -- SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</title>
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/base.css">
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/public.css">
  <meta content="SV_MEETING_TITLE" lang="en" name="Title">  
  <meta content="text/html; charset=iso-8859-1" http-equiv="Content-Type">
</head>

<body>
<p><a href="http://www.w3.org/"><img src="http://www.w3.org/Icons/WWW/w3c_home" alt="W3C" border="0"
height="48" width="72"></a> 

</p>

<h1>SV_MEETING_TITLE<br>
SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</h1>

SV_FORMATTED_AGENDA_LINK

SV_FORMATTED_IRC_URL

<h2><a name="attendees">Attendees</a></h2>

<div class="intro">
<p>Present: SV_PRESENT_ATTENDEES</p>
<p>Regrets: SV_REGRETS</p>
<p>Chair: SV_MEETING_CHAIR </p>
<p>Scribe: SV_MEETING_SCRIBE</p>
</div>

<h2>Contents</h2>
<ul>
  <li><a href="#agenda">Topics</a>
	<ol>
	SV_MEETING_AGENDA
	</ol>
  </li>
  <li><a href="#ActionSummary">Summary of Action Items</a></li>
</ul>
<hr>

SV_AGENDA_BODIES

<h2><a name="ActionSummary">Summary of Action Items</a></h2>
<!-- Action Items -->
SV_ACTION_ITEMS

<hr>

<address>
  Minutes formatted by David Booth's 
  <a href="http://dev.w3.org/cvsweb/~checkout~/2002/scribe/scribe.perl">scribe.perl SCRIBEPERL_VERSION</a> (<a href="http://dev.w3.org/cvsweb/2002/scribe/scribe.perl">CVS log</a>)<br>
  $Date$ 
</address>
</body>
</html>
PublicTemplate-EOF
;
return $template;
}

##################################################################
###################### MemberTemplate ############################
##################################################################
sub MemberTemplate
{
my $template = <<'MemberTemplate-EOF'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
  <title>SV_MEETING_TITLE -- SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</title>
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/base.css">
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/member.css">
  <link rel="STYLESHEET" href="http://www.w3.org/StyleSheets/member-minutes.css">
  <meta content="SV_MEETING_TITLE" lang="en" name="Title">  
  <meta content="text/html; charset=iso-8859-1" http-equiv="Content-Type">
</head>

<body>
<p><a href="http://www.w3.org/"><img src="http://www.w3.org/Icons/WWW/w3c_home" alt="W3C" border="0"
height="48" width="72"></a> 
</p>

<h1>SV_MEETING_TITLE<br>
SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</h1>

SV_FORMATTED_AGENDA_LINK

SV_FORMATTED_IRC_URL

<h2><a name="attendees">Attendees</a></h2>

<div class="intro">
<p>Present: SV_PRESENT_ATTENDEES</p>
<p>Regrets: SV_REGRETS</p>
<p>Chair: SV_MEETING_CHAIR </p>
<p>Scribe: SV_MEETING_SCRIBE</p>
</div>

<h2>Contents</h2>
<ul>
  <li><a href="#agenda">Topics</a>
	<ol>
	SV_MEETING_AGENDA
	</ol>
  </li>
  <li><a href="#ActionSummary">Summary of Action Items</a></li>
</ul>
<hr>

SV_AGENDA_BODIES

<h2><a name="ActionSummary">Summary of Action Items</a></h2>
<!-- New Action Items -->
SV_ACTION_ITEMS

<hr>

<address>
  Minutes formatted by David Booth's 
  <a href="http://dev.w3.org/cvsweb/~checkout~/2002/scribe/scribe.perl">scribe.perl SCRIBEPERL_VERSION</a> (<a href="http://dev.w3.org/cvsweb/2002/scribe/scribe.perl">CVS log</a>)<br>
  $Date$ 
</address>
</body>
</html>
MemberTemplate-EOF
;
return $template;
}

##################################################################
###################### TeamTemplate ############################
##################################################################
sub TeamTemplate
{
my $template = <<'TeamTemplate-EOF'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
  <title>SV_MEETING_TITLE -- SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</title>
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/base.css">
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/team.css">
  <link rel="STYLESHEET" href="http://www.w3.org/StyleSheets/team-minutes.css">
  <meta content="SV_MEETING_TITLE" lang="en" name="Title">  
  <meta content="text/html; charset=iso-8859-1" http-equiv="Content-Type">
</head>

<body>
<p><a href="http://www.w3.org/"><img src="http://www.w3.org/Icons/WWW/w3c_home" alt="W3C" border="0"
height="48" width="72"></a> 

</p>

<h1>SV_MEETING_TITLE<br>
SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</h1>

SV_FORMATTED_AGENDA_LINK

SV_FORMATTED_IRC_URL

<h2><a name="attendees">Attendees</a></h2>

<div class="intro">
<p>Present: SV_PRESENT_ATTENDEES</p>
<p>Regrets: SV_REGRETS</p>
<p>Chair: SV_MEETING_CHAIR </p>
<p>Scribe: SV_MEETING_SCRIBE</p>
</div>

<h2>Contents</h2>
<ul>
  <li><a href="#agenda">Topics</a>
	<ol>
	SV_MEETING_AGENDA
	</ol>
  </li>
  <li><a href="#ActionSummary">Summary of Action Items</a></li>
</ul>
<hr>


SV_AGENDA_BODIES

<h2><a name="ActionSummary">Summary of Action Items</a></h2>
<!-- New Action Items -->
SV_ACTION_ITEMS

<hr>

<address>
  Minutes formatted by David Booth's 
  <a href="http://dev.w3.org/cvsweb/~checkout~/2002/scribe/scribe.perl">scribe.perl SCRIBEPERL_VERSION</a> (<a href="http://dev.w3.org/cvsweb/2002/scribe/scribe.perl">CVS log</a>)<br>
  $Date$ 
</address>
</body>
</html>
TeamTemplate-EOF
;
return $template;
}

##################################################################
###################### MITTemplate ############################
##################################################################
sub MITTemplate
{
my $template = <<'MITTemplate-EOF'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
  <title>SV_MEETING_TITLE -- SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</title>
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/base.css">
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/team.css">
  <link rel="STYLESHEET" href="http://www.w3.org/StyleSheets/team-minutes.css">
  <meta content="SV_MEETING_TITLE" lang="en" name="Title">  
  <meta content="text/html; charset=iso-8859-1" http-equiv="Content-Type">
</head>

<body>
<p><a href="http://www.w3.org/"><img src="http://www.w3.org/Icons/WWW/w3c_home" alt="W3C" border="0"
height="48" width="72"></a> <a href="http://www.w3.org/Team"><img width="48" height="48"
alt="W3C Team home" border="0" src="http://www.w3.org/Icons/WWW/team"></a> | <a
href="http://www.w3.org/Team/Meeting/MIT-scribes">MIT Meetings</a> | <a href="http://www.w3.org/">SV_MEETING_MONTH_ALPHA
SV_MEETING_YEAR</a></p>

<h1>SV_MEETING_TITLE<br>
SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</h1>

SV_FORMATTED_AGENDA_LINK

SV_FORMATTED_IRC_URL

<h2><a name="attendees">Attendees</a></h2>

<div class="intro">
<p>Present: SV_PRESENT_ATTENDEES</p>
<p>Regrets: SV_REGRETS</p>
<p>Chair: SV_MEETING_CHAIR </p>
<p>Scribe: SV_MEETING_SCRIBE</p>
</div>

<h2>Contents</h2>
<ul>
  <li><a href="#agenda">Topics</a>
	<ol>
	SV_MEETING_AGENDA
	</ol>
  </li>
  <li><a href="#ActionSummary">Summary of Action Items</a></li>
</ul>
<hr>


SV_AGENDA_BODIES


<h2><a name="ActionSummary">Summary of Action Items</a></h2>
<!-- Action Items -->
SV_ACTION_ITEMS

<hr>

<address>
  Minutes formatted by David Booth's 
  <a href="http://dev.w3.org/cvsweb/~checkout~/2002/scribe/scribe.perl">scribe.perl SCRIBEPERL_VERSION</a> (<a href="http://dev.w3.org/cvsweb/2002/scribe/scribe.perl">CVS log</a>)<br>
  $Date$ 
</address>
</body>
</html>
MITTemplate-EOF
;
return $template;
}


