
package ICOM_CIV;

BEGIN {
    use Exporter ();
    use POSIX;
    use IO::Select;
    use Fcntl;

    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    
    # set the version for version checking
    $VERSION     = 1.00;
    # if using RCS/CVS, this may be preferred
    $VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g;
    
    @ISA         = qw(Exporter);
    @EXPORT      = qw(&icom_civ_setup &icom_civ_getfreq);
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],
    
    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK   = qw( );
}
our @EXPORT_OK;


sub hexify {
    my $in = shift;
    my @crap = split(//, $in);
    
    while (defined ($f = shift(@crap))) {
	printf "0x%02x ", ord($f);
    }
}

sub icom_civ_setup {

    my $port = shift;

    open(S, "+<$port") or return undef;
    system "/bin/stty -f $port gfmt1:cflag=cb00:iflag=5:lflag=0:oflag=0:ispeed=9600:ospeed=9600";

    if ($? == -1) {
	warn "failed to execute: $!\n";
    } else {
	if (($? >> 8) != 0) {
	    printf "stty exited with value %d\n", $? >> 8;
	}
    }

    my $oldfh = select S;
    $| = 1;
    select $oldfh;

    return S;
}

# icom_civ_getfreq($socket, $rigaddr) 
# Returns frequency as G.MMM.KKK.HHH where G=GHz, M=MHz, K=kHz, H=Hz
# Rig address is typically 0x66 for IC-746PRO unless changed through config menus
sub icom_civ_getfreq {

    my $socket = shift;
    my $rigaddr = shift;
    my @rigdata = ();

    printf($socket "%c%c%c%c%c%c%c", 0xfe, 0xfe, $rigaddr, 0xe0, 0x03, 0xfd);
    
    eval {
	local $SIG{ALRM} = sub { die "timeout!" };
	
	# Wired-OR CI-V bus echos everything we send back to us. 
	# Can check for collision later if we don't get back what we sent
	alarm 1;
	read($socket, $input, 6);
	alarm 0;
	
	#print "Message to rig (hw echo): ";
	#hexify($input);
	#print "\n";
	
	# Horrible way to do this, but it works.
	#print "Message from rig: ";
	
	while (1) {
	    alarm 1;
	    read ($socket, $input, 1);
	    alarm 0;
	    
	    push @rigdata, $input;
	    
	    #hexify($input);
	}
    };
    
    #print "\n";
    
# Look for preamble
  LOOP:    
    while (defined(my $f = shift @rigdata)) {
	if (ord($f) == 0xfe) {
	    $f = shift @rigdata;
	    if (ord($f) == 0xfe) {
		#print "Got preamble...\n";
		my $toaddr = shift @rigdata;
		if (ord($toaddr) != 0xe0) {
		    print "A message on the bus not for us.\n";
		    next LOOP;
		}
		my $fromaddr = shift @rigdata;
		my $cmd = shift @rigdata;
		if (ord($cmd) == 0x03) {
		    my $f1 = shift @rigdata; # 10Hz, 1Hz
		    my $f2 = shift @rigdata; # 100Hz, 1kHz
		    my $f3 = shift @rigdata; # 100kHz, 10kHz
		    my $f4 = shift @rigdata; # 1MHz, 10MHz
		    my $f5 = shift @rigdata; # 1GHz, 100MHz
		    $freq = sprintf("%u.%u%u%u.%u%u%u.%u%u%u", 
				    (ord($f5) >> 4), (ord($f5) & 0x0f),
				    (ord($f4) >> 4), (ord($f4) & 0x0f),
				    (ord($f3) >> 4), (ord($f3) & 0x0f),
				    (ord($f2) >> 4), (ord($f2) & 0x0f),
				    (ord($f1) >> 4), (ord($f1) & 0x0f));
		    my $postamble = shift @rigdata;
		    if (ord($postamble) != 0xfd) {
			print "No postamble .. check data!\n";
		    }
		} else {
		    print "Something else -> cmd [" . ord($cmd) . "]\n";
		    return undef;
		}
	    } else {
		print "Error: corrupted preamble\n";
		return undef;
	    }
	} else {
	    #print "Skip 1 byte of junk\n";
	}
    }
    
    return $freq
}

# Always return true from modules
1;
