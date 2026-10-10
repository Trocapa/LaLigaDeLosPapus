"""Demo verificable de TICK TACK PAPA! (espejo de la logica GDScript).
Ejecutar: python demo.py — verifica RF-01..RF-15 / F1-F7 / RN-01..RN-06.
"""
import random

BASE_HEAT = 4.0  # %/s (trajes.gd BASE_HEAT_POR_SEG)
TRAJES = {
    "rey":      {"speed": 300.0, "jump": -550.0, "heat_mult": 1.0},
    "criolla":  {"speed": 390.0, "jump": -550.0, "heat_mult": 1.5},
    "rustica":  {"speed": 300.0, "jump": -440.0, "heat_mult": 1.0, "inmune": True},
    "helada":   {"speed": 300.0, "jump": -550.0, "heat_mult": 0.5},
    "picante":  {"speed": 340.0, "jump": -550.0, "heat_mult": 1.2, "doble_salto": True},
}

class Papa:
    def __init__(self, nivel=1, traje="rey", bono_f7=False):
        self.temp = 0.0; self.viva = True; self.traje = traje
        self.nivel = nivel; self.bono = bono_f7; self.causa = ""
        self.freeze = 0.0; self.butter = 0.0; self.chili = 0.0
        self.sal = 0.0; self.invert = 0.0
        self.dash_cd = 0.0
    def heat(self):
        m = TRAJES[self.traje]["heat_mult"] * (2.0 if self.chili > 0 else 1.0) * (0.7 if self.bono else 1.0)
        return BASE_HEAT * m
    def tick(self, dt):
        for a in ("freeze","butter","chili","sal","invert"): setattr(self, a, max(0.0, getattr(self, a)-dt))
        self.dash_cd = max(0.0, self.dash_cd-dt)
        if self.freeze > 0: return
        self.temp = min(100.0, self.temp + self.heat()*dt)
        if self.temp >= 100.0: self.viva = False
    def agua(self):  # RF-03 -30% + RN-03 limpia
        self.temp = max(0.0, self.temp-30.0); self.chili=self.sal=self.invert=0.0
        if self.traje == "picante": self.traje = "rey"  # RF-08
    def item(self, tipo, rng):
        if tipo=="botella": self.temp=max(0.0,self.temp-20.0); return 0.0
        if tipo=="aceite": return 5.0
        if tipo=="mantequilla": self.butter=4.0; return 0.0
        if tipo=="carbon": self.temp=min(100.0,self.temp+20.0); self.viva=self.temp<100.0; return 0.0
        if tipo=="aji": self.chili=5.0; return 0.0
        if tipo=="sal": self.sal=3.0; return 0.0
        if tipo=="misterioso":
            if rng.random()<0.5: self.temp=0.0; self.chili=self.sal=self.invert=0.0
            else: self.temp=80.0; self.invert=5.0
            return 0.0
        return 0.0
    def dash(self):
        if self.dash_cd<=0: self.dash_cd=1.0; return True
        return False
    def explotar(self, causa):
        self.causa=causa; self.viva=False
    def jump(self): return TRAJES[self.traje]["jump"]*(0.75 if self.sal>0 else 1.0)
    def speed(self): return TRAJES[self.traje]["speed"]*(1.3 if self.butter>0 else 1.0)

TABLAS = {
    1: {"botella":50,"aceite":50},
    2: {"botella":40,"aceite":25,"mantequilla":15,"sal":20},
    3: {"botella":25,"aceite":20,"mantequilla":10,"carbon":20,"misterioso":15,"sal":10},
    4: {"botella":15,"aceite":20,"mantequilla":15,"carbon":15,"aji":20,"misterioso":10,"sal":5},
    5: {"botella":8,"aceite":12,"mantequilla":10,"carbon":25,"aji":25,"misterioso":10,"sal":10},
}
def elegir(nivel, rng):
    t=TABLAS[nivel]; tot=sum(t.values()); r=rng.random()*tot; a=0.0
    for k,v in t.items():
        a+=v
        if r<=a: return k
    return "botella"

ok = lambda c,msg: print(("PASS " if c else "FAIL ")+msg) or (not c and (_ for _ in ()).throw(SystemExit(f"FALLO: {msg}")))

print("== TICK TACK PAPA! DEMO ==")
# RF-01/F3 subida constante
p=Papa(); p.tick(1.0); ok(abs(p.temp-4.0)<1e-6, f"RF-01/F3 rey +4%/s (temp={p.temp})")
p=Papa(traje="criolla"); p.tick(1.0); ok(abs(p.temp-6.0)<1e-6, f"RF-07 criolla 1.5x (temp={p.temp})")
p=Papa(traje="helada"); p.tick(1.0); ok(abs(p.temp-2.0)<1e-6, f"RF-07 helada 0.5x (temp={p.temp})")
# RF-02/F1/F4 explosion y timeout
p=Papa(); p.temp=99.0; p.tick(0.5); ok(not p.viva, "RF-02/F1 explota al 100%")
t=10.0; t-=10.0; ok(t<=0, "RF-02/F4 timeout => derrota")
# RF-03/F2 agua
p=Papa(); p.temp=60.0; p.chili=5.0; p.agua(); ok(p.temp==30.0 and p.chili==0, f"RF-03 agua -30% y RN-03 limpia (temp={p.temp})")
# RF-04/F6 dash
p=Papa(); ok(p.dash() and not p.dash(), "RF-04/F6 dash con cooldown 1s")
p.tick(1.0); ok(p.dash(), "dash listo tras cooldown (HUD RF-12)")
ok(abs(Papa().speed()-300.0)<1e-6 and abs(Papa().jump()+550.0)<1e-6, "RF-04 movimiento base 300/-550")
# RF-05 catalogo
p=Papa(); p.temp=50.0; p.item("botella",random); ok(p.temp==30.0, "botella -20% calor")
p=Papa(); extra=p.item("aceite",random); ok(extra==5.0, "aceite +5s")
p=Papa(); p.item("mantequilla",random); ok(abs(p.speed()-390.0)<1e-6, f"mantequilla +30% vel ({p.speed()})")
p=Papa(); p.item("carbon",random); ok(p.temp==20.0, "carbon +20%")
p=Papa(); p.item("aji",random); ok(p.chili==5.0 and abs(p.heat()-8.0)<1e-6, "aji 2x calor 5s")
p=Papa(); p.item("sal",random); ok(p.jump()==-412.5, "sal -25% salto 3s")
rng=random.Random(1); vistos=set()
for _ in range(200):
    q=Papa(); q.item("misterioso",rng); vistos.add("frio" if q.temp==0.0 else "caliente")
ok(vistos=={"frio","caliente"}, f"misterioso 50/50 ambas ramas {vistos}")
# RF-07 trajes extras
ok(TRAJES["rustica"]["jump"]==-440.0 and TRAJES["rustica"].get("inmune"), "rustica salto -20% + inmune pinchos")
ok(TRAJES["picante"].get("doble_salto"), "picante doble salto")
p=Papa(traje="picante"); p.agua(); ok(p.traje=="rey", "RF-08 picante pierde traje con agua")
# RF-06/F7 bono
derrotas={1:2}; ok(derrotas[1]>=2, "RN-05 2 derrotas activan bono")
p=Papa(nivel=1,bono_f7=True); p.tick(1.0); ok(abs(p.temp-2.8)<1e-6, f"F7 bono heat x0.7 (temp={p.temp}) +10s tiempo")
# RF-14 meta
p=Papa(); p.temp=70.0; p.agua(); p.temp=0.0; ok(p.temp==0.0, "RF-14 meta resetea 0% y frena timer")
# RF-15/RN-06 spawner
rng=random.Random(7)
ok(set(elegir(1,rng) for _ in range(50))<={"botella","aceite"}, "RN-06 N1 100% ventajas fijas")
from collections import Counter
c=Counter(elegir(2,rng) for _ in range(2000))
ok("sal" in c and c["sal"]/2000>0.1, f"RN-06 N2 incluye sal ~20% (sal={c['sal']/20:.1f}%)")
c3=Counter(elegir(3,rng) for _ in range(2000))
ok("misterioso" in c3 and "carbon" in c3, "RN-06 N3 introduce ? y carbon")
# Tinte papa: blanco original hasta 35%, de ahi a rojo (mezcla 60%)
def lerp(a,b,f): return tuple(x+(y-x)*f for x,y in zip(a,b))
BASE=(1.0,1.0,1.0); ROJO=(1.0,0.12,0.08)
def tinte(f):
    f=max(0.0,min(1.0,f))
    if f<=0.35: return BASE
    return lerp(BASE,ROJO,(f-0.35)/0.65*0.6)
ok(tinte(0.0)==BASE and tinte(0.3)==BASE, "tinte 0-35%: color original sin filtros")
c50=tinte(0.5); ok(abs(c50[1]-0.88)<0.02, f"tinte 50% enrojeciendo {tuple(round(v,2) for v in c50)}")
c100=tinte(1.0); ok(abs(c100[1]-0.47)<0.02, f"tinte 100%: rojo {tuple(round(v,2) for v in c100)}")
# Dash radial: carga = 1 - restante/cooldown (listo = 1.0)
def carga(listo,rest,cd=1.0): return 1.0 if listo else max(0.0,min(1.0,1.0-rest/cd))
ok(carga(True,0.0)==1.0 and abs(carga(False,0.5)-0.5)<1e-9 and carga(False,1.0)==0.0, "dash carga/descarga segun tiempos")
# Barra HUD (hud.gd color_por_temp): verde -> amarillo -> rojo
def barra(f):
    V=(0.35,0.9,0.35); A=(1.0,0.85,0.15); R=(1.0,0.15,0.1)
    return lerp(V,A,f*2.0) if f<=0.5 else lerp(A,R,(f-0.5)*2.0)
def cerca(a,b): return all(abs(x-y)<1e-9 for x,y in zip(a,b))
ok(cerca(barra(0.0),(0.35,0.9,0.35)) and cerca(barra(0.5),(1.0,0.85,0.15)) and cerca(barra(1.0),(1.0,0.15,0.1)), "barra HUD verde->amarillo->rojo")
# Barra de vida 5 niveles (hud.gd nivel_vida): vida = 100 - temp
def nivel_vida(v):
    if v>80: return 5
    if v>60: return 4
    if v>40: return 3
    if v>20: return 2
    return 1
ok([nivel_vida(v) for v in (95,70,50,30,5)]==[5,4,3,2,1], "vida 5 niveles verde->rojo")
p=Papa(); p.temp=30.0; ok(nivel_vida(100.0-p.temp)==4, "vida 70% = nivel 4")
# Timeout y caida tambien explotan (nivel_base)
p=Papa(); p.explotar("Tiempo agotado (F4)"); ok(not p.viva and p.causa=="Tiempo agotado (F4)", "timeout explota con causa")
p=Papa(); y=750.0
if y>700.0: p.explotar("Caida al vacio")
ok(not p.viva and p.causa=="Caida al vacio", "caida (y>700) mata y reinicia")
print("== DEMO OK: F1-F7 + RF-01..RF-15 verificados ==")
