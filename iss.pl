#!/usr/bin/perl
#######################################################################################
# $Id: iss.pl,v 1.0 2016/02/01 cx8fs
#######################################################################################
## $Log: iss.pl,v $
## Copyright (c) 2016 Claudio Nuñez
## Revision 1.0  2016/02/01
##  First Release
##
#######################################################################################

# Predict genera el archivo a procesar con la siguiente sintaxis en el crontab:
# 0 * * * * /usr/bin/predict -p ISS -o /home/pi/iss.pr >/dev/null 2>&1

# Formato del archivo a procesar:
# 1454333800 Mon 01Feb16 13:36:40    0  226  131  -47   78   2362   2373 *
# 1454333871 Mon 01Feb16 13:37:51    2  215  134  -49   72   2116   2373 *
# 1454333942 Mon 01Feb16 13:39:02    4  201  138  -50   65   1962   2373 *
# 1454334013 Mon 01Feb16 13:40:13    4  185  141  -51   59   1923   2373 *
# 1454334085 Mon 01Feb16 13:41:25    4  170  144  -52   52   2005   2373 *
# 1454334156 Mon 01Feb16 13:42:36    2  157  147  -52   44   2195   2373 *
# 1454334203 Mon 01Feb16 13:43:23    0  149  150  -52   40   2370   2373 *
# date/time in Unix format, the date and time in ASCII
# (UTC), the elevation of the satellite in degrees, the  azimuth  of  the
# satellite  in degrees, the orbital phase (modulo 256), the latitude (N)
# and longitude (W) of the satellite.s  sub-satellite  point,  the  slant
# range  to  the  satellite  (in  kilometers), the orbit number, and the
# spacecraft.s sunlight visibility information.

# Este script se ejecuta mediante el crontab de root de esta manera:
# 5 * * * * perl /home/pi/iss.pl >/dev/null 2>&1
# La salida del mismo es en $OutFile

use strict;
use warnings;

# Defino variables
my $Enable=1;   # Habilito=1, Deshabilito=0
my $True=1;
my $ThisLine;   # Simboliza cada linea de entrada
my $OutFile='/var/log/aprx/beacon03.txt';
my $InputFile='/home/pi/iss.pr';
my $APRSLog='/var/log/aprx/aprx-rf.log';
my $APRSTo=':BLN1     :';
my $Orbit;
my $AOSDate;
my $AOSTime;
my $LOSDate;
my $LOSTime;
my $MaxElev;
my $MaxElevAz;
my $ArrayLinesNum;
my @ArrayLines; # Array que procesa cada linea de entrada, separados por espacio, 12 columnas
my @ArrayLinesTmp;
my @ArrayLinesSorted;  # Array ordenado por Elevacion
my $TotalLineas=0;      #Lineas totales de la primer orbita

#######################################################################################
# Subroutine for printing output report - Only for testing..
# Ref: http://www.tutorialspoint.com/perl/perl_subroutines.htm
sub PrintOutputTest {
print "------------------------Testing Area 1------------------------------\n";
for my $cni ( 0 .. $#ArrayLines ) {
    my $cnrow = $ArrayLines[$cni];
    for my $cnj ( 0 .. $#{$cnrow} ) {
        print "element $cni $cnj is $cnrow->[$cnj]\n";
    }
}
print "------------------------Testing Area2------------------------------\n";
@ArrayLinesSorted = sort { $b->[4] <=> $a->[4] } @ArrayLinesTmp;

for my $cni ( 0 .. $#ArrayLinesSorted ) {
    my $cnrow = $ArrayLinesSorted[$cni];
    for my $cnj ( 0 .. $#{$cnrow} ) {
        print "element $cni $cnj is $cnrow->[$cnj]\n";
    }
}
print "------------------------Testing Area3------------------------------\n";

for my $cni ( 0 .. $#ArrayLinesTmp ) {
    my $cnrow = $ArrayLinesTmp[$cni];
    for my $cnj ( 0 .. $#{$cnrow} ) {
        print "element $cni $cnj is $cnrow->[$cnj]\n";
    }
}
print "Fin Area3";
#print Dumper \@ArrayLines;
}

#######################################################################################
# Subroutine for printing output
# Tamaño maximo de mensaje 67 caracteres
# ISS next pass over GF15VC: Orbit [2373], AOS [01Feb16 13:36:40]UTC, LOS [01Feb16 13:43:23]UTC, MaxElev [4]° @ Az [201]°
sub PrintOutput {
my $Output = "ISS over GF15VC:Orbt${Orbit},AOS:${AOSDate}-${AOSTime}U,LOS:${LOSDate}-${LOSTime}U\n";

print "${APRSTo}${Output}";  # Resultado por STDOUT para testing

WriteOutput ("$APRSTo$Output");   #Llamo a la subrutina que escribe
}

#######################################################################################
# Subroutine for write to file output
# Parameter, text to save.
sub WriteOutput {
        my @list = @_;
        open(my $fh, '>', $OutFile) or die "Could not open file '$OutFile' $!";
                print $fh @list;
        close $fh;
}

#######################################################################################
# Subroutine for processing data
#
sub Process {
# Cargo los resultados
$Orbit=$ArrayLines[0][10];
$AOSDate=$ArrayLines[0][2];
$AOSTime=$ArrayLines[0][3];

# Filtro los resultados vinculados a la primer fecha
for my $cni ( 0 .. $ArrayLinesNum ) {
        while ( $Orbit == $ArrayLines[$cni][10] ) {  # tomo solos los que estan dentro del rango
                # Tengo que encontrar el mayor valor de azimith
                # Para eso cada valor de los que encontre lo paso a un array diferente y luego le aplico un sort.
                #push @ArrayLinesTmp, $ArrayLines[$cni];
                $TotalLineas++;
                last;
        }
        $LOSDate= $ArrayLines[$TotalLineas-1][2];
        $LOSTime= $ArrayLines[$TotalLineas-1][3];
}
# Recorto el año y los segundos de los datos a 5 caracteres.
$AOSDate = substr( $AOSDate, 0, 5 );
$LOSDate = substr( $LOSDate, 0, 5 );
$AOSTime = substr( $AOSTime, 0, 5 );
$LOSTime = substr( $LOSTime, 0, 5 );
}

#######################################################################################
#                         Start of Main Routine                                       #
#######################################################################################
# Main routine, go through the input.

if ($Enable == 0) {
        print "Program disabled by software, 73!\n";
        WriteOutput ("");   #Vacío el archivo de salida
        exit(0);
}

open(FILE1, $InputFile) || die "Error: $!\n";
while (defined($ThisLine = <FILE1>)) {
        chomp($ThisLine);
#######################################################################################
# Read the input text pipe separated by spaces, first camp it's adressed zero
    # Separo la linea por "espacios", [0]=FechaUX, [1]=DIA, [2]=Fecha, [3]=Hora, [4]=Elevacion....
        push @ArrayLines, [split("\x20", $ThisLine)];
}
$ArrayLinesNum=$#ArrayLines;  # cuantas lineas tiene el array?
Process ();                     # Proceso lo obtenido
#PrintOutputTest ();   # Este es para pruebas
PrintOutput ();
exit(0);
