# Ejecutar con el mismo Python que utilizará JupyterLab.
import os, sys, tempfile
from pathlib import Path
os.environ['PYSPARK_PYTHON'] = sys.executable
from pyspark.sql import SparkSession
spark = SparkSession.builder.master('local[2]').appName('PruebaTema07').getOrCreate()
print('Spark:', spark.version)
assert spark.range(6).count() == 6
assert spark.sparkContext.parallelize([15, 20, 30], 2).sum() == 65
with tempfile.TemporaryDirectory() as ruta:
    destino = str(Path(ruta) / 'prueba_parquet')
    spark.range(6).write.parquet(destino)
    assert spark.read.parquet(destino).count() == 6
spark.stop()
print('PRUEBA COMPLETA CORRECTA: RDD, SQL y Parquet')
