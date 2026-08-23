v {xschem version=3.4.4 file_version=1.2
}
G {}
K {}
V {}
S {}
E {}
N 60 -0 80 0 {
lab=out}
N 140 0 140 20 {
lab=out}
N 80 -0 140 0 {
lab=out}
N -60 -0 -60 20 {
lab=in}
N -60 -0 -0 0 {
lab=in}
C {capa-2.sym} 140 50 0 0 {name=X1
value = "MIM_UNIFIED l=50u w=50u"}
C {res.sym} 30 0 1 0 {name=R1
value=1k
footprint=1206
device=resistor
m=1}
C {gnd.sym} 140 80 0 0 {name=l2 lab=GND}
C {vsource.sym} -60 50 0 0 {name=V1 value="0 AC 1" savecurrent=false}
C {gnd.sym} -60 80 0 0 {name=l3 lab=GND}
C {lab_pin.sym} 140 0 2 0 {name=p1 sig_type=std_logic lab=out}
C {lab_pin.sym} -60 0 0 0 {name=p2 sig_type=std_logic lab=in}
C {code_shown.sym} 180 -170 0 0 {name=s1 only_toplevel=false value="
.include /home/rsanchez/capacitor/models.spice
.AC DEC 10 1k 100Meg
.CONTROL
run
set xlog
plot mag(v(out)/I(V1))
.ENDC
"}
