#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Getopt::Long;
my %opts = ();
use Scalar::Util qw(looks_like_number);
GetOptions(
  \%opts,
  "outdir=s",
  "nifxml=s",
  "nifattachxml=s",
  "game=s",
  "namespace=s",
  "highestuserversion=s",
  "highestuserversion2=s"
);
$opts{highestuserversion} = oct($opts{highestuserversion}) if defined $opts{highestuserversion};
$opts{highestuserversion} = 0 if !defined $opts{highestuserversion};
$opts{highestuserversion2} = oct($opts{highestuserversion2}) if defined $opts{highestuserversion2};
$opts{highestuserversion2} = 0 if !defined $opts{highestuserversion2};
use Data::Dumper;
$Data::Dumper::Indent = 1;
use XML::LibXML::Simple   qw(XMLin);
my $data = XMLin($opts{nifxml}, 
  ForceArray => [ "add" ],
  KeyAttr => { },
);
my $data_attach = XMLin($opts{nifattachxml},
  ForceArray => [ "read", "game" ],
  KeyAttr => { basic => "name", include_object => "name", game => "name" }
);
open(my $dump_fh, ">$opts{outdir}/$opts{nifxml}.dump") or die "Error: Couldn't open $opts{nifxml}.dump for writing: $!\n";
print $dump_fh Dumper $data;
close $dump_fh;

open(my $dump_attach_fh, ">$opts{outdir}/$opts{nifattachxml}.dump") or die "Error: Couldn't open $opts{nifattachxml}.dump for writing: $!\n";
print $dump_attach_fh Dumper $data_attach;
close $dump_attach_fh;

sub codeName {
  my($name, $nameDefined) = @_;
  return $name if looks_like_number($name);
  $name =~ s/\s+//g;
  $name =~ s/\W+//g;
  $name =~ s/::/_/g;
  $name =~ s/_+/_/g;
  my $return = (defined $nameDefined and defined $nameDefined->{$name}) ? ($name . $nameDefined->{$name}) : $name; 
  $nameDefined->{$name} = defined $nameDefined->{$name} ? ($nameDefined->{$name}+1) : 2 if defined $nameDefined;
  return "m".$return;
}

sub className {
  my($name) = @_;
  $name =~ s/\s+/_/g;
  $name =~ s/\W+/_/g;
  $name =~ s/::/_/g;
  return $name;
}

my %versionHash = ();
for my $ver(@{$data->{version}}){
  $versionHash{$ver->{num}} = 1 if ref($ver) eq 'HASH' and $ver->{content} =~ /$opts{game}/; 
}
my %extraVersionGameMap = (
  Morrowind => [
    "10.0.1.0"
  ]
);
if(defined $extraVersionGameMap{$opts{game}}){
  $versionHash{$_} = 1 for @{$extraVersionGameMap{$opts{game}}};
}
die "Error: no version matching game: $opts{game}!\n" if !scalar(keys %versionHash);
print "Versions for game: $opts{game} -> " . join(',',(keys %versionHash)) . "\n";

my $max_subversions = 4;
sub compareVersion {
  my($lhs,$rhs) = @_;
  my @lhs_parts = split('\.',$lhs);
  my @rhs_parts = split('\.',$rhs);
  my($lhs_int,$rhs_int) = (0,0);
  for my $i(0 .. $max_subversions-1){
    my $shift = ($max_subversions-1-$i)*8;
    $lhs_int |= (int($lhs_parts[$i]) << $shift) if defined $lhs_parts[$i];
    $rhs_int |= (int($rhs_parts[$i]) << $shift) if defined $rhs_parts[$i];
  }
  printf("Comparing version: $lhs(0x%x) to version: $rhs(0x%x)\n",$lhs_int,$rhs_int);
  return 1 if($lhs_int > $rhs_int);
  return -1 if($lhs_int < $rhs_int);
  return 0;
}
sub includedInVersion {
  my($add) = @_;
  my $included = 0;
  for my $ver(keys %versionHash){
    my $current_ver_passed = 1;
    # Check ver1 and ver2 conditions
    $current_ver_passed = 0 if defined $add->{ver1} and compareVersion($ver,$add->{ver1}) == -1;
    $current_ver_passed = 0 if defined $add->{ver2} and compareVersion($ver,$add->{ver2}) == 1;
    # Check vercond
    if(defined $add->{vercond}){
      my $verCondEval = $add->{vercond};
      $verCondEval =~ s/User Version 2/\$opts{highestuserversion2}/g;
      $verCondEval =~ s/User Version/\$opts{highestuserversion}/g;
      $verCondEval =~ s/Version\s*(\S)=\s*([\w|\.]+)/compareVersion(\$ver,"$2") $1= 0/g;
      $verCondEval =~ s/Version\s*(\S)\s*([\w|\.]+)/compareVersion(\$ver,"$2") $1 0/g;
      my $result = 0;
      $verCondEval = "\$result = ( $verCondEval ) ? 1 : 0;";
      eval $verCondEval;
      print "vercond " . ($result ? "passed" : "failed") . " for $add->{name} of type: $add->{type} after checking cond: $verCondEval\n" if !$result;
      $current_ver_passed = 0 if !$result;
    }
    $included = 1 if $current_ver_passed; 
  }
  return $included;
}


my %objectHash = ();
$objectHash{$_->{name}} = $_ for @{$data->{compound}};
$objectHash{$_->{name}} = $_ for @{$data->{niobject}};
our %objectUsed = ();
sub recurseOrderObjects {
  my($object,$objectHash,$objOrderArray,$objAccountedHash,$depth) = @_;
  # Return if we've already accounted for this object
  return if defined $objAccountedHash->{$object};
  # if this has inheritance that isn't accounted for, recurse on it
  if(defined $objectHash->{$object}{inherit}){
    print ' 'x($depth*2) . "Recursing on inherit object: $objectHash->{$object}{inherit}\n";
    recurseOrderObjects($objectHash->{$object}{inherit},$objectHash,$objOrderArray,$objAccountedHash,$depth+1);
  }
  # for each add, if the add exists as an object type, recurse it
  for my $add(@{$objectHash->{$object}{add}}){
    if(defined $objectHash->{$add->{type}}){
      next if $add->{type} eq 'UnionBV';
      if(&includedInVersion($add)){
        print ' 'x($depth*2) . "Adding object $add->{name} of type: $add->{type} owned by $object\n";
        $objectUsed{$add->{type}} = 1;
        print ' 'x($depth*2) . "Recursing on add object: $add->{type}\n";
        recurseOrderObjects($add->{type},$objectHash,$objOrderArray,$objAccountedHash,$depth+1);
      }else{
        print ' 'x($depth*2) . "Skipping object $add->{name} of type: $add->{type} owned by $object due to version incompatibility\n";
      }
    }
    #if(defined $add->{template} and defined $objectHash->{$add->{template}} and $add->{template} ne $object){
    #  print "Recursing on template member: $add->{template}\n";
    #  recurseOrderObjects($add->{template},$objectHash,$objOrderArray,$objAccountedHash);
    #}
  }
  $objAccountedHash->{$object} = 1;
  #print "Pushing object: $object\n";
  push(@{$objOrderArray},$object);  
}
#my @recordOrder = ();
#my %recordsAccountedFor = ();
#recurseOrderObjects($_,\%recordHash,\@recordOrder,\%recordsAccountedFor) for keys %recordHash;

my @objectOrder = ();
my %objectAccountedFor = ();
for(keys %objectHash){
  next if !defined $data_attach->{game}{$opts{game}}{include_object}{$_};
  print "Recursing on object: $_\n";
  recurseOrderObjects($_,\%objectHash,\@objectOrder,\%objectAccountedFor,1);
}
print "objectUsed: " . Dumper(\%objectUsed);

my %basicHash = ();
$basicHash{$_->{name}} = $_ for @{$data->{basic}};


sub computeType {
  my($element) = @_;
  if(defined $basicHash{$element->{type}}){
    if($element->{type} =~ /Ref|Ptr/){
      return "int"; #defined $element->{template} ? (className($element->{template}) . "*") : "void*";
    }
    return $basicHash{$element->{type}}{niflibtype};
  #}elsif(defined $recordHash{$element->{type}}){
  #  return className($element->{type});
  }elsif(defined $objectHash{$element->{type}}){
    return className($element->{type});
  }
  return undef;
}

#open (my $nifRecordHeaderFh, ">$opts{outdir}/nifrecord.hpp") or die "Error: Couldn't open nifrecord.hpp for writing: $!\n";
#open (my $nifRecordCppFh, ">$opts{outdir}/nifrecord.cpp") or die "Error: Couldn't open nifrecord.cpp for writing: $!\n";
open (my $nifObjectHeaderFh, ">$opts{outdir}/nifobject.hpp") or die "Error: Couldn't open nifobject.hpp for writing: $!\n";
open (my $nifObjectCppFh, ">$opts{outdir}/nifobject.cpp") or die "Error: Couldn't open nifobject.cpp for writing: $!\n";
#print $nifRecordHeaderFh "#ifndef __NIF_RECORD_HPP__\n#define __NIF_RECORD_HPP__\n";
#print $nifRecordHeaderFh "#include \"nifbasicobject.hpp\"\n";
#print $nifRecordHeaderFh "class NIFStream;\n";

# Forward declare all of the classes
for my $fh($nifObjectHeaderFh){
  #print $fh "class ".className($_).";\n" for sort keys %recordHash;
  print $fh "class ".className($_).";\n" for sort keys %objectHash;
}
#print $nifRecordCppFh "#include \"nifrecord.hpp\"\n";
print $nifObjectHeaderFh "#ifndef __NIF_OBJECT_HPP__\n#define __NIF_OBJECT_HPP__\n";
print $nifObjectHeaderFh "#include \"nifbasicobject.hpp\"\n";
print $nifObjectHeaderFh "#include \"components/nif/nifstream.hpp\"\n";
print $nifObjectHeaderFh "namespace $opts{namespace} { \n" if defined $opts{namespace};
#print $nifObjectHeaderFh "class NIFStream;\n";
print $nifObjectCppFh "#include \"nifobject.hpp\"\n";
print $nifObjectCppFh "#include \"components/nif/nifstream.hpp\"\n";
print $nifObjectCppFh "namespace $opts{namespace} { \n" if defined $opts{namespace};
for my $objectName(@objectOrder){
  next if $objectName eq 'NiObject';
  my %nameDefined = ();
  my %codeNames = ();
  $codeNames{$_->{name}} = codeName($_->{name},\%nameDefined) for @{$objectHash{$objectName}{add}};
  my $className = className($objectName);
  my $inheritName = undef;
  $inheritName = ($objectHash{$objectName}{inherit} ne 'NiObject') ? $objectHash{$objectName}{inherit} : 'NiObject' if defined $objectHash{$objectName}{inherit};
  print $nifObjectHeaderFh "class ${className}" . (defined $inheritName ? ": public $inheritName" : "") . " {
  public:
    ${className}();
    ~${className}();
    void read(Nif::NIFStream *nif);
  protected:\n";
  %nameDefined = ();
  for my $add(@{$objectHash{$objectName}{add}}){
    if(defined $basicHash{$add->{type}} or defined $objectHash{$add->{type}}){
      next if $add->{type} eq 'UnionBV';
      next if !&includedInVersion($add);
      print $nifObjectHeaderFh "    /* $add->{content} */\n" if defined $add->{content};
      print $nifObjectHeaderFh "    ".computeType($add).(defined $add->{arr1} ? "*" : "")." ".codeName($add->{name}, \%nameDefined).";\n";
    }
  }
  print $nifObjectHeaderFh "};\n\n";
  print $nifObjectCppFh  "${className}::${className}()" . (defined $inheritName ? " : $inheritName()" : ""). " { }\n";
  print $nifObjectCppFh  "${className}::~${className}() { }\n";
  print $nifObjectCppFh  "void ${className}::read(Nif::NIFStream *nif){\n";
  %nameDefined = ();
  for my $add(@{$objectHash{$objectName}{add}}){
    next if !&includedInVersion($add);
    my($codeName,$type) = (codeName($add->{name}, \%nameDefined), computeType($add));
    if(defined $basicHash{$add->{type}}){
      die "Error: basic attach information not defined for type: $add->{type}\n" if !defined $data_attach->{basic}{$add->{type}}{read};
      for my $read(@{$data_attach->{basic}{$add->{type}}{read}}){
        if($read->{type} eq 'assign' and &includedInVersion($add)){
          if(defined $add->{arr1}){
            my $numElements = defined $codeNames{$add->{arr1}} ? $codeNames{$add->{arr1}} : codeName($add->{arr1});
            print $nifObjectCppFh "  $codeName = new $type" . "[$numElements];\n";
            print $nifObjectCppFh "  for(int i = 0; i < $numElements; i++){\n";
            print $nifObjectCppFh "    $codeName" . "[i] = (" . computeType($add) . ") $read->{content};\n";
            print $nifObjectCppFh "  }\n";
          }else{
            print $nifObjectCppFh "  $codeName = (" . computeType($add) . ") $read->{content};\n";
          }
          last;
        }
      }
    }else{
#      if(defined $add->{arr1}){
#        my $numElements = defined $codeNames{$add->{arr1}} ? $codeNames{$add->{arr1}} : codeName($add->{arr1});
#        print $nifObjectCppFh "  $codeName = new $type" . "[$numElements];\n";
#        print $nifObjectCppFh "  for(int i = 0; i < $numElements; i++){\n";
#        print $nifObjectCppFh "    $codeName" . "[i] = new " . computeType($add) . "();\n";
#        print $nifObjectCppFh "    $codeName" . "[i]->read(nif);\n";
#        print $nifObjectCppFh "  }\n";
#      }else{
#        die "Error: Type undefined for $add->{name} of object: $objectName\n" if !defined computeType($add);
#        print $nifObjectCppFh "  $codeName = new " . computeType($add) . "();\n";
#        print $nifObjectCppFh "  $codeName" . "->read(nif);\n";
#      }
    }
  }
  print $nifObjectCppFh  "}\n";
}
print $nifObjectHeaderFh "} \n" if defined $opts{namespace};
print $nifObjectHeaderFh "#endif\n";
close($nifObjectHeaderFh);
print $nifObjectCppFh "} \n" if defined $opts{namespace};
close($nifObjectCppFh);

# Start with the header and make a record class for each sub type
#for my $recName(sort keys %recordHash){
#  print $nifRecordHeaderFh "class ${recName}Record : public Record {
#  public:
#    ${recName}Record();
#    ~${recName}Record();
#    void read(NIFStream *nif);
#  protected:\n";
#  my %nameDefined = ();
#  for my $add(@{$recordHash{$recName}{add}}){
#    if(defined $basicHash{$add->{type}} or defined $recordHash{$add->{type}} or defined $objectHash{$add->{type}}){
#      print $nifRecordHeaderFh "    ".computeType($add).(defined $add->{arr1} ? "*" : "")." ".codeName($add->{name}, \%nameDefined).";\n";
#    }
#  }
#  print $nifRecordHeaderFh "};\n\n";
#  print $nifRecordCppFh  "${recName}Record::${recName}Record() : Record() { }\n";
#  print $nifRecordCppFh  "void ${recName}Record::read(NIFStream *nif){\n";
#  print $nifRecordCppFh  "}\n";
#}
#print $nifRecordHeaderFh "#endif\n";
#close($nifRecordHeaderFh);
#close($nifRecordCppFh);
