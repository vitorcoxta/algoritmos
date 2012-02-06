use strict;
use Bio::DB::GenBank;
use Bio::DB::SwissProt;
use Bio::DB::RefSeq;
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


#DATABASE CONNECTION ON JOAO'S PC!
my $dbh = DBI->connect('dbi:mysql:alg','root','blabla1') or die "Connection Error: $DBI::errstr\n";
my %dbm_seq;
dbmopen(%dbm_seq, '/home/johnnovo/Documents/sequence', 0666);

#DATABASE CONNECTION ON VITOR'S PC!
#my $dbh = DBI->connect('dbi:mysql:alg','root','5D311NC8') or die "Connection Error: $DBI::errstr\n";

importation();


sub importation {
    
#print "\n".$dbm_seq{10}."\n";   
    
    my $option;    

    $option = interface("ask_database");   # Escolher a Base de Dados
       
    if ($option ==1 or $option ==2 or $option ==3) { interface("generic_importation_begin",$option); generic_importation($option); }    # Escolheu :     GENBANK    

        else {print "\t\n\nBioinformatics - \"Fetch the Sequence!\" \n\n Thank you for using our software! \n Have a nice day! :) \n\n\nPROPS PO PESSOAL!!!XD"};  
    
}    
             
         
sub generic_importation{
    
        my($base)=@_;
        my ($option2,$formato,$seq,$existe,$option,$gb,$seqio_obj,$result,$sql,$specie,$id_specie,$id_sequence,$id_tag);         
         
         if ($base==2) {$option=1;}
                    else {$option = interface ("ask_import"); }  ## Escolher tipo de importação - "Acession Number ou Version Number"
        
        $formato = interface ("ask_format");  ## Escolher Fasta ou Genbank
        
        ### CICLO PARA PROCURAR    
        
        $existe=1;
        
        if ($base==1) {
            $gb = Bio::DB::GenBank->new();} ## Iniciar ligação ao Genbank
        
            elsif ($base==2) {$gb=Bio::DB::SwissProt->new();}
            
                else {$gb=Bio::DB::RefSeq->new();}
        
        do {
        
            if (!$existe)  {print "ERROR: Already existing Accession Number in DataBase!!\n\n";<>;}     
            if ($existe==2) {print "ERROR : Non existing Number in Remote DataBase!!\n\n";<>;}
        
        ##### Inserir Number para procura
                if ($option==1) {
                                        
                                        $option2=interface("ask_accession_number");                                        
                                        chomp($option2); 
                                        $existe = verifica_accession($option2);             #Verifica de o accesion number já existe na Base de Dados                                                
                                        
                                         if ($existe==1) {   
                                                try {   
                                                        
                                                        $seq = $gb->get_Seq_by_acc($option2) || throw Bio::Root::Exception(print "ERRO:INVALID NUMBER!!");
                                                 
                                                }catch Bio::Root::Exception with {$existe=2};    
                                        }         
                }
                    
                elsif ($option==2) {
                        
                                        $option2=interface("ask_version_number");                                        
                                        chomp($option2); 
                                        $existe = verifica_version_number($option2);             #Verifica de o accesion number já existe na Base de Dados                                        
                                                              
                                        if($existe==1){
                                            try { 
                
                                                        $seq = $gb->get_Seq_by_version($option2) || throw Bio::Root::Exception(print "ERRO:INVALID NUMBER!!") # Vai buscar o number 
                                                        
                                                }catch Bio::Root::Exception with {$existe=2};  
                                        }
                }
                
        }while(!$existe or $existe==2);
                     
    
        $specie = interface("ask_specie");   #pede especie e de seguida grava
        $id_specie=insert_specie_importation($specie);
     
         $id_sequence = insert_sequence_importation($formato,$id_specie,$seq);
     
         $id_tag = interface("ask_tag"); #pergunta se quer tag, se quiser pode escolher uma das que já há, ou uma nova.
         
         if ($id_tag){insert_relation($id_sequence,$id_tag);}
     
         print "INSERCAO FEITA COM SUCESSO!!\n\n\n"; 
     
     
     
     ### Tipo de Ficheiro para Gravar###########################################
     
$gb = Bio::DB::GenBank->new(-retrievaltype => 'tempfile' , -format => 'Fasta');     
     
                        if ($formato==1) {$seqio_obj = Bio::SeqIO->new(-file => '>sequence.fasta', -format => 'fasta' ); }
                        
                        elsif($formato==2) {$seqio_obj = Bio::SeqIO->new(-file => '>sequence.gb', -format => 'genbank' );}                        
                        
                        else {$seqio_obj = Bio::SeqIO->new(-file => '>sequence.swiss', -format => 'swiss' );}
           
    ########################################################################
            
        $seqio_obj->write_seq($seq);
        
        print "---",$seq->length,"CENAS!!";
                
    }
       
  
      
      
#########################  FUNCOES DE VERIFICAÇAOOOOOOOOOO #####################################      
      
  
  
  
       
sub verifica_accession{   #### Verifica se o Accession  number já existe na Base de Dados -----------   Se sim, retorna 0,  senao retorna 1
    
            my ($type) = @_;     
            my ($sql,$result);
            
            $sql = "SELECT accession_number FROM sequences WHERE accession_number='".$type."'";
            $result = $dbh->prepare($sql);
            $result->execute();
            if(($result->fetchrow_hashref())){
                        
                        return 0;}
    return 1;
}
        
        
        
sub verifica_version_number{   #### Verifica se o Version number já existe na Base de Dados -----------   Se sim, retorna 0,  senao retorna 1
    
            my ($type) = @_;     
            my ($sql,$result);
            
            $sql = "SELECT seq_version FROM sequences WHERE seq_version='".$type."'";
            $result = $dbh->prepare($sql);
            $result->execute();
            
            if(($result->fetchrow_hashref())){
                        
                        return 0; }
            
    return 1;
}


#-----------------Verifies if the inserted specie already exists on database. If it already exists, doesn't try to insert it---------------
sub insert_specie_importation{
    my ($specie) = @_;
    my @val;
    my $sql = "SELECT id_specie FROM species WHERE specie='".$specie."';";    
    my $sql1;    
    my $result2;
    my $result = $dbh->prepare($sql);
    $result->execute();
    
    if(!(@val=$result->fetchrow_array())){
   
            $sql1 = "INSERT INTO species (specie) VALUES ('".$specie."');";   ## INSERÇÃO
            $dbh->do($sql1);

            $result2 = $dbh->prepare($sql);  ## SELECT DO ID DA ESPECIE INSERIDA
            $result2->execute();
        
            @val = $result2->fetchrow_array();
        }
           
        return $val[0];
}


sub insert_sequence_importation {
        
         my ($formato,$id_specie,$seq)=@_;
         my ($sql,$form);        
         my  $result;
         my @val;
        
        if ($formato==1) {$form="fasta";}
        elsif ($formato==2){$form ="genbank";}
        else {$form="swiss";}
        
        $sql = "INSERT INTO sequences (id_specie, alphabet, authority, description, accession_number, gene_name, date, is_circular, length, format, seq_version)
                       VALUES ('".$id_specie."', '".$seq->alphabet."', '".$seq->authority."', '".$seq->desc."', '".$seq->accession."', '".$seq->display_name."', '".$seq->get_dates."', '".$seq->is_circular."', '".$seq->length."', '".$form."', '".$seq->seq_version."');";
                       
        $dbh->do($sql);  ## INSERCAO NA BASE DADOS;
        $sql = "SELECT id_sequence FROM sequences WHERE accession_number='".$seq->accession."';";
        $result = $dbh->prepare($sql);  ## SELECT DO ID DA ESPECIE INSERIDA
        $result->execute();
    
        @val = $result->fetchrow_array(); ## SELECT DO ID DA SEQUENCIA INSERIADA
        
        #$dbm_seq{$val[0]} = $seq;        
  
    return $val[0] ;  
}

sub display_tags(){
    
    my ($result,$sql,@val,%n_tags);

    $sql = "Select * from tags";    
    
    print "\tTAG's TABLE\n\n";
    
    $result = $dbh->prepare($sql);
    $result->execute();
    
    while(@val=$result->fetchrow_array()){
    
        print "   ID = $val[0] \t TAG = $val[1]\n";
        $n_tags{$val[0]}=$val[1];
    }

    print "\n";
    return %n_tags;
}

sub insert_tag{
    
    my ($new_tag)=@_;
    my (@val,$sql,$result);
    
    $sql = "INSERT INTO tags (tag) VALUES ('".$new_tag."');"; ## Inserir Nova tag
    $dbh->do($sql);
    
    $sql = "SELECT id_tag FROM tags WHERE tag='".$new_tag."';";  ## Retorna o id da nova tag
    $result = $dbh->prepare($sql);
    $result->execute();    
    
    @val=$result->fetchrow_array();
    
    return $val[0];
}

sub insert_relation{
    
    my ($id_seq,$id_tag)=@_;
    
    print "----------------$id_seq,$id_tag-----------------";
    
    my $sql = "INSERT INTO seq_tags (id_sequence,id_tag) VALUES ('".$id_seq."','".$id_tag."');";
    
    $dbh->do($sql);
    
    }







 ################################ INTERFACE ######################################
    

sub interface {
    
    my $var=0;
    my ($type,$bank) = @_;
    my ($option, $answer,$flag,$size);
    my %id_tags;
    
    if ($type eq "ask_database"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Which database you want to use to import: \n 1-Genbank\n 2-Swissprot \n 3-RefSeq\n\n E-Go back and Exit\n\n";    
        do{     
        print "Answer: ";
        $option = <>;
        
        if ($option == 1 or $option == 2 or $option == 3 or $option eq 'E' or $option eq 'e') {return $option;}
        else {print "\nERROR: INVALID OPTION! Please select one of the given options!\n";}    
    
        } while(1);     
    }
    
  ############## GENBANK  

    if ($type eq "generic_importation_begin"){
        
         system $^O eq 'MSWin32' ? 'cls' : 'clear';
        if ($bank==1) {print "Welcome to the GenBank Importation Interface!!\n"; }
          if($bank==2) {print "Welcome to the SwissProt Importation Interface!!\n";}
            else {print "Welcome to the RefSeq Importation Interface!!\n";}
    }
    
    
    if ($type eq "ask_import"){
        ##system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "\n\nSelect the way you want to import:\n 1-Accession Number\n 2-Accession Version\n\n9-Go back\n\n";    
        do{     
        print "Answer: ";
        $option = <>;
        
        if ($option == 1 or $option == 2 or $option eq 'b') {return $option;}
        else {print "\nERROR: INVALID OPTION! Please select one of the given options!\n";}    
    
        } while(1);     
    
    }
    
    if ($type eq "ask_format"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Select the format of the importation:\n 1-fasta\n 2-genbank\n 3-swissprot\n";    
        do{     
            print "Answer: ";
            $option = <>;
            
            if ($option == 1 or $option == 2 or $option==3 or $option eq 9) {return $option;}
            else {print "\nERROR: INVALID OPTION! Please select one of the given options!\n";}    

        } while(1);     
    }
    
           if ($type eq "ask_accession_number"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Please insert the Accession Number: \n";    
        print "Answer: ";
        $option = <>;
        return $option;
    
    }
    
    
           if ($type eq "ask_version_number"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Please insert the Accession Version Number: \n";    
        print "Answer: ";
        $option = <>;
        return $option;
    
    }
    
    elsif($type eq "ask_specie"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Insert the specie: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }    
    
    elsif($type eq "ask_tag"){
        
      
        system $^O eq 'MSWin32' ? 'cls' : 'clear';      
        
        my $flag;
        do{

            $flag=1;
            print "Do you want to add a tag  to the sequence?\n 1- Yes, i do.\n 2- No, i don't.\n\nAnswer: ";
        
            $answer = <>;
            chomp $answer;
            if ($answer!=1 and $answer!=2) {$flag=0;}

            }while(!$flag);   
        
        if ($answer==2) {return 0;} ## DONT WANT TO ADD TAG
        
         system $^O eq 'MSWin32' ? 'cls' : 'clear'; 
         %id_tags=display_tags();
        
        do{        
        $flag =1;       
         print "Do you want to use an existing Tag from the table or add a new one?\n 1- Existing Tag\n 2- New Tag\n\nAnswer: ";
         $answer = <>;
         chomp $answer;
        if ($answer!=1 and $answer!=2) {$flag=0;}
        }while(!$flag) ; 
        
        my $resp;
        
        if($answer==1){                           ##Escolheu opção de usar tag existente
            $flag =1;           
            print "\nChoose the ID of the tag you want to use.\n";
            
            do{
                if(!$flag) {print "\nERROR: Non existing ID!\n"}                      #inseriu numero errado de tag
                $flag=1;                            
                print "Answer: "; 
    
                $resp = <>;
                chomp $resp;
                
                if(!(exists($id_tags{$resp}))) { $flag=0; }   # vê se a tag que inseriram é válida
                else {return $resp};
            }while(!$flag);
        }
        
        print"\nInsert the new Tag:\nAnswer: ";
        my $ans = <>;
        chomp $ans;
        my @lista_keys = keys %id_tags;
     
        for my $x (@lista_keys){  # vê se value que o utilizador introduziu já se encontra na tabela
            if ($id_tags{$x} eq $ans){ return $x;}
        }
       return insert_tag($ans);
    }
}

