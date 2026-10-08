from pathlib import Path
import csv, json, zipfile, textwrap, datetime, shutil

ROOT = Path(__file__).resolve().parent
DATA = ROOT / 'datos'
DATA.mkdir(parents=True, exist_ok=True)

def csvwrite(name, headers, rows):
    with (DATA/name).open('w', newline='', encoding='utf-8') as f:
        w=csv.writer(f); w.writerow(headers); w.writerows(rows)

viajes=[['CEN-001','2026-09-03','EJECUTIVO','Comas','15.00'],
['CEN-002','2026-09-04','EJECUTIVO','Comas','20.00'],
['CEN-003','2026-09-05','ESTANDAR','Los Olivos','10.00'],
['CEN-004','2026-09-06','ESTANDAR','Los Olivos','20.00'],
['CEN-005','2026-10-04','ESTANDAR','Comas','30.00'],
['CEN-006','2026-10-05','ENCOMIENDA','Independencia','25.00']]
csvwrite('movitrack_control.csv',['CodigoViaje','Fecha','Servicio','Distrito','Importe'],viajes)
playas=[[b,f'Playa Demo {b:02d}', ['Norte','Centro','Sur'][(b-1)//2]] for b in range(1,7)]
csvwrite('playas.csv',['PlayaID','Nombre','Region'],playas)
jornadas=[]; residuos=[]; sensores=[]
for b in range(1,7):
    for d in range(100):
        jid=(b-1)*100+d+1
        fecha=(datetime.date(2026,1,1)+datetime.timedelta(days=d)).isoformat()
        jornadas.append([jid,b,fecha,10+b+(d%5),f'{18+b*.3+(d%10)*.2:.1f}'])
        pesos=[b*10+(d%10),b*2+(d%5),b*3+(d%3)]
        for tipo,peso in zip(['PLASTICO','VIDRIO','ORGANICO'],pesos):
            residuos.append([len(residuos)+1,jid,tipo,f'{peso:.2f}'])
        nivel=100 if (b==6 and d==99) else 10+b*3+(d%7)*.5
        sensores.append([jid,b,fecha,f'{nivel:.2f}'])
csvwrite('jornadas.csv',['JornadaID','PlayaID','Fecha','NumVoluntarios','TemperaturaAmbiente'],jornadas)
csvwrite('sensores.csv',['SensorID','PlayaID','Fecha','NivelContaminacion'],sensores)
dirty=residuos+[residuos[i].copy() for i in range(5)]+[
[1801,1,'PLASTICO',''],[1802,2,'VIDRIO','-5.00'],
[1803,3,'','12.00'],[1804,9999,'PLASTICO','18.00']]
csvwrite('residuos.csv',['RegistroID','JornadaID','TipoResiduo','PesoKg'],dirty)
with zipfile.ZipFile(ROOT/'datos_tema07.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(DATA.glob('*.csv')): z.write(p,p.name)

