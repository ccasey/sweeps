#!/Users/csc/perl5/perlbrew/perls/perl-5.16.0/bin/perl

use English;
require Tk;
require Tk::Adjuster;
use Tk;

%mults = (
	A => "a",
	B => "b",
);

sub inline_validate_section {
	my $entry = uc(shift);
	print "$entry\n";
	if(defined($mults{$entry}) || !$entry){
		$Inputs{Section}->configure(-background => lightgrey);
		#$Inputs{Section}->update;
		$Telltale{Section}->configure(-text => "$mults{$entry}");
		#$Telltale{Section}->update();
	} else {
		$Inputs{Section}->configure(-background => red);
		#$Inputs{Section}->update();
		$Telltale{Section}->configure(-text => "nope");
		#$Telltale{Section}->update();
	}
	return 1;
}

 my $main = MainWindow->new();
 $main->geometry('400x100');

 # two frames and adjuster
 my $main_frame = $main->Frame; # right

  # pack frames
 $main_frame->pack(qw/-side right -fill both -expand l/);

 	$vn = "Section";

  $main_frame->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
	$Inputs{$vn} = $main_frame->Entry(-validate        => 'key',
					-validatecommand => [\&inline_validate_section],
					-textvariable => \$$vn)->pack(qw/-side left -padx 10 -pady 5 -fill x/);

  $Telltale{$vn} = $main_frame->Label(-text => "nope", -width => 25)->pack(qw/-side left/);

 MainLoop();
