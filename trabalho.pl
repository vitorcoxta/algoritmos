use strict;
use Bio::Perl;
use Bio::Seq;
use Bio::SeqIO;
use Bio::Species;
use strict;
use warnings;
use DBI;

my ($Row,$SQL,$Select);

#DATABASE CONNECTION ON JOAO'S PC!
#my $dbh = DBI->connect('dbi:mysql:alg','root','blabla1') or die "Connection Error: $DBI::errstr\n";

#DATABASE CONNECTION ON VITOR'S PC!
my $dbh = DBI->connect('dbi:mysql:alg','root','5D311NC8') or die "Connection Error: $DBI::errstr\n";



#$SQL = "insert into tags(tag) values(\'Day1\');";

#my $SQL2 = "Delete from tags where tag='Day1' or tag='cenas';";

#my $update = $dbh->do($SQL2);


#if($update) {print ("Correu bem!!\n");}
#else {print ("JA fostes!!!\n");}


# $SQL= "select * from Temporario";

#$Select = $dbh->prepare($SQL2);
#$Select->execute();

#while($Row=$Select->fetchrow_hashref)
#{
 # print "$Row->{Nome} $Row->{Idade}";
#}

insertion();

sub insertion {
    my $option = interface("ask_insertion_type");
    if ($option == 1) {         #TODO: ver se faz sentido perguntar tanta coisa (o que não está comentado. o que está acho que nao faz sentido) -> vitor
        #my $accession = interface("ask_accession");
        my $alphabet = interface("ask_alphabet");
        my $authority = interface("ask_authority");
        my $description = interface("ask_description");
        my $id = interface("ask_id");
        #my $division = interface("ask_division");
        my @dates = interface("ask_dates");         #ver se dá para meter uma funçao a retornar $ e/ou @
        #my @secondary_accessions = interface("ask_secondary_accessions");   #   .....//.....
        my $is_circular = interface("ask_is_circular");
        my @keywords = interface("ask_keywords");                           #   .....//.....
        #my $length = interface("ask_length");
        #my $molecule = interface("ask_molecule");
        #my $namespace = interface("ask_namespace");
        my $sequence = interface("ask_sequence");
        my $seq_version = interface("ask_seq_version");
        #my $species = Bio::Species->new(-classification => interface("ask_species"));          #TODO: ver isto das especies. sera que se pode meter tudo na tabela tags, e assim nao precisamos da tabela species???
        #my @species = interface ("ask_species");
        #print "\n\nAQUI ESTAO AS RESPOSTAS DADAS:\nalphabet: $alphabet\nauthority: $authority\ndesc: $description\nid: $id\ndates: ";
        #for my $date (@dates){
        #    print "$date, ";
        #}
        #print"\ncircular: $is_circular\nkeywords: ";
        #for my $key (@keywords){
        #    print "$key, ";
        #}
        #print"\nsequence: $sequence\nseq_version: $seq_version\nspecies: ";#.$species->species;
        #for my $specie (@species){
        #    print "$specie, ";
        #}
        my $seq_obj = Bio::Seq->new(-seq => $sequence, -alphabet => $alphabet, -authority => $authority, -desc => $description, -display_id => $id, -get_dates => @dates, -is_circular => $is_circular, -keywords => @keywords, -seq_version => $seq_version);#, -species => $species);
        my $seqio_obj = Bio::SeqIO->new(-file => '>sequence.gb', -format => 'genbank' );
        $seqio_obj->write_seq($seq_obj);
        print "\n\n\nCORREU TUDO BEM! :D\n\n\n";
    }
    elsif ($option == 2) {print "queres num ficheiro\n"}
}

#This function will have ALL the interface things
sub interface {
    my ($type) = @_;
    my ($option, $answer);
    my @answer;
    if ($type eq "ask_insertion_type"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Do you want to insert the sequence manually, or is the sequence on a file?\n1 - Manually\n2 - In a file\n3 - Go back\n"; #TODO: go back. in the mean time, it is considered an invalid option
        $option = <>;
        if ($option == 1 or $option == 2) {return $option;}
        else {interface("ask_insertion_type_invalid_option");}
    }
    elsif($type eq "ask_insertion_type_invalid_option"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "INVALID OPTION! Please choose a valid one!\n\nDo you want to insert the sequence manually, or is the sequence on a file?\n1 - Manually\n2 - In a file\n3 - Go back\n"; #TODO: go back. in the mean time, it is considered an invalid option
        $option = <>;
        if ($option == 1 or $option == 2) {return $option;}
        else {interface("ask_insertion_type_invalid_option");}
    }
    elsif($type eq "ask_alphabet"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Insert the alphabet: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_authority"){
        print "Insert the authority: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_description"){
        print "Insert the description: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_id"){
        print "Insert the identifier: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_dates"){
        print "Insert the dates (seperated by ','): ";
        $answer = <>;
        chomp $answer;
        @answer = split /\s*,\s*/, $answer;
        return @answer;
    }
    elsif($type eq "ask_is_circular"){
        print "Is it circular? [yes/no]: ";
        $answer = <>;
        chomp $answer;
        if ($answer eq "yes") {
            $answer = 1;
            return $answer;
        }
        elsif ($answer eq "no") {
            $answer = 0;
            return $answer;
        }
        else{interface("ask_is_circular_invalid_option")}
    }
    elsif($type eq "ask_is_circular_invalid_option"){
        print "INVALID OPTION! Please choose a valid one! Is it circular? [yes/no]: ";
        $answer = <>;
        chomp $answer;
        if ($answer eq "yes") {
            $answer = 1;
            return $answer;
        }
        elsif ($answer eq "no") {
            $answer = 0;
            return $answer;
        }
        else{interface("ask_is_circular_invalid_option");}
    }
    elsif($type eq "ask_keywords"){
        print "Insert the keywords (seperated by ','): ";
        $answer = <>;
        chomp $answer;
        @answer = split /\s*,\s*/, $answer;
        return @answer;
    }
    elsif($type eq "ask_sequence"){
        print "Insert the sequence: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_seq_version"){
        print "Insert the version of this sequence: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_species"){
        print "Insert the species (seperated by ','): ";
        $answer = <>;
        chomp $answer;
        @answer = split /\s*,\s*/, $answer;
        return @answer;
    }
}













