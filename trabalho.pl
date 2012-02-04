use strict;
use Bio::Perl;
use Bio::Seq;
use Bio::SeqIO;
use Bio::Species;
use strict;
use warnings;
use DBI();
use DBD::mysql;

my ($Row,$SQL,$Select);

#------------------------DATABASE CONNECTION ON JOAO'S PC!-----------------------------
#my $dbh = DBI->connect('dbi:mysql:alg','root','blabla1') or die "Connection Error: $DBI::errstr\n";

#------------------------DATABASE CONNECTION ON VITOR'S PC!----------------------------
my $dbh = DBI->connect('dbi:mysql:alg','root','5D311NC8') or die "Connection Error: $DBI::errstr\n";

#------------------------DATABASE CONNECTION ON JOSE'S PC!----------------------------
#my $dbh = DBI->connect('dbi:mysql:alg','root','') or die "Connection Error: $DBI::errstr\n";

#TODO: Quando a interface estiver terminada, meter na opcao "sair" o close da connection à base de dados

insertion();

sub insertion {
    my $option = interface("ask_insertion_type");
    if ($option == 1) {         #TODO: ver se faz sentido perguntar tanta coisa
        #----------Asks user for useful information---------------
        my $authority = interface("ask_authority");
        my $alphabet = interface("ask_alphabet");
        my $description = interface("ask_description");
        my $gene_name = interface("ask_gene_name");
        my $date = interface("ask_date");
        my $is_circular = interface("ask_is_circular");
        my @keywords = interface("ask_keywords");
        my $sequence = interface("ask_sequence");
        my $seq_version = interface("ask_seq_version");
        my $specie = interface("ask_specie");
        my $format = interface("ask_format");
        my $seq_length = length($sequence);
        
        #print "\n\nAQUI ESTAO AS RESPOSTAS DADAS:\nalphabet: $alphabet\nauthority: $authority\ndesc: $description\ngene name: $gene_name\ndate: $date\ncircular: $is_circular\nkeywords: ";
        #for my $key (@keywords){
        #    print "$key, ";
        #}
        #print"\nsequence: $sequence\nseq_version: $seq_version\nformat: $format\n";#species: ".$species->species;
        
        #my $seq_obj = Bio::Seq->new(-seq => $sequence, -alphabet => $alphabet, -authority => $authority, -desc => $description, -display_id => $id, -get_dates => @dates, -is_circular => $is_circular, -keywords => @keywords, -seq_version => $seq_version);#, -species => $species);
        #my $seqio_obj = Bio::SeqIO->new(-file => '>sequence.gb', -format => 'genbank' );
        #$seqio_obj->write_seq($seq_obj);
        
        insert_specie($specie);
        insert_sequence($specie, $alphabet, $authority, $description, $gene_name, $date, $is_circular, $seq_length, $format, $seq_version, "gene_name");
        insert_tags(@keywords);
    }
    elsif ($option == 2) {
        #----------Gets useful information from the file or asks to user if the file doesn't have it---------------
        my $path = interface("ask_file_path");
        my $seqio = Bio::SeqIO->new(-file => $path);                 #TODO: meter um try catch aqui, para ver se o ficheiro existe ou nao!!!!!!
        my $format ;
        if ((substr ($path, -5)) eq "fasta") {$format = "fasta";}
        elsif ((substr ($path, -5)) eq "swiss") {$format = "swiss";}
        elsif ((substr ($path, -2)) eq "gb") {$format = "genbank";}
        else {$format = interface("ask_format");}
        my $seq = $seqio->next_seq;
        my $alphabet = interface("ask_alphabet");                       #Asks the alphabet
        my $authority = $seq->authority;
        my $description = $seq->desc;
        my $accession_number = $seq->display_id;                     #This method returns the gene name
        my $is_circular;
        if ($seq->is_circular) {$is_circular = 1;}
        else {$is_circular = 0;}
        my @keywords = interface("ask_keywords");
        my $sequence = $seq->seq;
        my $seq_version;
        my $date;
        if($format eq "genbank" or $format eq "swiss"){
            $seq_version = $seq->seq_version;
            $date= ($seq->get_dates)[0];
        }
        else{
            $seq_version = interface("ask_seq_version");
            $date= interface("ask_date");
        }
        my $specie = interface("ask_specie");               #Just to ask if the user wants to associate the sequence to any specie
        my $seq_length = $seq->length;
        
        #print "\n\nAQUI ESTAO AS RESPOSTAS DADAS:\nalphabet: $alphabet\nauthority: $authority\ndesc: $description\ngene name: $gene_name\ndate: $date\ncircular: $is_circular\nkeywords: ";
        #for my $key (@keywords){
        #    print "$key, ";
        #}
        #print"\nsequence: $sequence\nseq_version: $seq_version\nformat: $format\nspecies: $specie\n";
        insert_specie($specie);
        insert_sequence($specie, $alphabet, $authority, $description, $accession_number, $date, $is_circular, $seq_length, $format, $seq_version, "accession_number");
        insert_tags(@keywords);
        
        
        #
        #
        #
        #
        #
        #       TODO PARA SABADO: VER DMDOPEN (http://perldoc.perl.org/functions/dbmopen.html) E COMECAR A GUARDAR SEQUENCIAS!!!!!!!!!!!!
        #
        #
        #
        #
        #
        
        
    }
}


#-----------------Verifies if the inserted specie already exists on database. If it already exists, doesn't try to insert it---------------
sub insert_specie{
    my ($specie) = @_;
    my ($row, $id_sequence);
    my $sql = "SELECT id_specie FROM species WHERE specie='".$specie."'";
    my $result = $dbh->prepare($sql);
    $result->execute();
    if(!($result->fetchrow_hashref())){
        $sql = "INSERT INTO species (specie) VALUES ('".$specie."')";
        $dbh->do($sql);
    }
}


#-------------------Insert the sequence----------------------
        #Ineficiente porque faz o mesmo select 2 vezes, mas assim funciona... Deve ser porque nao pode fazer o fecthrow 2 vezes seguidas,
        #por isso tive de voltar a fazer o select...
        
        #The last argument tells if it has the accession number (insertion from a file or from a remote DB) or the gene name (manual insertion)
sub insert_sequence{
    my ($specie, $alphabet, $authority, $description, $gene_name_or_accession_number, $date, $is_circular, $seq_length, $format, $seq_version, $type) = @_;
    my $sql = "SELECT id_specie FROM species WHERE specie='".$specie."'";
    my $result = $dbh->prepare($sql);
    $result->execute();
    while(my $row = $result->fetchrow_hashref()){
        if ($type eq "gene_name") {
            $sql = "INSERT INTO sequences (id_specie, alphabet, authority, description, gene_name, date, is_circular, length, format, seq_version)"
            ."VALUES ('".$row->{'id_specie'}."', '".$alphabet."', '".$authority."', '".$description."', '".$gene_name_or_accession_number."', '".$date."', '"
            .$is_circular."', '$seq_length', '".$format."', '".$seq_version."')";
        }
        elsif ($type eq "accession_number"){
            $sql = "INSERT INTO sequences (id_specie, alphabet, authority, description, accession_number, date, is_circular, length, format, seq_version)"
            ."VALUES ('".$row->{'id_specie'}."', '".$alphabet."', '".$authority."', '".$description."', '".$gene_name_or_accession_number."', '".$date."', '"
            .$is_circular."', '$seq_length', '".$format."', '".$seq_version."')";
        }
        $dbh->do($sql);
    }
}

#-------------------Insert the tags------------------------------
sub insert_tags{
    my (@keywords) = @_;
    my $id_sequence;
    my $sql = "SELECT LAST_INSERT_ID()";
    my $result = $dbh->prepare($sql);
    $result->execute();
    while (my $row = $result->fetchrow_hashref()){
        $id_sequence = $row->{'LAST_INSERT_ID()'};
    }
    
    for my $keyword (@keywords){
        #-------------Verifies if the inserted tags already exist on database. If they already exist, doesn't try to insert them-----------
        $sql = "SELECT id_tag FROM tags WHERE tag='".$keyword."'";
        $result = $dbh->prepare($sql);
        $result->execute();
        if(!($result->fetchrow_hashref())){
            $sql = "INSERT INTO tags (tag) VALUES ('".$keyword."')";
            $dbh->do($sql);
        }
        
        $sql = "SELECT id_tag FROM tags WHERE tag='".$keyword."'";
        $result = $dbh->prepare($sql);
        $result->execute();
        
        #--------------Insert the tuple id_sequence - id_tag on seq_tags table------------------------
        while(my $row = $result->fetchrow_hashref()){
            $sql = "INSERT INTO seq_tags (id_sequence, id_tag) VALUES ('".$id_sequence."', '".$row->{'id_tag'}."')";
            my $result2 = $dbh->do($sql);
            if($result2) {print ("A insercao foi executada com sucesso\n");}
            else {print ("Ocorreu um erro na insercao\n");}
        }
    }
}


#------------------This function will have ALL the interface things-------------------
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
    elsif($type eq "ask_authority"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Insert the authority: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_alphabet"){
        print "Insert the alphabet: ";
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
    elsif($type eq "ask_gene_name"){
        print "Insert the gene name: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_date"){
        print "Insert the date: ";
        $answer = <>;
        chomp $answer;
        return $answer;
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
        else{
            print "INVALID OPTION! Please choose a valid one! ";
            interface("ask_is_circular");
        }
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
    elsif($type eq "ask_specie"){
        print "Insert the specie: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_format"){
        print "Insert the format [fasta/genbank/swiss]: ";
        $answer = <>;
        chomp $answer;
        if ($answer eq "fasta" or $answer eq "genbank" or $answer eq "swiss") {
            return $answer;
        }
        else{
            print "FORMAT NOT SUPORTED! Please choose a suported one! ";
            interface("ask_format");
        }
    }
    elsif($type eq "ask_file_path"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Insert the file path: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
}













