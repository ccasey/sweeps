#!/usr/local/bin/perl

# sweeps logging program
# - dupes
# - scoring
# - cabrillo v2 output

use Term::ReadLine;
$term = new Term::ReadLine 'vrpsweeps';

%qsos = ();

$mycall = "n0vrp";
$myprec = "m";
$mysec = "ks";
$mycheck = 93;

$last_freq = 0;
$totqso = 0;
$LOGFILE = "sweeps.dat";
$CABFILE = "sweeps.cab";
$last_checked;
$last_qso;

%mults = ( ct => 0, ema => 0, me => 0, nh => 0, ri => 0, vt => 0, wma => 0,
            eny => 0, nli =>0 , nnj => 0, nny => 0, snj => 0, wny => 0,
	    de => 0, epa => 0, mdc => 0, wpa => 0,
	    al => 0, ga => 0, ky => 0, nc => 0, nfl => 0, sc => 0, sfl => 0, tn => 0, va => 0, pr => 0, vi => 0, wcf => 0, 
	    ar => 0, la => 0, ms => 0, nm => 0, ntx => 0, ok => 0, stx => 0, wtx => 0, 
	    eb => 0, lax => 0, org => 0, sb => 0, scv => 0, sdg => 0, sf => 0, sjv => 0, sv => 0, pac => 0, 
	    az => 0, ewa => 0, id => 0, mt => 0, nv => 0, or => 0, ut => 0, wwa => 0, wwa => 0, wy => 0, ak => 0, 
	    mi => 0, oh => 0, wv => 0, 
	    il => 0, in => 0, wi => 0, 
	    co => 0, ia => 0, ks => 0, mn => 0, mo => 0, ne => 0, nd => 0, sd => 0, 
	    mar => 0, nl => 0, qc => 0, on => 0, mb => 0, sk => 0, ab => 0, bc => 0, nt => 0
	  );


##########

sub logit {

 my $logln = shift(@_);
 
 open(FH,">>$LOGFILE")
  or die "cant open $LOGFILE: $!\n";
  
 print FH $logln;
 
 close(FH);
 
}

sub prompt {

 return score() . "/$totqso > ";

}


sub loadlog {

 if( -e $LOGFILE ){
  open(LL,"<$LOGFILE")
   or die "cant open $LOGFILE: $!\n";
 }  
  while(<LL>){
   chomp;
   my @foo = split; 
   
   if($foo[0] =~ /del/){
    if($mults{$qsos{$foo[1]}{section}}){
     $mults{$qsos{$foo[1]}{section}}--;
    }
    delete($qsos{$foo[1]});
   }else{
    $qsos{$foo[4]} = { sserial => $foo[1], rserial => $foo[2], precedence => $foo[3], check => $foo[5],
                       section => $foo[6], qsotime => $foo[7], freq => $foo[8]};
    $mults{$foo[6]}++;		       
    $totqso = $foo[1];
    $last_qso = $foo[4];
   }
  }
  
  close(LL);

}

sub printlog {

 my @bar;
 
 foreach (keys %qsos){ 
  $bar[$qsos{$_}{sserial}] = "$qsos{$_}{sserial} - $qsos{$_}{rserial} $qsos{$_}{precedence} $_ $qsos{$_}{check} $qsos{$_}{section} $qsos{$_}{qsotime} $qsos{$_}{freq} \n";
 }

 foreach (@bar){
  print;
 }
}

sub score {

 my $m;
 
 foreach (keys %mults){
  if ($mults{$_}){
   $m += 1;
  }
  #print $m . "\n";
 }
 
 return ($m * ($totqso*2));
 
}

sub sections_left {
 
 my $lc = 0;
 
 foreach $s (keys %mults){
  unless($mults{$s}) {
   print "$s ";
   $lc++;
   if($lc > 10){
    $lc = 0;
    print"\n";
   }
  }
 }
 print "\n";
}

sub cabrillo {
 foreach (keys %qsos){ 
   $bar[$qsos{$_}{sserial}] = "$_";
 }
 open(CAB, ">$CABFILE")
  or die "no cabfile workie: $!";
  
 foreach $call (@bar){
 unless($call){next;}
  my @ta = localtime(($qsos{$call}{qsotime} + 21600));
  my $cd = ($ta[5] + 1900) . "-" . ($ta[4]+1) . "-$ta[3]";
  my $ct = "$ta[2]$ta[1]";
  
  printf CAB ("QSO: %5s PH %10s %02s%02s %-10s %4s %s %s %3s %-10s %4s %s %s %s\n", 
  $qsos{$call}{freq},$cd,$ta[2],$ta[1],"N0VRP",$qsos{$call}{sserial},"A","93","KS ",uc($call),$qsos{$call}{rserial},uc($qsos{$call}{precedence}),$qsos{$call}{check},uc($qsos{$call}{section}));
 
 
 }
 
 close(CAB);

}
 
##########

loadlog();

prompt();



while(defined ($_ = $term->readline(prompt()))){

  if( $_ eq "q" ){
   exit;
  }
  
  if( /^p/ ){
   printlog();
  }
  
  if( /^cs/ ){
   sections_left();
  }
  
  if( /^cab/ ){
   cabrillo();
  }
  
  if ( /^c / ){
    $last_checked = (split)[1];
    if (defined($qsos{(split)[1]}) ){
     print "DUPE\n";
     undef($last_checked);
    }else{
     print "good\n";
    }
   next;
  }
  
  if ( /^f / ){
   $last_freq = (split)[1];
   next;
  }
  
  if ( /^s/ ){
   print score() . "\n";
   next;
  }
  
  if ( /^dl/ ){
   if($last_qso){
    if(exists($qsos{$last_qso})){
     $mults{$qsos{$last_qso}{section}}--;
     delete($qsos{$last_qso});
     logit("del $last_qso\n");
     $totqso--;
     print "$last_qso deleted\n";
     $last_qso = "";
    }else{
     print "** $last_qso not in log, madness **\n";
    }
   }else{
    print "*** already deleted last, or dont have anything to delete ***\n";
   }
  }
  
  if ( /^n/ ){
   
    $sserial = ($totqso + 1);
    print "\t\tsend: $sserial $myprec $mycall $mycheck $mysec\n";
    
    my $qsotime = time();
    
    print "recv serial: ";
    my $rserial = <>;
    chomp($rserial);
    
    print "recv precedence: ";
    my $rprec = <>;
    chomp($rprec);
    
    print "recv call ($last_checked): ";
    my $rcall = <>;
    chomp($rcall);
    unless($rcall){
     $rcall = $last_checked;
    }
    undef $last_checked;
    if (defined($qsos{$rcall})){
     print "DUPE\n";
     next;
    }
    
    print "recv check: ";
    my $rcheck = <>;
    chomp($rcheck);
    
    print "recv section: ";
   while(TRUE){
     $rsection = <>;
     chomp($rsection);
    unless($rsection){
     last;
    }
    if (exists($mults{$rsection})){
      $mults{$rsection}++;
      last;
     }else{
      foreach (keys %mults){
       print "$_ ";
      }
      print "\n";
      print "bzzt! try again $rsection $mults{$rsection}: ";
     }
    }
    
    print "freq($last_freq): ";
    my $new_freq = <>;
    chomp($new_freq);
    $last_freq = $new_freq if ($new_freq);
    my $rfreq = $last_freq;
    
    unless($rfreq && $rcall && $rcall && $rserial && $rprec && $rsection){
     print "skipping...\n";
     next;
    }
    
  
    $totqso++;
  
    
   $last_qso = $rcall;
   logit("add $totqso $rserial $rprec $rcall $rcheck $rsection $qsotime $rfreq\n");
   $qsos{$rcall} = { sserial => $totqso, rserial => $rserial, precedence => $rprec, check => $rcheck,
                       section => $rsection, freq => $rfreq, qsotime => $qsotime};
  }
  
  
}
   
