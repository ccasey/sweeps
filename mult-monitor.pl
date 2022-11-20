#!/usr/bin/env perl

sub loadlog {

 	if( -e $LOGFILE ){
  	open(LL,"<$LOGFILE")
   	or die "cant open $LOGFILE: $!\n";
 	}
  while(<LL>){
   	chomp;
   	my @foo = split;

   	if($foo[0] =~ /del/){
			delete($qsos{$foo[1]});
   	}else{
    	$qsos{$foo[4]} = { action => "add", sserial => $foo[1], rserial => $foo[2], precedence => $foo[3], check => $foo[5],
                      	section => $foo[6], qsotime => $foo[7], freq => $foo[8]};
      json_logit($foo[4]);
    	$last_qso = $foo[4];
    	$Freq = $foo[8];
   	}
  }

  close(LL);

}
