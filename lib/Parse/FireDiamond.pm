package Parse::FireDiamond;

use 5.010001;
use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(
                       parse_fire_diamond_notation
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Parse Fire Diamond (NFPA 704) notation',
};

our %health_hazard_attrs = (
    4 => {
        meaning => "deadly",
        explanation => "Very short exposure could cause death or major residual injury (e.g. hydrogen cyanide, phosgene, diborane, methyl isocyanate, hydrofluoric acid)",
    },
    3 => {
        meaning=>"extreme danger",
        explanation => "Short exposure could cause serious temporary or moderate residual injury (e.g. liquid hydrogen, sulfuric acid, calcium hypochlorite, carbon monoxide, hexafluorosilicic acid, zinc chloride, sodium hydroxide)",
    },
    2 => {
        meaning=>"hazardous",
        explanation => "Intense or continued but not chronic exposure could cause temporary incapacitation or possible residual injury (e.g. diethyl ether, ammonium phosphate, carbon dioxide, chloroform, DEET).",
    },
    1 => {
        meaning=>"slightly hazardous",
        explanation => "Exposure would cause irritation with only minor residual injury (e.g. acetone, sodium bromate, potassium chloride)",
    },
    0 => {
        meaning=>"normal material",
        explanation => "Poses no health hazard, no precautions necessary and would offer no hazard beyond that of ordinary combustible materials (e.g. wood, sugar, salt, propylene glycol)",
    },
);

our %fire_hazard_attrs = (
    4 => {
        meaning => "below 25 °C",
        explanation => "Will rapidly or completely vaporize at normal atmospheric pressure and temperature, or is readily dispersed in air and will burn readily (e.g. acetylene, propane, hydrogen gas, diborane). Includes pyrophoric substances. Flash point below room temperature at 22.8 °C (73 °F).",
    },
    3 => {
        meaning => "below 37 °C",
        explanation => "Liquids and solids (including finely divided suspended solids) that can be ignited under almost all ambient temperature conditions (e.g. gasoline, acetone, ethanol). Liquids having a flash point below 22.8 °C (73 °F) and having a boiling point at or above 37.8 °C (100 °F) or having a flash point between 22.8 and 37.8 °C (73 and 100 °F).",
    },
    2 => {
        meaning => "below 93 °C",
        explanation => "Must be moderately heated or exposed to relatively high ambient temperature before ignition can occur (e.g. diesel fuel, paper, sulfur and multiple finely divided suspended solids that do not require heating before ignition can occur). Flash point between 37.8 and 93.3 °C (100 and 200 °F).",
    },
    1 => {
        meaning => "above 93 °C",
        explanation => "Materials that require considerable preheating, under all ambient temperature conditions, before ignition and combustion can occur (e.g. mineral oil, ammonia, ethylene glycol). Includes some finely divided suspended solids that do not require heating before ignition can occur. Flash point at or above 93.3 °C (200 °F).",
    },
    0 => {
        meaning=>"not flammable",
        explanation => "Materials that will not burn under typical fire conditions (e.g. carbon tetrachloride, silicon dioxide, perfluorohexane), including intrinsically noncombustible materials such as concrete, stone, and sand. Materials that will not burn in air unless exposed to a temperature of 820 °C (1,500 °F) for more than 5 minutes.",
    },
);

our %reactivity_attrs = (
    4 => {
        meaning => "may detonate",
        explanation => "Readily capable of detonation or explosive decomposition at normal temperatures and pressures (e.g. nitroglycerin, chlorine dioxide, nitrogen triiodide, manganese heptoxide, TNT)",
    },
    3 => {
        meaning => "shock + heat may detonate",
        explanation => "Capable of detonation or explosive decomposition but requires a strong initiating source, must be heated under confinement before initiation, reacts explosively with water, or will detonate if severely shocked (e.g. ammonium nitrate, caesium, hydrogen peroxide)",
    },
    2 => {
        meaning => "violent reaction",
        explanation => "Undergoes violent chemical change at elevated temperatures and pressures, reacts violently with water, or may form explosive mixtures with water (e.g. white phosphorus, potassium, sodium)",
    },
    1 => {
        meaning => "unstable if heated",
        explanation => "Normally stable, but can become unstable at elevated temperatures and pressures (e.g. propene, ammonium acetate, carbonic acid)",
    },
    0 => {
        meaning => "stable",
        explanation => "Normally stable, even under fire exposure conditions, and is not reactive with water (e.g. helium, N2, carbon dioxide)",
    },
);

our %specific_hazard_attrs = (
    O => {
        meaning => "oxidizer",
        explanation => "allows chemicals to burn without an air supply (e.g. potassium perchlorate, ammonium nitrate, hydrogen peroxide)",
    },
    OX => {
        meaning => "oxidizer",
        explanation => "allows chemicals to burn without an air supply (e.g. potassium perchlorate, ammonium nitrate, hydrogen peroxide)",
    },
    OXY => {
        meaning => "oxidizer",
        explanation => "allows chemicals to burn without an air supply (e.g. potassium perchlorate, ammonium nitrate, hydrogen peroxide)",
    },

    W => {
        meaning => "reacts with water",
        explanation => "Reacts with water in an unusual or dangerous manner (e.g. caesium, sodium, diborane, sulfuric acid)",
    },
    # W with overstrike

    SA => {
        meaning => "simple asphyxiant gas",
        explanation => "Simple asphyxiant gas (specifically helium, nitrogen, neon, argon, krypton, xenon), shall also be used for liquefied carbon dioxide vapor withdrawal systems and where large quantities of dry ice are used in confined areas",
    },

    COR => {
        meaning => "corrosive",
        explanation => "strong acid or base (e.g. sulfuric acid, potassium hydroxide) ",
    },

    ACID => {
        meaning => "acid",
        explanation => "",
    },

    ALK => {
        meaning => "alkaline",
        explanation => "",
    },

    BIO => {
        meaning => "biological hazard",
        explanation => "Biological hazard (e.g. flu virus, rabies virus)",
    },

    POI => {
        meaning => "poisonous",
        explanation => "Poisonous (e.g. strychnine, alpha-amanitin)",
    },

    RA => {
        meaning => "radioactive",
        explanation => "Radioactive (e.g. plutonium, cobalt-60, carbon-14)",
    },
    RAD => {
        meaning => "radioactive",
        explanation => "Radioactive (e.g. plutonium, cobalt-60, carbon-14)",
    },

    CRY => {
        meaning => "cryogenic",
        explanation => "Cryogenic (e.g. liquid nitrogen)",
    },
    CRYO => {
        meaning => "cryogenic",
        explanation => "Cryogenic (e.g. liquid nitrogen)",
    },
);

$SPEC{parse_fire_diamond_text_notation} = {
    v => 1.1,
    summary => 'Parse Fire Diamond (NFPA 704) text notation',
    args => {
        notation => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    examples => [
        {
            summary => "Parse the fire diamond for citric acid",
            args => {notation=>"H2/F1/R0/"},
        },
        {
            summary => "Parse the fire diamond for sucrose",
            args => {notation=>"H0/F1/R0/"},
        },
        {
            summary => "Parse the fire diamond for sulfuric acid",
            args => {notation=>"H3/F0/R2/W+OX"},
        },
    ],
};
sub parse_fire_diamond_text_notation {
    my %args = @_;

    my $notation = $args{notation} or return [400, "Please specify notation"];
    $notation = uc($notation);
    $notation =~ s/\s+//g;

    my $res = [200, "OK (parsed)", {}, {}];

    my ($h, $f, $r, $specifics) = $notation =~ m!\AH(\d+)/F(\d+)/R(\d+)/(.*)\z!
        or return [400, "Bad syntax, must be in Hx/Fx/Rx/(...(+...))? notation"];

    $h >= 0 && $h <= 4 or return [400, "Bad H value, must be between 0 and 4"];
    $res->[2]{health_hazard_number} = $h;
    $res->[2]{health_hazard_meaning} = $health_hazard_attrs{$h}{meaning};
    $res->[3]{'func.health_hazard_explanation'} = $health_hazard_attrs{$h}{explanation};

    $f >= 0 && $f <= 4 or return [400, "Bad F value, must be between 0 and 4"];
    $res->[2]{fire_hazard_number} = $f;
    $res->[2]{fire_hazard_meaning} = $fire_hazard_attrs{$f}{meaning};
    $res->[3]{'func.fire_hazard_explanation'} = $fire_hazard_attrs{$f}{explanation};

    $r >= 0 && $r <= 4 or return [400, "Bad R value, must be between 0 and 4"];
    $res->[2]{reactivity_number} = $r;
    $res->[2]{reactivity_meaning} = $reactivity_attrs{$r}{meaning};
    $res->[3]{'func.reactivity_explanation'} = $reactivity_attrs{$r}{explanation};

    my @specifics = split /\+/, $specifics;
    my %seen_specifics;
    for my $specific (@specifics) {
        $specific =~ /\A[A-Z]+\z/ or return [400, "Bad syntax in specific hazard '$specific', must be all letters"];
        exists $specific_hazard_attrs{$specific} or return [400, "Unknown specific hazard symbol '$specific'"];
        $seen_specifics{$specific}++ and return [400, "Duplicate specific hazard symbol '$specific'"];
        $res->[2]{specific_hazards} //= [];
        $res->[3]{'func.specific_hazards'} //= [];
        push @{ $res->[2]{specific_hazards} }, {
            symbol => $specific,
            meaning => $specific_hazard_attrs{$specific}{meaning},
        };
        push @{ $res->[3]{'func.specific_hazards'} }, {
            symbol => $specific,
            explanation => $specific_hazard_attrs{$specific}{explanation},
        };
    }

    $res;
}

1;
# ABSTRACT:

=head1 SYNOPSIS

 use Parse::FireDiamond qw(
     parse_fire_diamond_text
 );

 my $res = parse_fire_diamond_text(notation => 'H3/F2/R1/');


=head1 DESCRIPTION

Keywords: chemicals, materials, hazardous, safety.


=head1 SEE ALSO

Credits: explanation text are taken from Wikipedia page
L<https://en.wikipedia.org/wiki/NFPA_704>.
