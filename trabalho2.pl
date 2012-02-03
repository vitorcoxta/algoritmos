use strict;
use Bio::DB::GenBank;
use Bio::Perl;
use Bio::Seq;
use Bio::SeqIO;
use Bio::Species;
use strict;
use warnings;
use DBI();
use DBD::mysql;

use Bio::Root::Exception;
use Error qw(:try);


my ($Row,$SQL,$Select);

#DATABASE CONNECTION ON JOAO'S PC!
#my $dbh = DBI->connect('dbi:mysql:alg','root','blabla1') or die "Connection Error: $DBI::errstr\n";

#DATABASE CONNECTION ON VITOR'S PC!
my $dbh = DBI->connect('dbi:mysql:alg','root','5D311NC8') or die "Connection Error: $DBI::errstr\n";

importation();


sub importation {
    
    my ($option2,$formato,$seq);
    my $option = interface("ask_database");
    my $gb;
    my $seqio_obj; 
    my $result;
    my $sql;
    
    
    if ($option ==1) {
        
        $option = interface ("ask_genbank_import");
        
        $formato = interface ("ask_genbank_format");
        
        $gb = Bio::DB::GenBank->new();        
        
        
####################        
        
        if ($formato == 1) {$gb = Bio::DB::GenBank->new(-retrievaltype => 'tempfile' , 
                                              -format => 'Fasta');
                            
                            $seqio_obj = Bio::SeqIO->new(-file => '>sequence.fasta', -format => 'fasta' );
 
                            }
        
        else {$seqio_obj = Bio::SeqIO->new(-file => '>sequence.gb', -format => 'genbank' );}
        
        
   #####################3     
        
        do {
        
        if ($option==1) {$option2=interface("ask_gi_number");}
                elsif ($option==2) {$option2=interface("ask_accession_number");}
                    elsif ($option==3) {$option2=interface("ask_accession_version");}
        
        chomp($option2);        
        
        #Verifica de o accesion number já existe na Base de Dados
            
            $sql = "SELECT accession_number FROM sequences WHERE accession_number='".$option2."'";
            $result = $dbh->prepare($sql);
            $result->execute();
            if(($result->fetchrow_hashref())){
                
                print "ERROR: ALREADY EXISTING ACCESSION NUMBER!!\n";
                
            }
        
        
        
        if ($option==1) {$seq = $gb->get_Seq_by_gi($option2);} # GI Number 
        
        if ($option==2) {   
         
            
            try {
                
                $seq = $gb->get_Seq_by_acc($option2) || throw Bio::Root::Exception( 
                                                                   print "ERRO:INVALID NUMBER!!")
            
            }
            catch Bio::Root::Exception with {};
         
         
         $sql = "Insert accession_number FROM sequences WHERE accession_number='".$option2."'";
         
           
        }
        
        
        
        
        
        if ($option==3) {$seq = $gb->get_Seq_by_version($option2);} # Accession.version
                
            if(!$seq) {print "ERROR: WRONG NUMBER";}
            
        } while (!$seq);
        
        $seqio_obj->write_seq($seq);
        
        print "peidos peidos ---",$seq->length,"PEIDOS!!";
                
    }
    
    
    elsif ($option ==2) {
        print ("SELECIONASTE A 2");
        
    }
        
    
    elsif ($option ==3) {
        
        print ("SELECIONASTE A 3");
    }
    
    
    elsif ($option ==9) {
        
    system $^O eq 'MSWin32' ? 'cls' : 'clear';    
    print ("\t\n\nBioinformatics - \"Fetch the Sequence!\" \n\n Thank you for using our software! \n Have a nice day! :) \n\n\nPROPS PO PESSOAL!!!XD");
    
    }
    
    
    
    print ("\t\n\nBioinformatics - \"Fetch the Sequence!\" \n\n Thank you for using our software! \n Have a nice day! :) \n\n\nPROPS PO PESSOAL!!!XD");
    
    
    
}


sub interface {
    
    my $var=0;
    my ($type) = @_;
    my ($option, $answer);
    my @answer;
    if ($type eq "ask_database"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Which database you want to use to import: \n 1-Genbank\n 2-Swissprot \n 3-NCBI\n\n9-Go back and Exit\n\n";    
        do{     
        print "Answer: ";
        $option = <>;
        
        if ($option == 1 or $option == 2 or $option == 3 or $option == 9) {return $option;}
        else {print "\nERROR: INVALID OPTION! Please select one of the given options!\n";}    
    
        } while(1);     
    
    }
    
    
    if ($type eq "ask_genbank_import"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Select the way you want to import:\n 1-Gi number\n 2-Accession Number\n 3-Accession Version\n\n9-Go back\n\n";    
        do{     
        print "Answer: ";
        $option = <>;
        
        if ($option == 1 or $option == 2 or $option == 3 or $option == 9) {return $option;}
        else {print "\nERROR: INVALID OPTION! Please select one of the given options!\n";}    
    
        } while(1);     
    
    }
    
       if ($type eq "ask_genbank_format"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Select the format of the importation:\n 1-fasta\n 2-genbank\n";    
        do{     
        print "Answer: ";
        $option = <>;
        
        if ($option == 1 or $option == 2 or $option == 9) {return $option;}
        else {print "\nERROR: INVALID OPTION! Please select one of the given options!\n";}    
    
        } while(1);     
    
    }
    
           if ($type eq "ask_gi_number"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Please insert the Gi number: \n";    
        print "Answer: ";
        $option = <>;
        return $option;
    
    }
    
    
           if ($type eq "ask_accession_number"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Please insert the Accession Number: \n";    
        print "Answer: ";
        $option = <>;
        return $option;
    
    }
    
    
           if ($type eq "ask_accession_version"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Please insert the Accession Version: \n";    
        print "Answer: ";
        $option = <>;
        return $option;
    
    }
    
    
}

