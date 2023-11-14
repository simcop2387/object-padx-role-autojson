package Object::PadX::Role::AutoJSON;

use v5.38;

use Object::Pad ':experimental(custom_field_attr mop)';
use Object::Pad::MOP::FieldAttr;
use Object::Pad::MOP::Field;
use Object::Pad::MOP::Class;
use Syntax::Operator::Equ;

Object::Pad::MOP::FieldAttr->register( "JSONExclude", permit_hintkey => 'Object/PadX/Role/AutoJSON' );
# Set a new name when going to JSON
Object::Pad::MOP::FieldAttr->register( "JSONKey", permit_hintkey => 'Object/PadX/Role/AutoJSON' );
# Allow this to get sent as null, rather than leaving it off
Object::Pad::MOP::FieldAttr->register( "JSONNull", permit_hintkey => 'Object/PadX/Role/AutoJSON' );
# Force boolean or num or str
Object::Pad::MOP::FieldAttr->register( "JSONBool", permit_hintkey => 'Object/PadX/Role/AutoJSON' );
Object::Pad::MOP::FieldAttr->register( "JSONNum", permit_hintkey => 'Object/PadX/Role/AutoJSON' );
Object::Pad::MOP::FieldAttr->register( "JSONStr", permit_hintkey => 'Object/PadX/Role/AutoJSON' );

# ABSTRACT: Role for Object::Pad that dynamically handles a TO_JSON serialization based on the MOP
our $VERSION='1.0';


use Data::Dumper;

sub import { $^H{'Object/PadX/Role/AutoJSON'}=1;}

role AutoJSON {
  use Carp qw/croak/;
  use experimental 'for_list';

  method TO_JSON() {
    my $class = __CLASS__;
    my $classmeta = Object::Pad::MOP::Class->for_class($class);
    my @metafields = $classmeta->fields;

    my %json_out = ();

    for my $metafield (@metafields) {
      my $field_name = $metafield->name;
      my $sigil = $metafield->sigil;

      my $has_exclude = $metafield->has_attribute("JSONExclude");

      next if $has_exclude;

      next if $sigil ne '$';  # Don't try to handle anything but scalars

      my $has_null = $metafield->has_attribute("JSONNull");

      my $value = $metafield->value($self);
      next unless (defined $value || $has_null);

      my $key = $field_name =~ s/^\$//r;
      $key = $metafield->get_attribute_value("JSONKey") if $metafield->has_attribute("JSONKey");

      if ($metafield->has_attribute('JSONBool')) {
        $value = !!$value ? \1 : \0;
      } elsif ($metafield->has_attribute('JSONNum')) {
        # Force numification
        $value = 0+$value;
      } elsif ($metafield->has_attribute('JSONStr')) {
        # Force stringification
        $value = "".$value;
      }

      $json_out{$key} = $value;
    }

    return \%json_out;
  }
}
